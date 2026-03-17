---
name: ubuntu-vm
description: Use when creating an Ubuntu Desktop VM on Steam Deck (SteamOS) with KVM/Virt-Manager for AI Agent automation, software testing, or development environments requiring a separate Linux system.
---

# Ubuntu VM on Steam Deck

Create an Ubuntu Desktop VM via KVM with SSH access, so AI Agents (Claude Code, Codex, Gemini…) can directly operate the VM via `ssh user@ip`.

## Critical: Long Commands MUST Be Written to .sh Files

**Never paste multi-word commands directly into terminal.** SteamOS terminal auto-wraps long lines and breaks them mid-argument. Always write commands to `/tmp/*.sh`, then prompt the user to run `sudo bash /tmp/filename.sh`.

## Phase 1: Infrastructure

Write `/tmp/vm-setup-phase1.sh` (use Write tool):
```bash
#!/bin/bash
set -e
steamos-readonly disable
pacman -S --noconfirm --needed qemu-desktop libvirt dnsmasq virt-install edk2-ovmf
systemctl start libvirtd && systemctl enable libvirtd
usermod -aG libvirt deck
```
Prompt: `sudo bash /tmp/vm-setup-phase1.sh`

Write `/tmp/vm-setup-network.sh`:
```bash
#!/bin/bash
set -e
cat > /etc/firewalld/zones/libvirt.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<zone target="ACCEPT">
  <short>libvirt</short>
  <description>The libvirt zone for virtual network interfaces.</description>
  <interface name="virbr0"/>
  <protocol value="icmp"/>
  <protocol value="ipv6-icmp"/>
  <service name="dhcp"/>
  <service name="dhcpv6"/>
  <service name="dns"/>
  <service name="ssh"/>
  <service name="tftp"/>
</zone>
EOF
firewall-cmd --reload
virsh net-start default 2>/dev/null || true
virsh net-autostart default
```
Prompt: `sudo bash /tmp/vm-setup-network.sh`

## Phase 2: Download ISO

Use WebFetch to load `https://releases.ubuntu.com/24.04/`, find the current `ubuntu-*-desktop-amd64.iso` filename (e.g. `ubuntu-24.04.4-desktop-amd64.iso`). Then prompt:
```bash
wget -c -P ~/Downloads https://releases.ubuntu.com/24.04/<FILENAME>
```

## Phase 3: Create VM

Check idempotency first: `sudo virsh dominfo ubuntu-2404 2>/dev/null` — if exists, ask user.

Write `/tmp/vm-create.sh` with actual ISO filename substituted:
```bash
#!/bin/bash
set -e
mkdir -p /home/deck/VMs
virt-install --name ubuntu-2404 --ram 8192 --vcpus 4 --disk path=/home/deck/VMs/ubuntu-2404.qcow2,size=25,format=qcow2 --cdrom /home/deck/Downloads/REPLACE_ISO --os-variant ubuntu24.04 --network network=default --graphics spice --video virtio --check disk_size=off --noautoconsole
```
Prompt: `sudo bash /tmp/vm-create.sh`

## Phase 4: Ubuntu Installation (User-interactive)

1. Prompt user to open **Virt-Manager** (Flatpak) → double-click `ubuntu-2404`
2. **Important:** Click **"Install Ubuntu"** — not just use the Live session
3. After install, ask user for: username and password
4. Ask user to run inside VM terminal:
   ```bash
   sudo apt install -y openssh-server ssh-askpass-gnome
   ```

## Phase 5: SSH Setup

**Get VM IP** (no guest agent needed):

Write `/tmp/vm-get-ip.sh`:
```bash
#!/bin/bash
virsh net-dhcp-leases default
```
Prompt: `sudo bash /tmp/vm-get-ip.sh`

Parse the IP (e.g. `192.168.122.x`).

**Setup key auth** (run on host):
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" 2>/dev/null || true
ssh-copy-id <user>@<ip>
```
User enters VM password when prompted.

**Verify:**
```bash
ssh <user>@<ip> echo "VM ready"
```

**Eject ISO** after SSH is verified (not before — reboot could change IP):

Write `/tmp/vm-eject.sh`:
```bash
#!/bin/bash
CDROM=$(virsh domblklist ubuntu-2404 | awk '/iso/{print $1}')
[ -n "$CDROM" ] && virsh change-media ubuntu-2404 "$CDROM" --eject || true
```
Prompt: `sudo bash /tmp/vm-eject.sh`

## Known Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| `virsh net-start default` → "can't find libvirt zone" | firewalld zone missing/broken XML | Write correct zone XML → `firewall-cmd --reload` |
| `virt-install` → disk space error | `/var/lib/libvirt/images/` on system partition (~200MB free) | Use `~/VMs/` on home partition |
| VM → "No bootable device" | User exited Live CD without installing | Reattach ISO: `virsh change-media ubuntu-2404 <dev> <iso-path> --insert` then `virsh start ubuntu-2404` |
| `virsh domifaddr` returns empty | No qemu-guest-agent in VM | Use `virsh net-dhcp-leases default` instead |
| Packages gone after SteamOS update | SteamOS resets system partition | Re-run Phase 1 |
| SSH from agent sandbox fails | No askpass / password auth only | Install `ssh-askpass-gnome` in VM + key auth on host |
