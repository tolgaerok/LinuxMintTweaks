# LinuxTweaks — Tolga Style
23/10/2025

*logical calm surgical tweaks for a faster cleaner linux experience*

### why i built this

i got tired of doing the same small fixes every time i installed linux.
you know the drill ... fonts missing, swap not tuned, grub half-asleep, wifi acting lazy, systemd hoarding logs like a dragon.
so i built this script. not out of frustration but curiosity and respect for the system.

i wanted a way to set up my workstation the same way i think ...
clean, minimal, logical. everything has its place.

this script became my way of making linux breathe a little easier.

---

### what this script does

#### ⚙️ system tuning

* sets **zswap** with **lz4 compression** and **zsmalloc** pool for smoother memory pressure handling
* automatically adjusts **swap size and swappiness** based on how much RAM you have
* mounts **/tmp in RAM** for faster temporary operations
* tunes **vm.dirty_ratio** and writeback values for SSD performance

#### 🔒 security & stability

* sets up a **UFW firewall** automatically
* allows the right ports for samba sharing and network discovery
* trims SSDs daily with **systemd fstrim** tweaks

#### 🧠 performance under xanmod kernel

* adds the right **kernel boot flags** for stability and speed
* rebuilds **grub and initramfs** cleanly without duplicate entries
* ensures **zsmalloc** is loaded early for zswap to work right

#### 🌐 wifi tuning

* disables power saving (stops random disconnects)
* reloads the wifi module for full throughput

#### 🖥️ usability and style

* installs essential apps like **helix**, **sublime-text**, **vlc**, **variety**, **plank**, and **okular**
* brings in clean readable fonts (**FiraCode**, **Ubuntu Classic**, **Noto**, and Microsoft core fonts**)
* improves **konsole** visuals with **qt5ct** and **adwaita-qt**
* sets up **numlock**, **double commander**, **nala**, and more for daily use

#### 🧹 system maintenance

* cleans up journal logs
* limits log sizes and rotations so your SSD doesn’t get flooded
* rebuilds caches and trims the fat

---

### how to use

1. clone or copy this repo
2. make the script executable

   ```bash
   chmod +x linux-tweaks.sh
   ```
3. run it with sudo

   ```bash
   sudo ./linux-tweaks.sh
   ```
4. grab a drink while it runs .. it’s doing hours of manual tweaking in minutes
5. reboot and enjoy your faster smoother linux

---

### after running

* check zswap status

  ```bash
  dmesg | grep zswap
  ```
* confirm swap size

  ```bash
  swapon --show
  free -h
  df -h /tmp
  lsmod | grep zsmalloc  
  systemctl status tmp.mount --no-pager
  sudo systemctl status fstrim.timer --no-pager  
  iwconfig  
  ```
* and breathe — your system just got smarter.

---

### what i learned

i learned patience. that tuning linux isn’t about fighting it.
it’s about understanding how each part breathes and helping it run free.
i felt proud the first time it all worked without an error.
this script carries that feeling ... calm logic and quiet power.

---

### thank you

if you’re using this tweak pack, thank you brother (or sister).
you’re walking the same path ... curious, disciplined, wanting better without breaking things.

stay sharp stay kind stay curious.
– **tolga** 🜏
