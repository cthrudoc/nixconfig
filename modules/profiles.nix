{ config, pkgs, lib, ...}:
let
  cfg = config.profiles;
in
{
  options.profiles = {
    core.enable = lib.mkEnableOption "Core baseline";
    gaming.enable = lib.mkEnableOption "Gaming";
    nvidia.enable = lib.mkEnableOption "Nvidia";
    kdeapps.enable = lib.mkEnableOption "KdeApps";
    globalpython.enable = lib.mkEnableOption "GlobalPython";
    secureboot.enable = lib.mkEnableOption "SecureBoot";
  };

  config = lib.mkMerge [

    # Core :
    (lib.mkIf cfg.core.enable {
      # Universal user declaration

      environment.systemPackages = with pkgs; [
        obsidian
        syncthing
        libreoffice-qt
        realvnc-vnc-viewer
        anki-bin
        vscode
      ];
      # in common.nix : VS Code,
      # anki-bin : nixized config at this date [[10.10.2025]] is not supported, per NixOS wiki.

      services.syncthing = {
        enable = true;
        user = "deltarnd";
        dataDir = "/home/deltarnd";                # where folders live by default
        configDir = "/home/deltarnd/.config/syncthing";
        openDefaultPorts = true;
      };

      security.sudo.enable = true; # Wheel can sudo
      users.mutableUsers = false; # only declared users
      # Defining user :
      users.users.deltarnd = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
        hashedPassword = "$6$AV.V.aqHeffVIoIV$8td7wVIPxnXzV6XPhXLyGMBSWqQHYSNPQ2DOlkhAQrca3e7sr2MN1IjvMtAiROBN97W9U2i2oDyWfNvkU7JOT.";
      };

      programs.git.enable = true;
      programs.firefox.enable = true;
      programs.ssh.startAgent = true;
      # Universal hardware settings
      ## Bluetooth
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      services.blueman.enable = true;  # Bluetooth manager
    }
    )

    # Gaming - Steam , 32-bit , Vulkan
    (lib.mkIf cfg.gaming.enable {
      # Steam
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        };
      # Vulkan and 32 bit
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        };
      programs.gamemode.enable = true; #gamemode idk [TODO] Research what this shit does
      }
    )

    # NVIDIA fuck you
    (lib.mkIf cfg.nvidia.enable {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        open = true;
        modesetting.enable = true;
        nvidiaSettings = true;
        };
      }
    )

    # KDE apps
    (lib.mkIf cfg.kdeapps.enable {
      environment.systemPackages = with pkgs; [
        krita
        ];
      }
    )

    # Global Python
    (lib.mkIf cfg.globalpython.enable {
      environment.systemPackages = with pkgs; [
        python312
      ];
    }
    )

    # Securebooot using lanzaboote
    (lib.mkIf cfg.secureboot.enable {
      boot.bootspec.enable = true;

      # lanzaboote replaces systemd-boot's module
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
        # explicit path to the systemd EFI stub
      };
    }
    )
  ];
}
