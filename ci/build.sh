#!/bin/bash
# Runs inside the Arch Linux ARM container, as root. /work is the repository.
set -euo pipefail
cd /work

# pacman >= 7 sandboxes downloads with Landlock, which Docker does not allow.
PM=(pacman)
pacman --help 2>&1 | grep -q -- --disable-sandbox && PM=(pacman --disable-sandbox)

pacman-key --init
pacman-key --populate archlinuxarm
"${PM[@]}" -Syu --noconfirm --needed base-devel git gnupg
. /work/PKGBUILD
"${PM[@]}" -S --noconfirm --needed "${makedepends[@]}"

useradd -m builder
chown -R builder:builder /work
install -d -o builder -g builder /out

su builder -c 'gpg --batch --import /work/keys/*.asc'
su builder -c 'cd /work && MAKEFLAGS="-j$(nproc)" makepkg -f --noconfirm --nodeps 2>&1 | tee /out/build.log'
cp /work/*.pkg.tar.zst /out/
cd /out && sha256sum *.pkg.tar.zst > SHA256SUMS && cat SHA256SUMS
