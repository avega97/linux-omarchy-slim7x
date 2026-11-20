# linux-omarchy-slim7x

Experimental Arch Linux ARM kernel package for the **Lenovo Yoga Slim 7x** (Snapdragon X Elite),
built from the Omarchy aarch64 kernel recipe on **linux 7.3.5**, plus the Slim 7x patches from
[aruhier/linux-slim7x-x1e](https://github.com/aruhier/linux-slim7x-x1e).

**Untested. Do not install over your only kernel.** It installs next to `linux-omarchy`
(own `pkgbase`, own `/usr/lib/modules/7.3.5-1-omarchy-slim7x`), but booting it needs a bootloader entry
and a matching DTB (`/usr/lib/modules/<version>/dtb/qcom/x1e80100-lenovo-yoga-slim7x.dtb`).

## What is in it
- Base: kernel.org `linux-7.3.5` (PGP-verified), Omarchy `config.aarch64`.
- 482 patches from [omacom/omarchy-pkgs](https://github.com/omacom/omarchy-pkgs)
  (`pkgbuilds/linux-omarchy-aarch64`), minus those that 7.3.5 already contains, those for Intel/AMD/ROG
  hardware, the NVIDIA N1x / MediaTek series, the `mm` opportunistic-compaction series
  (7.3.5 has its own `reclaim_compact_order`, which overlaps it) and the Glymur (Snapdragon X2) USB4
  patches that depend on the N1x ones. Dropped patches were found by applying the series on a clean
  7.3.5 tree and compiling the affected directories.
  Two were rebased by hand: `iris` (power-off IRQ) and `wsa884x` (PA recovery), marked `[omarchy-slim7x: ...]`.
- 7 patches from aruhier's tree (the last seven entries (plus a one-line export fix, `0520`) of `patches/series`): Slim 7x embedded-controller
  node, EC reset GPIO, lid wake on both edges, GPIO 71 documentation, two `qcom-hamoa-ec` driver fixes,
  NVMe dynamic PCIe link-speed scaling. The EC node, the EC reset GPIO and the SCI-suspend fix are in mainline 7.4-rc1.
- Config changes: `EC_QCOM_HAMOA=m`, `NVME_SPEED_SWITCH=y`.

`patches/series` is the application order; `patches/SHA256SUMS` is checked in `prepare()`.

## Build
Run the **Build kernel** workflow (Actions tab). It builds in an Arch Linux ARM container
(root filesystem signature-verified) and uploads the `.pkg.tar.zst` plus `SHA256SUMS` as an artifact.

All patches keep their original authors and licence (GPL-2.0).
