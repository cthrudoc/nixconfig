{ config, pkgs, lib, unstable ? pkgs, ...}:
let
  cfg = config.profiles;
in
{
  options.profiles = {
    base.enable = lib.mkEnableOption "Default User, GC, minimal packaging";
    desktop.enable = lib.mkEnableOption "GUI + audio";
    bluetooth.enable = lib.mkEnableOption "Bluetooth" ;
    syncthing.enable = lib.mkEnableOption "Syncthing" ;
    VNC.enable = lib.mkEnableOption "NVC";
    core.enable = lib.mkEnableOption "Core applications";
    gaming.enable = lib.mkEnableOption "Gaming";
    nvidia.enable = lib.mkEnableOption "Nvidia";
    kdeapps.enable = lib.mkEnableOption "KdeApps";
    globalpython.enable = lib.mkEnableOption "GlobalPython";
    secureboot.enable = lib.mkEnableOption "SecureBoot";
    ocr.enable = lib.mkEnableOption "OCR";
    netsec.enable = lib.mkEnableOption "netsec";
    starsector.enable = lib.mkEnableOption "starsector";
  };

  config = lib.mkMerge [

    # BASE of every system
    (lib.mkIf cfg.base.enable {

      # GC "keep 5 generations"
      systemd.services.nix-keep-5-gens = {
        description = "Keep only last 5 NixOS system generations";
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          set -euo pipefail

          # Keep only the 5 newest generations of the system profile
          /run/current-system/sw/bin/nix-env \
            --profile /nix/var/nix/profiles/system \
            --delete-generations +5 || true

          # Collect garbage for anything no longer referenced
          /run/current-system/sw/bin/nix-collect-garbage
        '';
      };

      systemd.timers.nix-keep-5-gens = {
        description = "Run nix-keep-5-gens daily";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
      nix.settings.auto-optimise-store = true;


      # Universal User definition
      security.sudo.enable = true; # Wheel can sudo
      users.mutableUsers = false; # only declared users
      # Defining user :
      users.users.deltarnd = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
        hashedPassword = "$6$AV.V.aqHeffVIoIV$8td7wVIPxnXzV6XPhXLyGMBSWqQHYSNPQ2DOlkhAQrca3e7sr2MN1IjvMtAiROBN97W9U2i2oDyWfNvkU7JOT.";
      };

      # basic firewall
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
      };

      # Essential packages
      environment.systemPackages = with pkgs; [
        git
      ];
      programs.ssh.startAgent = true;
    })

    # Desktop (GUI + audio)
    (lib.mkIf cfg.desktop.enable {
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
      programs.firefox.enable = true; # at least one browser
    })

    # Bluetooth
    (lib.mkIf cfg.bluetooth.enable {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      services.blueman.enable = true;  # Bluetooth manager
    })

    # Syncthing :
    (lib.mkIf cfg.syncthing.enable {
      services.syncthing = {
        enable = true;
        user = "deltarnd";
        dataDir = "/home/deltarnd";                # where folders live by default
        configDir = "/home/deltarnd/.config/syncthing";
        openDefaultPorts = true;
      };
    })

    # VNC: true extended desktop over LAN (X11 only)
    (lib.mkIf cfg.VNC.enable {
      environment.systemPackages = with pkgs; [
        x11vnc
        tigervnc
      ];

      networking.firewall.allowedTCPPorts = [ 5900 ];

      systemd.services.virtual-second-monitor = {
        description = "Export secondary X11 monitor over VNC (x11vnc clipped to xinerama1)";
        wants = [ "display-manager.service" ];
        after = [ "display-manager.service" ];

        unitConfig = {
          ConditionPathExists = "/tmp/.X11-unix/X0";
        };

        serviceConfig = {
          Type = "simple";
          User = "deltarnd";
          Environment = "DISPLAY=:0";
          ExecStart =
            "${pkgs.x11vnc}/bin/x11vnc "
            + "-display :0 "
            + "-xrandr -clip xinerama1 "
            + "-forever -shared -noxdamage "
            + "-rfbport 5900 "
            + "-nopw";
          Restart = "on-failure";
        };
      };
    })

    # Core apps
    (lib.mkIf cfg.core.enable {
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
    })

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
        open = false;
        modesetting.enable = true;
        nvidiaSettings = true;
        powerManagement.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.production;
        };
      }
    )

    # KDE apps
    (lib.mkIf cfg.kdeapps.enable {
      environment.systemPackages = with pkgs; [
        krita
        # KDE/Plasma apps (Qt6):
        kdePackages.kdeconnect-kde
        kdePackages.filelight
        kdePackages.partitionmanager
        kdePackages.kfind
        kdePackages.kcolorchooser
        kdePackages.kmag
        ];

        # needs to be enabled for kdeconnect to work
        programs.kdeconnect.enable = true;
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        # manual opening of the ports for KDE Connect.
        networking.firewall.allowedTCPPorts = [ 1714 1715 1716 1717 1718 1719 ];
        networking.firewall.allowedUDPPorts = [ 1714 1715 1716 1717 1718 1719 ];


      }
    )

    # Global Python
    (lib.mkIf cfg.globalpython.enable {
      environment.systemPackages = with pkgs; [
        python312
        stdenv.cc.cc
      ];
      # tryig to make numpy work [TODO]
      programs.nix-ld.enable = true;
      programs.nix-ld.libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        glibc
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

    # OCR
    (lib.mkIf cfg.ocr.enable {
      environment.systemPackages = with pkgs; [
        ocrmypdf
        tesseract
      ];
      environment.etc."tessdata/pol.traineddata".source = pkgs.tesseract.languages.pol;
      environment.etc."tessdata/eng.traineddata".source = pkgs.tesseract.languages.eng;
      environment.variables.TESSDATA_PREFIX = "/etc";
    })

    # Netsec : VPN
    (lib.mkIf cfg.netsec.enable {
      environment.systemPackages = with pkgs; [
        mullvad-vpn
      ];
      services.mullvad-vpn = {
        enable = true;
        package = pkgs.mullvad-vpn;
      };
      services.dbus.enable = true;
    })

    # Starsector
    (lib.mkIf cfg.starsector.enable {
      environment.systemPackages = with pkgs; [
        unstable.starsector
      ];
    })
  ];
}
