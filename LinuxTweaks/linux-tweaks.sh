#!/bin/bash
# 23/10/25
# LinuxTweaks tolga style — logical, surgical, calm for all brother's

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
    echo "welcome to nix shell with my tools"
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
