{
  description = "[TODO]";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote";
    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";};
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";


  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, lanzaboote, plasma-manager, sops-nix, nixos-hardware, ... }:
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
          sops-nix.nixosModules.sops # secrets management

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
            profiles.nvidia.enable = false;
            profiles.kdeapps.enable = true;
            profiles.globalpython.enable = true;
            profiles.secureboot.enable = true;
            profiles.netsec.enable = true;
            profiles.starsector.enable = true;
            profiles.minecraft.enable = true;
            profiles.containers.enable = true;

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
      
      nixosConfigurations.GO3 = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit unstable;
        };
        modules = [
          # Surface Go hardware quirks + linux-surface stack
          nixos-hardware.nixosModules.microsoft-surface-go
          lanzaboote.nixosModules.lanzaboote # [TODO] now nothing boots without lanzaboote. turn it into a proper module!
      
          ./hosts/GO3/hardware-configuration.nix
          ./modules/profiles.nix
          sops-nix.nixosModules.sops
      
          home-manager.nixosModules.home-manager {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;
      
            networking.hostName = "go3";
            time.timeZone = "Europe/Warsaw";
            networking.networkmanager.enable = true;
            hardware.microsoft-surface.kernelVersion = "stable"; # surface kernel needs stable
      
            # [TODO] desktop profile forces amdgpu; override for Surface (Intel)
            services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
      
            profiles.base.enable = true;
            profiles.desktop.enable = true;
            profiles.bluetooth.enable = true;
            profiles.core.enable = true;
            profiles.globalpython.enable = true;

            profiles.kdeapps.enable = true;

            profiles.starsector.enable = true;

            # [TODO] lanzaboote  bullhit
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            boot.loader.grub.enable = false;
      
            # Do NOT enable secureboot/lanzaboote on this host for now
            profiles.secureboot.enable = false;
      
            # [TODO] Tailscale. Make it into a module. 
            services.tailscale = {
              enable = true;
              useRoutingFeatures = "client";
            };
      
            services.openssh.enable = true;
      
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { pm = plasma-manager; };
            home-manager.users.deltarnd = import ./home/common.nix;
      
            system.stateVersion = "25.05";
          }
        ];
      };

        nixosConfigurations.USB = lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/USB/hardware-configuration.nix
          ./modules/profiles.nix
          sops-nix.nixosModules.sops # secrets management
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
          sops-nix.nixosModules.sops # secrets management

          home-manager.nixosModules.home-manager {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;
            nix.settings.trusted-users = [ "root" "deltarnd" ]; # for delegated rebuilds

            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            boot.loader.grub.enable = false;

            networking.hostName = "m720";
            time.timeZone = "Europe/Warsaw";
            networking.networkmanager.enable = true;

            profiles.base.enable = true;
            profiles.globalpython.enable = true;
            # profiles.desktop.enable = true;
            profiles.minecraftserver.enable = true;
            profiles.containers.enable = true;
            profiles.gitlabrunner.enable = true;
            profiles.ecg-interface.enable = true;
            profiles.cloudflared.enable = true;

            # Tailscale for remote SSH
            services.tailscale = {
              enable = true;
              useRoutingFeatures = "client";
            };

            # Service to start minecraft server
            systemd.services.minecraft-forge = {
              path = with pkgs; [ bash coreutils jdk21_headless ];
              # (keep the rest of your existing service as-is)
            };

            # Service to start internet connection to minecraft server
            systemd.services.playit = {
              description = "playit.gg tunnel agent";
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                ExecStart = "/opt/playit/playit";
                Restart = "always";
                RestartSec = "5s";

                User = "deltarnd";
                WorkingDirectory = "/home/deltarnd";
              };
            };


            services.openssh.enable = true; # [TODO] configure a proper SSH module
            services.openssh.settings = {
              PasswordAuthentication = true;   # disable later after keys
              };

            # remote desktop

            environment.systemPackages = with pkgs; [
              # xorg.xorgxrdp
            ];

            services.xserver.enable = true;

            services.xserver.desktopManager.xfce.enable = true;
            services.xserver.displayManager.lightdm.enable = true;

            services.desktopManager.plasma6.enable = lib.mkForce false;
            services.displayManager.sddm.enable = lib.mkForce false;
            services.displayManager.sddm.wayland.enable = lib.mkForce false;
            services.xrdp.enable = true;
            networking.firewall.allowedTCPPorts = [ 3389 22 ];
            networking.firewall.allowedUDPPorts = [ 5353 ]; # for avahi

            services.xrdp.defaultWindowManager = "${pkgs.xfce.xfce4-session}/bin/startxfce4";

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
