{
  description = "mkg's nixOS flavour";

  inputs.nixpkgs.url = "github:mkg20001/nixpkgs/mkg-patch-a";
  inputs.gitlab-lxd-image.url = "git+https://git.mkg20001.io/mkg20001/gitlab-lxd-image.git";
  inputs.solaros.url = "github:xeredo-solar/solaros-nix";
  inputs.solaros.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
  inputs.nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, gitlab-lxd-image, solaros, nixos-hardware }:
    let
      e = device: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        lib = nixpkgs.lib.extend (final: prev: {
          inherit nixos-hardware nixpkgs;
          flake = self;
        });

        modules = with nixpkgs.lib; [
          (import ./configuration.nix)
          device
          ({ config, ... }: {
            nix.registry.nixpkgs.flake = nixpkgs;
            nix.registry.mkg.flake = self;

            nixpkgs.overlays = builtins.attrValues self.overlays;

            nix.nixPath = [
              "nixos-config=/etc/nixos/configuration.nix"
            ] ++ (mapAttrsToList
              (key: value: "${key}=${value.to.path}")
              (filterAttrs (key: value: value ? to.path) config.nix.registry));

            imports = [
              "${solaros}/config/features/bluetooth.nix"
            ];
          })
        ];
      };

      # f = device: (e device).system;

      nixosConfigurations = {
        rechner = e ./devices/rechner;
      };
    in
    {
      inherit nixosConfigurations;

      packages.x86_64-linux = {
        image = (nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
            gitlab-lxd-image.nixosModules.gitlab-lxd-image
            ({ config, pkgs, lib, ... }: with lib; {
              environment.systemPackages = with pkgs; [
                cachix
                openssh
                # for some reason it uses the flake here, even tho we do with pkgs; so just force it
                pkgs.xzar
              ];

              nixpkgs = {
                overlays = [
                  xzar.overlay
                ];
              };

              programs.git.config.advice.detachedHead = false;

              nix = {
                binaryCaches = [
                  "https://mkg20001.cachix.org"
                  "https://xzar.s.xeredo.it"
                ];
                binaryCachePublicKeys = [
                  "mkg20001.cachix.org-1:dg0SpEMJfgL8EDI0NRkGUd+wMoUaSzhZURsz1vRt4wY="
                  "cache.xeredo.it-1:Dlh2ON5d64vjGOSc7NTD7/64diyuZczokmGObFRjMvE="
                ];
              };
            })
          ];
        }).config.system.build.gitlab-lxd-image;
      };

      legacyPackages.x86_64-linux = {
        # iso = self.nixosConfigurations.iso.config.system.build.isoImage;
        # vme = self.nixosConfigurations.vme.config.system.build.virtualBoxOVA;
        iso = (e ./devices/iso).config.system.build.isoImage;
        isoTPL = (e ./devices/iso).config.system.build.toplevel;
        vme = (e ./devices/vme).config.system.build.virtualBoxOVA;
        vmeTPL = (e ./devices/vme).config.system.build.toplevel;

        all = nixpkgs.legacyPackages.x86_64-linux.releaseTools.aggregate {
          name = "all-devices";
          constituents = map (c: c.config.system.build.toplevel) (builtins.attrValues nixosConfigurations);
        };
      };

      overlays = {};
    };
}
