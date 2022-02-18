# PC config
# docref: <nixpkgs/..>

{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./hardware-configuration.nix
    "${lib.nixos-hardware}/common/cpu/intel"
    # "${lib.nixos-hardware}/common/gpu/amd"
  ];

  # Name the child
  networking.hostName = "rechner";

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot.enable = mkForce false;

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
      efiSysMountPoint = "/boot";
    };
    grub = {
      # despite what the configuration.nix manpage seems to indicate,
      # as of release 17.09, setting device to "nodev" will still call
      # `grub-install` if efiSupport is true
      # (the devices list is not used by the EFI grub install,
      # but must be set to some value in order to pass an assert in grub.nix)
      devices = [ "nodev" ];
      efiSupport = true;
      enable = true;

      timeout = 20;
      # default = "saved";
      default = "1";

      # set $FS_UUID to the UUID of the EFI partition
      extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --fs-uuid --set=root $FS_UUID
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }

        menuentry "Kiosk todo" {
          insmod search_fs_uuid
          search --set=kiosk --fs-uuid bf148b15-da46-4db1-bac4-ce69ec7eeae6
          configfile "($kiosk)/boot/grub/grub.cfg"
        }
      '';
      version = 2;
    };
  };
}
