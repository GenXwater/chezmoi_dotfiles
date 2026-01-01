#!/bin/bash

echo "🔧 Restauration des paquets DNF personnalisés..."
sudo dnf install -y $(cat ~/Dotfiles/manual_exports/packages-dnf.txt)

echo "📦 Restauration des applis Flatpak..."
cat ~/Dotfiles/manual_exports/flatpak-list.txt | xargs -n1 flatpak install -y flathub

echo "🌐 Configuration des remotes Flatpak..."
while IFS=$'\t' read -r name url; do
    flatpak remote-add --if-not-exists "$name" "$url"
done < ~/Dotfiles/manual_exports/flatpak-remotes.txt

echo "🔒 Réapplication des overrides Flatpak..."
flatpak override --reset  # nettoie d'abord tout
cat ~/Dotfiles/manual_exports/flatpak-overrides.txt | while read line; do
    flatpak override $line
done

echo "🧠 Restauration des préférences GNOME..."
dconf load /org/gnome/ < ~/Dotfiles/manual_exports/gnome-settings.dconf

echo "🔐 Brave : copie des fichiers de préférences..."
cp -v ~/Dotfiles/manual_exports/brave-prefs/* ~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/Default/

echo "🛠️ VS Codium : préférences et extensions..."
cp -v ~/Dotfiles/manual_exports/vscodium-prefs/settings.json ~/.var/app/com.vscodium.codium/config/VSCodium/User/
cp -v ~/Dotfiles/manual_exports/vscodium-prefs/keybindings.json ~/.var/app/com.vscodium.codium/config/VSCodium/User/ 2>/dev/null
cp -r ~/Dotfiles/manual_exports/vscodium-prefs/snippets ~/.var/app/com.vscodium.codium/config/VSCodium/User/ 2>/dev/null
cat ~/Dotfiles/manual_exports/vscodium-prefs/extensions.txt | xargs -n1 flatpak run com.vscodium.codium --install-extension

echo "✅ Configuration terminée."
