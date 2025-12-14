{
  description = "[TODO]";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote";
    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, lanzaboote, plasma-manager, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {inherit system;};
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.BXR = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit unstable;
        };
        modules = [
          lanzaboote.nixosModules.lanzaboote
          ./hosts/BXR/hardware-configuration.nix
          ./modules/profiles.nix

          home-manager.nixosModules.home-manager {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;

            # Adding windows to boot menu
            boot.loader.efi.canTouchEfiVariables = true;
            boot.loader.systemd-boot.extraEntries = {
              "windows.conf" = ''
                title Windows 10
                sort-key 01-windows
                 efi /EFI/Microsoft/Boot/bootmgfw.efi
              '';
            };

            # boot.kernelParams = [ "usbcore.autosuspend=-1" ]; # attempting to get Bluetooth to work on boot, makes USB ports powered all the time
            # boot.kernelModules = [ "btusb" ]; # attempting to get Bluetooth to work on boot, makes it boot early

            networking.hostName = "BXR";
            time.timeZone = "Europe/Warsaw";
            networking.networkmanager.enable = true;

            profiles.base.enable = true;
            profiles.desktop.enable = true;
            profiles.bluetooth.enable = true;
            profiles.syncthing.enable = true;
            profiles.VNC.enable = true;
            profiles.core.enable = true;
            profiles.gaming.enable = true;
            profiles.nvidia.enable = true;
            profiles.kdeapps.enable = true;
            profiles.globalpython.enable = true;
            profiles.secureboot.enable = true;
            profiles.netsec.enable = true;
            profiles.starsector.enable = true;
            profiles.minecraft.enable = true;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              pm = plasma-manager;
            };
            home-manager.users.deltarnd = import ./home/common.nix;

            system.stateVersion = "25.05"; # don't touch, ever
          }
        ];
      };

      nixosConfigurations.USB = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/USB/hardware-configuration.nix
          ./modules/profiles.nix
          home-manager.nixosModules.home-manager {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;

            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            boot.loader.grub.enable = false;

            networking.hostName = "USB";
            time.timeZone = "Europe/Warsaw";
            networking.networkmanager.enable = true;

            profiles.base.enable = true;
            profiles.desktop.enable = true;
            profiles.core.enable = true;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              pm = plasma-manager;
            };
            home-manager.users.deltarnd = import ./home/common.nix;

            system.stateVersion = "25.05"; # don't touch, ever
          }
        ];
      };

      nixosConfigurations.M720 = lib.nixosSystem {
        inherit system;
        modules = [
          lanzaboote.nixosModules.lanzaboote # [TODO] no machine can start without lanzaboote, FIX [BUG]
          ./hosts/M720/hardware-configuration.nix
          ./modules/profiles.nix


          home-manager.nixosModules.home-manager {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;

            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            boot.loader.grub.enable = false;

            networking.hostName = "m720";
            time.timeZone = "Europe/Warsaw";
            networking.networkmanager.enable = true;

            profiles.base.enable = true;
            profiles.globalpython.enable = true;
            profiles.desktop.enable = true;
            profiles.minecraftserver.enable = true;

            services.openssh.enable = true; # [TODO] configure a proper SSH module
            services.openssh.settings = {
              PasswordAuthentication = true;   # disable later after keys
              };

            # remote desktop
            services.xrdp.enable = true;
            services.xrdp.defaultWindowManager = "startplasma-x11";
            networking.firewall.allowedTCPPorts = [ 3389 22 ];
            networking.firewall.allowedUDPPorts = [ 5353 ]; # for avahi

            # avoiding IP's with remote desktop [TODO] add it to proper module
            services.avahi = {
              enable = true;
              nssmdns = true;
            };


            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              pm = plasma-manager;
            };
            home-manager.users.deltarnd = import ./home/common.nix;

            system.stateVersion = "25.05"; # don't touch, ever
          }
        ];
      };

    devShells.${system} = rec {

      py-pipwheel = pkgs.mkShell {
        packages = with pkgs; [
          python312
        ];

        # expose libstdc++ & friends on the search path for wheels
        env.LD_LIBRARY_PATH = lib.makeLibraryPath [
          (lib.getLib pkgs.stdenv.cc.cc)  # libstdc++.so.6
          pkgs.zlib
          pkgs.glibc
        ];

        shellHook = ''
          # ensure the manylinux loader shim is present in devshells
          if [ -f /etc/profile.d/nix-ld.sh ]; then
            . /etc/profile.d/nix-ld.sh
          fi
          # keep venvs sane
          unset PYTHONPATH
          export PS1="(py-pipwheel) $PS1"
        '';
      };

      py-playwright = pkgs.mkShell {
        packages = with pkgs; [
          python312
          nodejs                 # Playwright's driver is a Node tool
          playwright-driver      # prebuilt browsers + driver, Nix-wrapped
          chromium
        ];

        env.LD_LIBRARY_PATH = lib.makeLibraryPath [
          (lib.getLib pkgs.stdenv.cc.cc)  # libstdc++.so.6
          pkgs.zlib
          pkgs.glibc
        ];

        # Tell Python Playwright to use Nix’s browsers and skip downloads
        env.PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
        env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

        shellHook = ''
          if [ -f /etc/profile.d/nix-ld.sh ]; then
          . /etc/profile.d/nix-ld.sh
          fi
          unset PYTHONPATH
          export PS1="(py-playwright) $PS1"
        '';
      };
    };
  };
}
