#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
EXPORT_DIR="${DOTFILES_DIR}/manual_exports"

DNF_LIST="${EXPORT_DIR}/packages-dnf.txt"
FLATPAK_LIST="${EXPORT_DIR}/flatpak-list.txt"
FLATPAK_REMOTES="${EXPORT_DIR}/flatpak-remotes.txt"
GNOME_DCONF="${EXPORT_DIR}/gnome-settings.dconf"

FLATPAK_OVERRIDES_SRC="${EXPORT_DIR}/flatpak-overrides/overrides"
FLATPAK_OVERRIDES_DST="${HOME}/.local/share/flatpak/overrides"

VSCODIUM_PREFS_DIR="${EXPORT_DIR}/vscodium-prefs"
VSCODIUM_DST="${HOME}/.var/app/com.vscodium.codium/config/VSCodium/User"

echo "[1/5] DNF packages"
if [[ -f "${DNF_LIST}" ]] && [[ -s "${DNF_LIST}" ]]; then
  # Filtre lignes vides / commentaires
  mapfile -t pkgs < <(grep -vE '^\s*#|^\s*$' "${DNF_LIST}" || true)
  if (( ${#pkgs[@]} > 0 )); then
    sudo dnf install -y "${pkgs[@]}"
  fi
fi

echo "[2/5] Flatpak remotes"
if [[ -f "${FLATPAK_REMOTES}" ]]; then
  while IFS=$'\t' read -r name url; do
    [[ -z "${name}" || -z "${url}" ]] && continue
    flatpak remote-add --if-not-exists "${name}" "${url}"
  done < "${FLATPAK_REMOTES}"
fi

echo "[3/5] Flatpak apps"
if [[ -f "${FLATPAK_LIST}" ]] && [[ -s "${FLATPAK_LIST}" ]]; then
  grep -vE '^\s*#|^\s*$' "${FLATPAK_LIST}" | \
    xargs -r -n1 flatpak install -y flathub
fi

echo "[4/5] Flatpak overrides (copy)"
mkdir -p "${FLATPAK_OVERRIDES_DST}"
if [[ -d "${FLATPAK_OVERRIDES_SRC}" ]]; then
  for f in "${FLATPAK_OVERRIDES_SRC}"/*; do
    [[ -f "${f}" ]] || continue
    cp -v "${f}" "${FLATPAK_OVERRIDES_DST}/"
  done
fi

echo "[5/5] GNOME dconf restore"
if [[ -f "${GNOME_DCONF}" ]]; then
  dconf load /org/gnome/ < "${GNOME_DCONF}"
fi

echo "[VSCodium] prefs + extensions"
mkdir -p "${VSCODIUM_DST}"

if [[ -f "${VSCODIUM_PREFS_DIR}/settings.json" ]]; then
  cp -v "${VSCODIUM_PREFS_DIR}/settings.json" "${VSCODIUM_DST}/settings.json"
fi

# keybindings.json : absent dans ton zip -> on ne fait rien si absent
if [[ -f "${VSCODIUM_PREFS_DIR}/keybindings.json" ]]; then
  cp -v "${VSCODIUM_PREFS_DIR}/keybindings.json" "${VSCODIUM_DST}/keybindings.json"
fi

# snippets : présent dans ton zip
if [[ -d "${VSCODIUM_PREFS_DIR}/snippets" ]]; then
  cp -rv "${VSCODIUM_PREFS_DIR}/snippets" "${VSCODIUM_DST}/"
fi

# extensions : présent dans ton zip
if [[ -f "${VSCODIUM_PREFS_DIR}/extensions.txt" ]]; then
  while IFS= read -r ext; do
    [[ -z "${ext}" ]] && continue
    flatpak run com.vscodium.codium --install-extension "${ext}" || true
  done < <(grep -vE '^\s*#|^\s*$' "${VSCODIUM_PREFS_DIR}/extensions.txt" || true)
fi

echo "Done."

