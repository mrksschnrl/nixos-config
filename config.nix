{ config, lib, pkgs, modulesPath, ... }:

with lib;

{

  imports = [
    ./mkg/desktop.nix
    ./yggdrasil.nix
  ];

  environment.systemPackages = with pkgs; [
    blender
    google-chrome
    obs-studio
    tdesktop
    firefox
    element-desktop
    # TODO: davinci
    kdenlive
    anydesk

    # app util
    clipit
    pavucontrol
    helvum

    inxi
    hwloc
    # dev
    atom
    gitAndTools.gitFull
    git-lfs
    nodejs-16_x
    yarn
    ntfs3g
    htop
  ];

  # Network manager ftw
  networking.networkmanager.enable = true;
  # TODO: do we need this?
  networking.wireless.enable = mkForce false;

  programs.kdeconnect.enable = true;

  nixpkgs.config.allowUnfree = true;

  services.geoclue2 = {
    enable = true;
  };

  location.provider = "geoclue2";

  # def

  # Select internationalisation properties.
  console = {
    font = "Lat2-Terminus16";
    keyMap = "de";
  };

  i18n.defaultLocale = "en_US.UTF-8";

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  nix = {
    binaryCaches = [
      "https://cache.xeredo.it"
    ];
    binaryCachePublicKeys = [
      "cache.xeredo.it-1:Dlh2ON5d64vjGOSc7NTD7/64diyuZczokmGObFRjMvE="
    ];

    useSandbox = true;
    autoOptimiseStore = true;

    extraOptions = ''
      # In general, outputs must be registered as roots separately. However, even if the output of a derivation is registered as a root, the collector will still delete store paths that are used only at build time (e.g., the C compiler, or source tarballs downloaded from the network). To prevent it from doing so, set this option to true.
      gc-keep-outputs = true
      gc-keep-derivations = true
      env-keep-derivations = true

      # Cache TTLs
      # narinfo-cache-positive-ttl = 0
      # narinfo-cache-negative-ttl = 0

      ## Fix
      #experimental-features = nix-command
      '';

    trustedUsers = [ "root" "@wheel" ];
  };

  # Swap, watch fixes
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 20480000;
    "vm.swappiness" = 80;
  };


  # Enable GPG agent
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # Firmware updates
  services.fwupd.enable = true;

  # Faster boot through entropy seeding
  services.haveged.enable = true;

  # More stable desktop
  programs.cfs-zen-tweaks.enable = true;

  # Shutdown speed-up
  systemd.services.fwupd.serviceConfig = { TimeoutStopSec = 5; };

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=20s
  '';

  services.journald.extraConfig = ''
    SystemKeepFree=10G
    SystemMaxUse=1G
  '';

  boot.kernelPackages = pkgs.linuxPackages_latest; # only the latest

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mrks = {
    createHome = true;
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "wireshark" ];
  };

}
