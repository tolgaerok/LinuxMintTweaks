#!/bin/bash
# LinuxTweaks for LinuxMint
# Version:  1.0a
# Author :  Tolga Erok
# Created:  23/10/25

BLUE="\033[0;34m"
NC="\033[0m"
RED="\033[0;31m"
YELLOW="\033[1;33m"

real_user=${SUDO_USER:-$(logname)}
user_home=$(eval echo "~$real_user")
autostart_dir="$user_home/.config/autostart"
plank_desktop="$autostart_dir/plank.desktop"
file="/etc/initramfs-tools/modules"
grub_file="/etc/default/grub"
initramfs_mod="/etc/initramfs-tools/modules"
module="zsmalloc"

# -------------- ensure script runs as root ---------------
if [[ $EUID -ne 0 ]]; then
    echo "⚠️  please run this with sudo"
    exit 1
fi

# -------------- Icon setup ---------------
icon_URL="https://raw.githubusercontent.com/tolgaerok/linuxtweaks/main/MY_PYTHON_APP/images/LinuxTweak.png"
icon_dir="$user_home/.config"
icon_path="$icon_dir/LinuxTweak.png"
DEFAULT_ART="$icon_path"
mkdir -p "$icon_dir"
wget -q -O "$icon_path" "$icon_URL"
chmod 644 "$icon_path"

if [ ! -f "$DEFAULT_ART" ]; then
    convert -size 300x300 xc:gray "$DEFAULT_ART" 2>/dev/null || touch "$DEFAULT_ART"
fi

# Intro text
intro=$(
cat <<'EOF'
 LinuxTweaks LinuxMint tweaks

🟢 TO-DO-LATER
💡 Minimal hassle, maximum performance
🟢 Install in progress...

[+] ============================================== [+]
EOF
)

downloading=$(
cat <<'EOF'
 LinuxTweaks LinuxMint tweaks live progress
🟢 Install in progress...
[+] ============================================== [+]
EOF
)

install_packages() {
    log="/tmp/linux_tweaks_apt.log"
    packages=(
        7zip-rar adwaita-qt catfish doublecmd-gtk fonts-crosextra-caladea fonts-crosextra-carlito
        fonts-firacode fonts-noto-unhinted fonts-ubuntu-classic fortune-mod git grub2-theme-mint helix
        linux-hwe-6.14-headers-6.14.0-33 linux-hwe-6.14-tools-6.14.0-33 lolcat nala preload
        numlockx okular pavucontrol plank python3-dnspython qt5ct rar samba curl
        samba-ad-provision samba-dsdb-modules samba-vfs-modules sublime-merge sublime-text synaptic
        tdb-tools variety vlc wsdd xanmod-kernel-manager yad fonts-noto-mono fonts-noto-color-emoji
    )

    echo " starting installation..." > "$log"

    # create a pipe
    pipe="/tmp/linux_tweaks_pipe.log"
    [[ -p $pipe ]] || mkfifo "$pipe"

    # start yad
    yad --title="🟢  LinuxTweaks LinuxMint tweaks live progress" \
        --image="$icon_path" \
        --text="$intro" \
        --width=750 --height=400 \
        --text-info --tail --fontname="monospace" \
        --wrap --center --button=gtk-cancel:1 < "$pipe" &
    yad_pid=$!

    # output to pipe
    {
        sudo apt-get update -y 2>&1 | tee -a "$log"
        sudo apt-get install -y "${packages[@]}" 2>&1 | tee -a "$log"
        echo "✅ installation done — check $log for details" | tee -a "$log"

        # countdown inside the pipe
        for i in 3 2 1; do
            echo "window closing in $i..." | tee -a "$log"
            sleep 1
        done
    } > "$pipe"

    sleep 0.5
    kill $yad_pid 2>/dev/null
    rm -f "$pipe"
}

install_packages

# -------------- plank auto-start ---------------
echo "👤 detected user: $real_user"
echo "📂 target directory: $autostart_dir"

# create the autostart dir if missing
mkdir -p "$autostart_dir"
chown -R "$real_user:$real_user" "$autostart_dir"

# create the plank autostart file if missing
if [[ -f "$plank_desktop" ]]; then
    echo "✔️ plank autostart already exists at $plank_desktop brother"
else
    echo "🌀 creating plank autostart entry brother, relax..."
    cat <<EOF > "$plank_desktop"
[Desktop Entry]
Name=Plank
GenericName=Dock
Comment=Stupidly simple.
Categories=Utility;
Type=Application
Exec=plank
Icon=plank
Terminal=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Hidden=false
Name[en_AU]=Plank
X-GNOME-Autostart-Delay=0
EOF

    chown "$real_user:$real_user" "$plank_desktop"
    chmod 644 "$plank_desktop"
    echo "✅ plank autostart file created at $plank_desktop Enjoy"
fi

echo "⚙️ ready... brother, plank will now start automatically on login for $real_user"

# -------------- required kernel flags for zswap + xanmod ---------------
params=(
    "zswap.enabled=1"
    "zswap.compressor=lz4"
    "zswap.max_pool_percent=20"
    "zswap.zpool=zsmalloc"
    "transparent_hugepage=never"
    "audit=0"
    "apparmor=1"
    "tsc=nowatchdog"
    "loglevel=3"
    "systemd.show_status=auto"
    "mitigations=off"
)

echo "🌀 checking grub parameters..."

current=$(grep -oP '(?<=GRUB_CMDLINE_LINUX_DEFAULT=")[^"]*' "$grub_file")
updated="$current"

for param in "${params[@]}"; do
    if ! grep -qw "$param" <<< "$current"; then
        updated+=" $param"
    fi
done

if [ "$updated" != "$current" ]; then
    echo "🔧 updating grub parameters..."
    sudo sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\"|GRUB_CMDLINE_LINUX_DEFAULT=\"$updated\"|" "$grub_file"
    echo "✅ grub updated with missing parameters"
else
    echo "✔️ all parameters already present"
fi

echo "🧠 checking for zsmalloc in initramfs modules..."
if ! grep -q "^zsmalloc" "$initramfs_mod" 2>/dev/null; then
    echo "zsmalloc" | sudo tee -a "$initramfs_mod" >/dev/null
    echo "✅ added zsmalloc to $initramfs_mod"
else
    echo "✔️ zsmalloc already present"
fi

echo "⚙️ rebuilding grub and initramfs..."
sudo update-grub >/dev/null 2>&1 && echo "grub updated"

echo "🎯 done — reboot to activate zswap changes"

# ------------- zsmalloc tweak ---------------
echo "🧠 zsmalloc + zswap + zram optimization for linux mint"
echo "🧠 checking $module in $file..."

echo "🧠 checking $module in $file..."
if grep -q "^$module" "$file" 2>/dev/null; then
    echo "✔️ $module already present — nothing to do."
else
    echo "$module" | sudo tee -a "$file" >/dev/null
    echo "✅ added $module to $file"
    echo "⚙️ rebuilding initramfs..."
    sudo update-initramfs -u -k all && echo "initramfs rebuilt successfully."
fi

echo "🎯 done — reboot to ensure $module loads early."
lsmod | grep zsmalloc || echo "ℹ️ will load after reboot"

# ------------- ZRAM tweak ---------------
echo
echo "💾 setting up zram swap..."

sudo modprobe zram

# safer writes using sudo tee
echo lz4 | sudo tee /sys/block/zram0/comp_algorithm >/dev/null 2>&1 || echo zstd | sudo tee /sys/block/zram0/comp_algorithm >/dev/null 2>&1
size_bytes=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') * 1024 / 2 ))
echo $size_bytes | sudo tee /sys/block/zram0/disksize >/dev/null
sudo mkswap /dev/zram0 >/dev/null
sudo swapon /dev/zram0

echo "✅ zram active — $(grep zram /proc/swaps)"

# ------------- ZSWAP tweak ---------------
echo
echo "⚙️ enabling zswap..."

sudo dmesg | grep -i zswap || true
cat /sys/module/zswap/parameters/max_pool_percent 2>/dev/null || echo "zswap not active yet"

# patch grub cleanly without line breaks
sudo sed -i 's/^\s*GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 zswap.enabled=1 zswap.compressor=zstd zswap.max_pool_percent=25"/' /etc/default/grub

if [ -d /sys/firmware/efi ]; then
    echo "UEFI system — updating grub..."
    sudo grub-mkconfig -o /boot/efi/EFI/ubuntu/grub.cfg 2>/dev/null || sudo update-grub
else
    echo "Legacy BIOS — updating grub..."
    sudo update-grub
fi

# ------------- FSTRIM tweak ---------------
echo
echo "🧹 setting up daily fstrim..."
sudo mkdir -p /etc/systemd/system/fstrim.timer.d
cat <<EOF | sudo tee /etc/systemd/system/fstrim.timer.d/override.conf >/dev/null
[Timer]
OnCalendar=
OnCalendar=daily
EOF

progress "rebuilding grub and initramfs" "update-grub && update-initramfs -u -k all"
progress "setting up zram swap" "modprobe zram && mkswap /dev/zram0 && swapon /dev/zram0"
progress "enabling daily fstrim" "systemctl enable fstrim.timer && systemctl restart fstrim.timer"

sudo systemctl daemon-reload
sudo systemctl enable fstrim.timer
sudo systemctl restart fstrim.timer
sudo systemctl status fstrim.timer --no-pager || true

echo
sudo dmesg | grep -i zswap | tail -n 5 || echo "zswap will activate after reboot"
echo "✅ all done — reboot to enjoy compressed swap and faster io"

# ------------- WIFI tweak ---------------
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf <<EOF
[connection]
wifi.powersave = 2
EOF
echo "options iwlwifi 11n_disable=8" | sudo tee /etc/modprobe.d/iwlwifi-speed.conf
sudo systemctl restart NetworkManager
sudo nmcli radio wifi off
sudo modprobe -r iwlwifi
sudo modprobe iwlwifi
sudo nmcli radio wifi on
sleep 6
iwconfig

# sudo dpkg-repack nerolinux
sudo apt-get install numlockx

# ------------- SSD tweaks & ram ---------------
# put /tmp on tmpfs
sudo cp -v /usr/share/systemd/tmp.mount /etc/systemd/system/
sudo sed -i 's/size=50%%/size=8G/' /etc/systemd/system/tmp.mount
sudo systemctl daemon-reload
sudo systemctl enable tmp.mount
sudo systemctl restart tmp.mount
systemctl status tmp.mount
df -h /tmp

cat /proc/sys/vm/dirty_ratio
cat /proc/sys/vm/dirty_background_ratio

# create a sysctl override
# echo "vm.swappiness=30" | sudo tee /etc/sysctl.d/7-swappiness.conf
sudo tee /etc/sysctl.d/99-tuned-ssd.conf <<EOF
vm.dirty_ratio = 28
vm.dirty_background_ratio = 14
vm.dirty_expire_centisecs = 1200
vm.dirty_writeback_centisecs = 200
EOF

# setup swap and swappiness
ram_gb=$(free -g | awk '/Mem:/{print $2}')
swapfile="/swapfile"

if (( ram_gb < 2 )); then
    swapsize=$(( ram_gb * 2 ))
    swappy=70
elif (( ram_gb <= 8 )); then
    swapsize=$ram_gb
    swappy=30
elif (( ram_gb <= 16 )); then
    swapsize=4
    swappy=20
else
    swapsize=4
    swappy=10
fi

echo "detected ram: ${ram_gb}gb"
echo "creating ${swapsize}gb swap, swappiness=${swappy}"

sudo swapoff -a 2>/dev/null
sudo fallocate -l ${swapsize}G $swapfile
sudo chmod 600 $swapfile
sudo mkswap $swapfile
sudo swapon $swapfile

if ! grep -q "$swapfile" /etc/fstab; then
    echo "$swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
fi

sudo sysctl vm.swappiness=$swappy
echo "vm.swappiness = $swappy" | sudo tee -a /etc/sysctl.conf >/dev/null

echo "swap and swappiness tuned ✅"

# apply immediately
sudo sysctl --system
sudo udevadm control --reload

# verify
cat /proc/sys/vm/swappiness
cat /proc/sys/vm/dirty_ratio
cat /proc/sys/vm/dirty_background_ratio
cat /proc/sys/vm/dirty_expire_centisecs
cat /proc/sys/vm/dirty_writeback_centisecs
swapon --show
free -h

# ------------- firewall ---------------
echo -e "\n🛡️ Configuring firewall (ufw)..."
# enable ufw if not active
if ! sudo ufw status | grep -q "Status: active"; then
    echo "[+] Enabling UFW..."
    sudo ufw enable
fi

# detect local subnet
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
SUBNET=$(ip -o -4 addr show dev $INTERFACE | awk '{print $4}')
echo "[+] detected subnet: $SUBNET"
sleep 2.5

# allow necessary ports
PORTS_IN=(
    "139,445/tcp"
    "137,138/udp"
    "137,138,139,445/udp"
    "137,138,139,445/tcp"
    "22/tcp"
    "5357/tcp"
    "5357/udp"
    "3702/udp"
    "5353/udp"
    "427/udp"
    "161"
    "162"
    "9100"
    "631"
    "8080/tcp"
    "5000/tcp"
    "1900/udp"
    "53317/tcp"
    "53317/udp"
)

for port in "${PORTS_IN[@]}"; do
    sudo ufw allow $port
done

echo "[+] reloading ufw..."
sudo ufw logging off
sudo ufw reload

echo "[+] checking ufw status..."
sudo ufw status verbose

echo -e "\n✅ custom full ufw setup complete!"
echo -e "\n[+]----------------------------------------------------------------------------------[+]"
sleep 3

# ------------- Terminal themes use 94 ---------------
bash -c  "$(wget -qO- https://git.io/vQgMr)"

# ------------- IO scheduler ---------------
# Before 
for d in /sys/block/*; do
    echo -n "$d: "
    cat $d/queue/scheduler
done

sudo tee /etc/udev/rules.d/60-ssd-scheduler.rules <<'EOF'
# set I/O scheduler to 'none' for all non-rotational drives
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
EOF

sudo udevadm control --reload
sudo udevadm trigger --type=devices --subsystem-match=block

# After
for d in /sys/block/*; do
    echo -n "$d: "
    cat $d/queue/scheduler
done

# ------------- konsole ---------------
sudo apt update -y
sudo apt install -y fonts-firacode qt5ct adwaita-qt
mkdir -p ~/.local/share/konsole
# echo 'export QT_QPA_PLATFORMTHEME=qt5ct' | sudo tee /etc/profile.d/qt5ct.sh
qt5ct

# -------------- fonts -------------- 
# download microsoft core fonts
wget http://ftp.us.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.8.1_all.deb -P ~/Downloads

# install the .deb (no need for --no-install-recommends, dpkg handles it)
sudo dpkg -i ~/Downloads/ttf-mscorefonts-installer_3.8.1_all.deb
sudo cp -v -r /usr/share/fonts/truetype/msttcorefonts /usr/local/share/fonts/msttcorefonts2
sudo apt-get purge -y ttf-mscorefonts-installer

# fix missing dependencies if any
sudo apt-get install -f -y

# refresh font cache
sudo dpkg-reconfigure fontconfig
sudo fc-cache -fv

# -------------- system tweaks -------------- 
sudo journalctl --vacuum-size=40M
sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=100M/' /etc/systemd/journald.conf
sudo sed -i 's/#SystemMaxFiles=100/SystemMaxFiles=7/g' /etc/systemd/journald.conf
sudo journalctl --rotate
sudo rm -v /var/log/*.log* /var/log/syslog*
sudo sed -i 's/rotate 7/rotate 1/g' /etc/logrotate.d/rsyslog
sudo sed -i 's/rotate 4/rotate 1/g' /etc/logrotate.d/rsyslog
sudo sed -i 's/weekly/daily/g' /etc/logrotate.d/rsyslog
sudo sed -i 's/rotate 4/rotate 1/g' /etc/logrotate.conf
sudo sed -i 's/weekly/daily/g' /etc/logrotate.conf

# -------------- samba tweaks -------------- 
echo "👤 detected user: $real_user"
echo "🏠 user home: $user_home"

# install samba packages
echo "🌀 updating and installing samba packages..."
apt update
apt install -y samba samba-common-bin smbclient

# enable and start samba services
echo "⚙️ enabling and starting samba services..."
systemctl enable --now smbd nmbd
systemctl status smbd nmbd --no-pager

# create public share
share_dir="/srv/samba/public"
echo "📂 creating public share at $share_dir"
mkdir -p "$share_dir"
chown -R "$real_user:$real_user" "$share_dir"
chmod -R 0777 "$share_dir"
ls -ld "$share_dir"

# set samba password for real user
echo "🔑 setting samba password for $real_user"
smbpasswd -a "$real_user"

# ensure permissions and restart services
chmod 0777 "$share_dir"
systemctl restart smbd nmbd

# allow firewall access
echo "🛡️ updating ufw for samba..."
ufw allow Samba

# test samba configuration
echo "🧪 testing samba config..."
testparm

# list shares for verification
smbclient -L localhost -U "$real_user"

echo "✅ samba setup complete — public share ready at $share_dir"

# -------------- Nix package manager -------------- 
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) –daemon
sudo systemctl enable nix-daemon.service --now
sudo systemctl status nix-daemon.service --no-pager -n 10

# ensure nix profile is loaded
if [ -f /etc/profile.d/nix.sh ]; then
    . /etc/profile.d/nix.sh
fi

# define shell.nix path
SHELL_NIX="$user_home/shell.nix"

# write shell.nix
cat > "$SHELL_NIX" <<'EOF'
with import <nixpkgs> {};

mkShell {
  buildInputs = [
    duf
    hello
    htop
    neofetch
    pipx
  ];

  shellHook = ''
    echo "welcome to nix shell with my tools"
  '';
}
EOF

echo "shell.nix created at $SHELL_NIX"

# install packages globally for permanent availability
nix-env -iA nixpkgs.hello nixpkgs.htop nixpkgs.neofetch nixpkgs.duf nixpkgs.pipx

# verify installation
nix --version
hello
neofetch
duf

# -------------- zsh + oh-my-zsh setup -------------- 
echo "🚀 starting zsh + oh-my-zsh setup..."

# ensure zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
    echo "📦 installing zsh..."
    sudo apt update && sudo apt install zsh git curl -y
fi

# set zsh as default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "⚙️ setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

# install oh-my-zsh if missing
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🌐 installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "✅ oh-my-zsh already installed."
fi

# set custom dir var
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# install powerlevel10k
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "💎 installing powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
else
    echo "✅ powerlevel10k already installed."
fi

# install plugins
declare -A plugins=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
)

for plugin in "${!plugins[@]}"; do
    dest="$ZSH_CUSTOM/plugins/$plugin"
    if [ ! -d "$dest" ]; then
        echo "🔌 installing $plugin..."
        git clone "${plugins[$plugin]}" "$dest"
    else
        echo "✅ $plugin already installed."
    fi
done

# install fzf and autojump
echo "📦 ensuring fzf and autojump installed..."
sudo apt install fzf autojump fonts-powerline -y

# write custom .zshrc
echo "🧾 writing new ~/.zshrc..."
cat <<'EOF' >~/.zshrc
# tolga's zsh setup

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  autojump
  colored-man-pages
  extract
  fzf
  git
  sudo
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# instant prompt for speed
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_all_dups share_history

alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias cls='clear'
alias please='sudo $(fc -ln -1)'
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555'
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

export LANG=en_US.UTF-8
export PATH="$HOME/.local/bin:$PATH"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

typeset -g POWERLEVEL9K_MODE=nerdfont-v3

alias ls='eza --icons=always --group-directories-first --color=auto'
alias ll='eza -lah --icons=always --group-directories-first --color=auto'
alias la='eza -a --icons=always --group-directories-first --color=auto'

# ------------------------- MY ALIAS ---------------------------------------------------------
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
NC="\033[0m"

perm() {
MEGA_DIR="/home/tolga/Documents/MEGA"
USER="tolga"
GROUP="tolga"

notify() {
  /usr/bin/notify-send "MEGAsync Setup" "$1" \
    --app-name="MEGA Service" \
    -i mega
  echo -e "\e[1;32m[✔] $1\e[0m"
}

echo -e "\e[1;34m=== MEGA Directory Preparation ===\e[0m"

# Step 1: Create directory if missing
if [ ! -d "$MEGA_DIR" ]; then
  mkdir -p "$MEGA_DIR"
  notify "Created MEGA directory at $MEGA_DIR"
else
  notify "MEGA directory already exists"
fi

# fix ownership
sudo chown -R "$USER:$GROUP" "$MEGA_DIR"
notify "Ownership set to $USER:$GROUP"

# fix permissions
chmod -R 774 "$MEGA_DIR"
notify "Permissions locked down to (774)"

echo -e "\e[1;34m=== Preparation Complete brother ===\e[0m"
notify "MEGA folder is ready for sync! Enjoy"
}

check-io(){
#!/usr/bin/env bash
# Tolga Erok
# Purpose: Check & report SSD/NVMe schedulers in style

echo -e "\e[1;34m=== IO Scheduler Audit: Aurora, Fedora, NixOS && Mint ===\e[0m"

for dev in /sys/block/*; do
    name=$(basename "$dev")
    sched_file="$dev/queue/scheduler"

    # Skip loopback, RAM, CD-ROM etc.
    [[ ! -f "$sched_file" ]] && continue

    sched=$(cat "$sched_file")
    active=$(echo "$sched" | grep -oP '\[\K[^\]]+')

    # Highlight if active scheduler is not none
    if [[ "$active" != "none" ]]; then
        echo -e "\e[1;31m$name: active scheduler is '$active', should be none\e[0m"
    else
        echo -e "\e[1;32m$name: active scheduler is 'none' ✅\e[0m"
    fi
done

echo -e "\e[1;34m=== Audit Complete ===\e[0m"
}

upt() {
  # Read uptime value (seconds) from /proc/uptime, strip the decimal part
  uptime=$(cut -d ' ' -f 1 /proc/uptime | cut -d '.' -f 1)

  # Calculate days, hours, and minutes
  d=$((uptime / 86400))
  h=$(((uptime % 86400) / 3600))
  m=$(((uptime % 3600) / 60))

  # Print formatted uptime
  printf "    🕒 Uptime: %d day%s %dh %dm\n" $d $( [ $d -ne 1 ] && echo "s" || echo "" ) $h $m
  echo ""
}

alias io="
for d in /sys/block/sd*; do
    echo -n \"\$d: \"
    cat \"\$d/queue/scheduler\" | sed 's/.*\\[\\(.*\\)\\].*/\\1/'
done
"
# --- YAD Helper Function ---#
fancy() {
  yad --center --width=400 --height=120 --window-icon=dialog-information --borders=10 \
    --title="LinuxTweaks NVIDIA Installer" --text="$1" --button=gtk-ok:0 --no-buttons &
  YAD_PID=$!
  bash -c "$2"
  kill $YAD_PID
}

cake2() {
iface=$(nmcli -t -f DEVICE,STATE device | awk -F: '$2=="connected" && $1!="lo" {print $1; exit}')
if [ -z "$iface" ]; then
    echo "no active non-loopback interface found"
    exit 1
fi

# determine RTT and speed
if [[ "$iface" =~ ^wl ]]; then
    rtt=50
    speed=$(iw dev "$iface" link 2>/dev/null | awk '/tx bitrate/ {print $3}')
    [ -z "$speed" ] && speed=100
else
    rtt=5
    speed=$(ethtool "$iface" 2>/dev/null | awk -F: '/Speed/ {gsub(/[^0-9]/,"",$2); print $2}')
    [ -z "$speed" ] && speed=1000
fi

echo "applying CAKE to $iface: bandwidth=${speed}Mbit rtt=${rtt}ms"
sudo tc qdisc replace dev "$iface" root cake bandwidth "${speed}Mbit" diffserv3 triple-isolate nonat nowash no-ack-filter split-gso rtt "${rtt}ms" raw overhead 0
tc -s qdisc show dev "$iface"
}

alias zramstatus='sudo systemctl status linux-tweaks-zram.service --no-pager; swapon --show; free -h'

fancy_progress() {
  (
    # total steps you plan to run, or just loop for time-consuming task
    echo "0"  # start at 0%
    
    # run your command and update progress in real-time
    "$@" | while IFS= read -r line; do
      echo "$line"  # you can send numeric progress if command outputs it
      sleep 0.1     # optional, smooth animation
    done
  ) | yad --progress \
         --title="LinuxTweaks Task" \
         --width=400 \
         --height=120 \
         --window-icon=dialog-information \
         --auto-close \
         --percentage=0 \
         --text="Running, please wait..." 
}

fancy_progress bash -c '
for i in {1..8}; do
  echo $i
  sleep 0.1
done
'
clear && echo && fortune | sed "s/^/    /" | lolcat && echo && upt
EOF

sudo apt install eza -y 

mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

# download all four MesloLGS Nerd Fonts
wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

fc-cache -fv

sudo mkdir -p /usr/share/fonts/NerdFonts
cd /usr/share/fonts/NerdFonts
sudo wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip
sudo unzip Meslo.zip
sudo fc-cache -fv

exec zsh
sudo chsh -s /bin/zsh $USER
echo $SHELL

echo "✨ setup complete."

# back up configs
mkdir -p ~/ohmyzsh-backup
cp -r ~/.oh-my-zsh ~/ohmyzsh-backup/
cp ~/.zshrc ~/ohmyzsh-backup/
cp ~/.zsh_history ~/ohmyzsh-backup/

# backup restore
#cp -r ~/ohmyzsh-backup/.oh-my-zsh ~/
#cp ~/ohmyzsh-backup/.zshrc ~/
#cp ~/ohmyzsh-backup/.zsh_history ~/

echo "💡 restart your terminal or run 'exec zsh' then 'p10k configure' to finish style setup."
echo "💡 Or simetimes log out and login again"
