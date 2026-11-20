#!/bin/bash
# Runs inside the Arch Linux ARM container, as root. /work is the repository.
set -euo pipefail
cd /work

# pacman >= 7 sandboxes downloads with Landlock and seccomp, which Docker on the runner
# does not allow. Older versions only warn about the unknown directives.
for opt in DisableSandbox DisableSandboxFilesystem DisableSandboxSyscalls; do
  grep -q "^$opt" /etc/pacman.conf || sed -i "/^\[options\]/a $opt" /etc/pacman.conf
done
PM=(pacman)

pacman-key --init
pacman-key --populate archlinuxarm
# The mirrors are sometimes slow enough for pacman to give up on a download.
retry() { local n; for n in 1 2 3 4; do "$@" && return 0; echo "attempt $n failed" >&2; sleep 20; done; return 1; }

# The container never boots, so its own kernel and firmware are not worth updating.
retry "${PM[@]}" -Syu --noconfirm --needed --ignore linux-aarch64 --ignore 'linux-firmware*' base-devel git gnupg
. /work/PKGBUILD
retry "${PM[@]}" -S --noconfirm --needed "${makedepends[@]}"

retry "${PM[@]}" -S --noconfirm --needed ccache

useradd -m builder
chown -R builder:builder /work /ccache
install -d -o builder -g builder /out

su builder -c 'gpg --batch --import /work/keys/*.asc'
# ccache wraps gcc through its masquerade directory; the kernel tree is always built in the
# same path, so objects can be reused between runs.
CC_ENV='export PATH=/usr/lib/ccache/bin:$PATH CCACHE_DIR=/ccache CCACHE_MAXSIZE=3G CCACHE_COMPRESS=1 CCACHE_BASEDIR=/work'
su builder -c "$CC_ENV; ccache -z >/dev/null; cd /work && CONFIG_VARIANT='${CONFIG_VARIANT:-full}' MAKEFLAGS=\"-j\$(nproc)\" makepkg -f --noconfirm --nodeps 2>&1 | tee /out/build.log; rc=\${PIPESTATUS[0]}; ccache -s | tee /out/ccache-stats.txt; exit \$rc"
cp /work/*.pkg.tar.zst /out/
cd /out && sha256sum *.pkg.tar.zst > SHA256SUMS && cat SHA256SUMS
