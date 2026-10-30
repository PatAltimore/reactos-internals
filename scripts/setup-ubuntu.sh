#!/usr/bin/env bash
# Set up an Ubuntu machine for ReactOS development: packages, swap, KVM access,
# a clone of your fork, and helpers to install and run ReactOS in QEMU.
#
#   ./setup-ubuntu.sh setup               one-time machine setup
#   ./setup-ubuntu.sh clone               clone the fork and add the upstream remote
#   ./setup-ubuntu.sh qemu-install ISO    create a disk image and boot the installer
#   ./setup-ubuntu.sh qemu-run            boot the installed system from the disk image
#
# It does NOT install RosBE (the ReactOS build environment); see the end of "setup".
# Written for Ubuntu 24.04 on a low-memory machine; read it before running it.

set -euo pipefail

FORK_URL="${FORK_URL:-https://github.com/PatAltimore/reactos.git}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/reactos/reactos.git}"
WORKDIR="${WORKDIR:-$HOME/reactos-dev}"
SWAP_SIZE="${SWAP_SIZE:-4G}"
SWAPFILE="${SWAPFILE:-/swapfile}"
VM_DIR="${VM_DIR:-$WORKDIR/vm}"
VM_DISK="$VM_DIR/reactos.qcow2"
VM_DISK_SIZE="${VM_DISK_SIZE:-8G}"
VM_RAM="${VM_RAM:-512}"

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

check_ubuntu() {
    [ -r /etc/os-release ] || die "cannot read /etc/os-release"
    . /etc/os-release
    if [ "${ID:-}" != "ubuntu" ]; then
        die "this script is written for Ubuntu (found: ${ID:-unknown})"
    fi
    echo "Ubuntu ${VERSION_ID:-?}"
}

report_machine() {
    say "Machine"
    free -h | sed -n '1,2p'
    df -h "$HOME" | sed -n '1,2p'
    local virt
    virt=$(grep -E -c '(vmx|svm)' /proc/cpuinfo || true)
    if [ "${virt:-0}" -gt 0 ]; then
        echo "Hardware virtualization: yes (KVM can be used)"
    else
        echo "Hardware virtualization: NO - QEMU will be very slow"
    fi
}

add_swap() {
    say "Swap"
    if swapon --show=NAME --noheadings | grep -q .; then
        echo "Swap is already active:"
        swapon --show
        return
    fi
    if [ -e "$SWAPFILE" ]; then
        echo "$SWAPFILE exists but is not active; leaving it alone. Activate it yourself if it is yours."
        return
    fi
    echo "Creating a $SWAP_SIZE swap file at $SWAPFILE (needs sudo)."
    sudo fallocate -l "$SWAP_SIZE" "$SWAPFILE"
    sudo chmod 600 "$SWAPFILE"
    sudo mkswap "$SWAPFILE"
    sudo swapon "$SWAPFILE"
    if ! grep -q "^$SWAPFILE " /etc/fstab; then
        echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
        echo "Added $SWAPFILE to /etc/fstab so it survives reboots."
    fi
}

install_packages() {
    say "Packages"
    # Prerequisites listed in RosBE-Unix's README (bash, gcc/g++, grep, make, texinfo,
    # zlib) plus git, ccache and QEMU.
    sudo apt-get update
    sudo apt-get install -y build-essential texinfo zlib1g-dev git ccache qemu-system-x86 qemu-utils
}

kvm_access() {
    say "KVM access"
    if id -nG "$USER" | tr ' ' '\n' | grep -qx kvm; then
        echo "$USER is already in the kvm group."
    else
        sudo usermod -aG kvm "$USER"
        echo "Added $USER to the kvm group. Log out and back in for it to take effect."
    fi
}

git_identity() {
    say "Git identity"
    local name email
    name=$(git config --global user.name || true)
    email=$(git config --global user.email || true)
    echo "user.name : ${name:-<not set>}"
    echo "user.email: ${email:-<not set>}"
    case "$email" in
        ""|*noreply.github.com*)
            echo
            echo "ReactOS requires your real name and a real email on every commit, and GitHub's"
            echo "'Keep my email addresses private' must be off. Set them with:"
            echo "  git config --global user.name  \"Your Real Name\""
            echo "  git config --global user.email \"you@example.com\""
            ;;
    esac
}

cmd_setup() {
    say "Checking system"
    check_ubuntu
    report_machine
    add_swap
    install_packages
    kvm_access
    git_identity
    say "Next steps"
    cat <<EOF
1. Log out and back in (for the kvm group), then run:  $0 clone
2. Install RosBE for Unix. Follow https://reactos.org/wiki/Build_Environment
   Its builder script compiles the cross-compiler on your machine; this takes a long time
   on a low-memory laptop and needs the packages installed above.
   If the builder fails on Ubuntu 24.04, ask in the project chat which RosBE setup is
   current before debugging it for hours.
3. In a RosBE shell, from a build directory OUTSIDE the source tree:
     $WORKDIR/reactos/configure.sh -DENABLE_ROSTESTS=1 -DENABLE_CCACHE=1
     ninja -j2 bootcd
   Keep -j low on this machine; use -j1 if the build is killed for lack of memory.
4. Install and boot the resulting ReactOS.iso:  $0 qemu-install /path/to/ReactOS.iso
EOF
}

cmd_clone() {
    say "Cloning the fork into $WORKDIR/reactos"
    mkdir -p "$WORKDIR"
    if [ -d "$WORKDIR/reactos/.git" ]; then
        echo "Already cloned."
    else
        git clone "$FORK_URL" "$WORKDIR/reactos"
    fi
    cd "$WORKDIR/reactos"
    if ! git remote | grep -qx upstream; then
        git remote add upstream "$UPSTREAM_URL"
    fi
    git remote -v
    echo
    echo "Keep your fork current with:  git fetch upstream && git merge upstream/master"
    echo "Work on a topic branch, never on master:  git switch -c fix-something"
}

qemu_args() {
    local accel=()
    if [ -w /dev/kvm ]; then
        accel=(-enable-kvm)
    else
        echo "warning: /dev/kvm is not usable (not in the kvm group yet?); running without KVM." >&2
    fi
    printf '%s\n' "${accel[@]}" -m "$VM_RAM" -hda "$VM_DISK"
}

cmd_qemu_install() {
    local iso="${1:-}"
    [ -n "$iso" ] || die "usage: $0 qemu-install /path/to/ReactOS.iso"
    [ -f "$iso" ] || die "no such file: $iso"
    mkdir -p "$VM_DIR"
    if [ ! -f "$VM_DISK" ]; then
        say "Creating $VM_DISK ($VM_DISK_SIZE)"
        qemu-img create -f qcow2 "$VM_DISK" "$VM_DISK_SIZE"
    fi
    say "Booting the installer (RAM: ${VM_RAM} MB)"
    mapfile -t args < <(qemu_args)
    exec qemu-system-i386 "${args[@]}" -cdrom "$iso" -boot d
}

cmd_qemu_run() {
    [ -f "$VM_DISK" ] || die "no disk image at $VM_DISK; run qemu-install first"
    say "Booting ReactOS from $VM_DISK (RAM: ${VM_RAM} MB)"
    mapfile -t args < <(qemu_args)
    exec qemu-system-i386 "${args[@]}" -boot c
}

case "${1:-}" in
    setup)        cmd_setup ;;
    clone)        cmd_clone ;;
    qemu-install) shift; cmd_qemu_install "$@" ;;
    qemu-run)     cmd_qemu_run ;;
    *)
        sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
