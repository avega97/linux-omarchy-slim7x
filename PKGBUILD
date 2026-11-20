# Maintainer: avega97
# Based on the linux-omarchy aarch64 recipe (omacom/omarchy-pkgs, pkgbuilds/linux-omarchy-aarch64),
# rebased on linux 7.3.5 for the Lenovo Yoga Slim 7x (Snapdragon X Elite), with the
# EC/lid/NVMe patches from aruhier/linux-slim7x-x1e. See README.md.
pkgbase=linux-omarchy-slim7x
pkgname=(linux-omarchy-slim7x)
_kernel=linux-omarchy-slim7x
pkgver=7.3.5
pkgrel=1
pkgdesc='Omarchy aarch64 kernel (BORE, ADIOS) on 7.3.5 for the Lenovo Yoga Slim 7x, with Qualcomm EC support'
url='https://github.com/avega97/linux-omarchy-slim7x'
arch=(aarch64)
license=(GPL-2.0-only)
makedepends=(bc binutils cpio gettext glibc libelf libgcc openssl pahole perl python tar xxhash xz zlib zstd)
options=(!debug !strip)
_srcname=linux-$pkgver
source=(
  https://cdn.kernel.org/pub/linux/kernel/v7.x/${_srcname}.tar.{xz,sign}
  config.aarch64
)
validpgpkeys=(
  ABAF11C65A2970B130ABE3C479BE3E4300411886  # Linus Torvalds
  647F28654894E3BD457199BE38DBBDC86092693E  # Greg Kroah-Hartman
  12D27D5D8C8E9BF1AABC7C7C7C64768D3DE334E7  # Krzysztof Wilczynski
)
sha256sums=('8f293f83d54f0b7b9be56863ebc5e4ea79d73e530b4ae55c572be97ef39f0990'
            'SKIP'
            '40143cf9a052400e6a14db18311f230770d63eb37538efb5305407a5bb216ed7')

prepare() {
  cd $_srcname

  echo "Setting version..."
  echo "-$pkgrel" > localversion.10-pkgrel
  echo "${_kernel#linux}" > localversion.20-pkgname

  echo "Checking patch checksums..."
  (cd "$startdir/patches" && sha256sum --quiet -c SHA256SUMS)

  local p
  while read -r p; do
    echo "Applying $p..."
    patch -Np1 --fuzz=0 < "$startdir/patches/$p"
  done < "$startdir/patches/series"

  echo "Setting config..."
  cp ../config.aarch64 .config
  # Qualcomm embedded controller (fan, thermal, lid) and NVMe link-speed switching
  scripts/config --module EC_QCOM_HAMOA --enable NVME_SPEED_SWITCH
  # Optional smaller builds: CONFIG_VARIANT=full (default) | aruhier | aruhier-extras
  case "${CONFIG_VARIANT:-full}" in
    full) ;;
    aruhier) cat "$startdir/config-fragments/aruhier-excludes.config" >> .config ;;
    aruhier-extras) cat "$startdir"/config-fragments/{aruhier,extra}-excludes.config >> .config ;;
    *) echo "unknown CONFIG_VARIANT=$CONFIG_VARIANT" >&2; return 1 ;;
  esac
  make olddefconfig
  diff -u ../config.aarch64 .config || :

  make -s kernelrelease > version
  echo "Prepared $_kernel version $(<version)"
}

build() {
  cd $_srcname
  MAKEFLAGS="-j$(nproc) $MAKEFLAGS"
  local dts=(arch/arm64/boot/dts/qcom/{x1,hamoa,glymur,mahua,sc8280xp,sc8180x,sdm850,msm8998-asus,msm8998-hp,msm8998-lenovo,sc7180-acer,sc7180-ecs,sc7280-samsung}*.dts)
  dts=("${dts[@]#arch/arm64/boot/dts/}")
  make Image modules "${dts[@]/%.dts/.dtb}"
}

package_linux-omarchy-slim7x() {
  depends=(coreutils initramfs kmod)
  optdepends=(
    'linux-firmware: firmware images needed for some devices'
    'scx-scheds: to use sched-ext schedulers'
    'wireless-regdb: to set the correct wireless channels of your country'
  )

  cd $_srcname
  local modulesdir="$pkgdir/usr/lib/modules/$(<version)"

  echo "Installing boot image..."
  # Limine's aarch64 Linux protocol needs the raw arm64 Image
  install -Dm644 arch/arm64/boot/Image "$modulesdir/vmlinuz"

  # Used by mkinitcpio to name the kernel
  echo "$_kernel" | install -Dm644 /dev/stdin "$modulesdir/pkgbase"

  echo "Installing modules..."
  ZSTD_CLEVEL=19 make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 \
    DEPMOD=/doesnt/exist modules_install

  echo "Installing device trees..."
  local dtb
  for dtb in arch/arm64/boot/dts/qcom/*.dtb; do
    install -Dm644 "$dtb" "$modulesdir/dtb/qcom/${dtb##*/}"
  done

  rm -f "$modulesdir"/build
}
