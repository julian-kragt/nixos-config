# Replace this stub with the file generated on the target by:
#   nixos-generate-config --root /mnt --no-filesystems
# (disko handles fileSystems, so we use --no-filesystems to avoid duplication).
#
# Until then, this stub provides minimal kernel modules that work for most
# x86_64 servers in Phase 1 testing. nixos-anywhere will overwrite this file
# from the live ISO during install if you add `--generate-hardware-config`.
{ ... }:
{
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "sd_mod"
    "virtio_pci"
    "virtio_scsi"
    "xhci_pci"
  ];
  boot.kernelModules = [
    "kvm-intel"
    "kvm-amd"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = false;
  hardware.cpu.amd.updateMicrocode = false;
}
