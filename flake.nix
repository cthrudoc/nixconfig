{
  description = "[TODO]";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
    in {
      nixosConfigurations.BXR = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/BXR/hardware-configuration.nix
          ./modules/profiles.nix
          home-manager.nixosModules.home-manager {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;

            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            boot.loader.systemd-boot.extraEntries = {
              "windows.conf" = ''
                title Windows 10
                sort-key 01-windows
                 efi /EFI/Microsoft/Boot/bootmgfw.efi
              '';
            }; # Adding windows to boot menu
            boot.kernelParams = [ "usbcore.autosuspend=-1" ]; # attempting to get Bluetooth to work on boot, makes USB ports powered all the time
            boot.kernelModules = [ "btusb" ]; # attempting to get Bluetooth to work on boot, makes it boot early

            networking.hostName = "BXR";
            time.timeZone = "Europe/Warsaw";
            networking.networkmanager.enable = true;

            services.displayManager.sddm.enable = true;
            services.desktopManager.plasma6.enable = true;
            services.xserver.enable = true;

            services.displayManager.sddm.wayland.enable = true; # enable virtual keyboard support in Wayland session

            services.pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
            };

            profiles.core.enable = true;
            profiles.gaming.enable = true;
            profiles.nvidia.enable = true;
            profiles.kdeapps.enable = true;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
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

            services.displayManager.sddm.enable = true;
            services.desktopManager.plasma6.enable = true;
            services.xserver.enable = true;

            services.pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
            };

            profiles.core.enable = true;
            profiles.gaming.enable = true;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.deltarnd = import ./home/common.nix;

            system.stateVersion = "25.05"; # don't touch, ever
          }
        ];
      };
    };
}
