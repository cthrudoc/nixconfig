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
    minecraft.enable = lib.mkEnableOption "minecraft";
    minecraftserver.enable = lib.mkEnableOption "minecraftserver";
    containers.enable = lib.mkEnableOption "Podman + /etc/containers config (policy/registries) + OCI systemd backend";
    gitlabrunner.enable = lib.mkEnableOption "gitlab runner, for now set up for running the EKG app, using podman, shell executor on host (gitlab is atm on Pi [TODO])";
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
      services.xserver.videoDrivers = [ "amdgpu" ];

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
        vlc # [TODO] move from here
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

    # Starsector & minecraft temporarily
    (lib.mkIf cfg.starsector.enable {
      environment.systemPackages = with pkgs; [
        unstable.starsector
        prismlauncher
      ];
    })

    # server for minecraft
    (lib.mkIf cfg.minecraftserver.enable {

      # Java for MC 1.20.1 (Forge uses Java 17)
      environment.systemPackages = with pkgs; [
        jdk21_headless
        curl
        wget
        tmux
        unzip
        rsync
      ];

      # Dedicated service user
      users.users.minecraft = {
        isSystemUser = true;
        group = "minecraft";
        home = "/srv/minecraft";
        createHome = true;
      };
      users.groups.minecraft = {};

      # Create directories with correct permissions
      systemd.tmpfiles.rules = [
        "d /srv/minecraft 0750 minecraft minecraft - -"
        "d /srv/minecraft/mods 0750 minecraft minecraft - -"
        "d /srv/minecraft/world 0750 minecraft minecraft - -"
        "d /srv/minecraft/logs 0750 minecraft minecraft - -"
        "d /srv/minecraft/config 0750 minecraft minecraft - -"
        # You will create /srv/minecraft/run.sh yourself (see below)
      ];

      # Firewall: open LAN port (set to false later if you only use a tunnel)
      networking.firewall.allowedTCPPorts = [ 25565 ];

      # Systemd service (expects a run.sh you control)
      systemd.services.minecraft-forge = {
        description = "Minecraft Forge Server";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

	path = with pkgs; [ bash coreutils jdk21_headless ];

        serviceConfig = {
          Type = "simple";
          User = "minecraft";
          Group = "minecraft";
          WorkingDirectory = "/srv/minecraft";
          Restart = "on-failure";
          RestartSec = "5s";
	  ExecStart = lib.mkForce "/srv/minecraft/run.sh";

          # Hardening
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/srv/minecraft" ];
        };

        # control of the server launch script; it can call Java with chosen args
        script = ''
          set -euo pipefail
          if [ ! -x /srv/minecraft/run.sh ]; then
            echo "Missing /srv/minecraft/run.sh (executable)."
            echo "Create it to launch Forge 1.20.1, then: systemctl restart minecraft-forge"
            exit 1
          fi
          exec /srv/minecraft/run.sh
        '';
      };
    })

    # containers
    (lib.mkIf cfg.containers.enable {

      # Generate /etc/containers/* (policy.json, registries.conf, storage.conf, …)
      virtualisation.containers = {
        enable = true;

        # image search
        registries.search = [ "docker.io" "quay.io" "registry.dltrnd.com" ];

        # Strict by default, allow unsigned pulls only from specific registries
        policy = {
          default = [{ type = "reject"; }];
          transports = {
            docker = {
              "docker.io" = [{ type = "insecureAcceptAnything"; }];
              "quay.io" = [{ type = "insecureAcceptAnything"; }];
              "registry.gitlab.com" = [{ type = "insecureAcceptAnything"; }];
            };
          };
        };
      };

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      # run services via systemd
      virtualisation.oci-containers.backend = "podman";

      # some tooling
      environment.systemPackages = with pkgs; [
        skopeo
        podman-compose
        conmon
        crun
        slirp4netns
        netavark
        aardvark-dns
        fuse-overlayfs
        iptables
        iproute2
      ];
    })


    # gitlab runner
    (lib.mkIf cfg.gitlabrunner.enable {

      # GitLab Runner service
      services.gitlab-runner = {
        enable = true;
        concurrent = 1;

        services.ecg-shell = {
          executor = "shell";

          # IMPORTANT: absolute string path so it is NOT copied into /nix/store.
          # [TODO] This file will be created by sops-nix in the next step.
          # [TODO] It must contain:
          #   CI_SERVER_URL=https://git.dltrnd.com
          #   CI_SERVER_TOKEN=glrt-...
          authenticationTokenConfigFile = "/run/secrets/gitlab-runner-ecg-shell-token-env";

          # Must match tags set in GitLab runner UI AND tags used in .gitlab-ci.yml jobs.
          tagList = [ "shell" "x86_64" "ecg" ];
        };
      };

      # Shell executor runs directly on host.
      # Makes sure required tools exist system-wide (including git).
      environment.systemPackages = with pkgs; [
        git
        podman
        skopeo
        bash
        coreutils
        findutils
        gnugrep
        gnused
        gawk
        which
        shadow
        python312
      ];

      # Ensures gitlab-runner service sees these tools in PATH (avoid “git not found” in CI).
      systemd.services.gitlab-runner.path = with pkgs; [
        git podman skopeo bash coreutils findutils gnugrep gnused gawk which shadow
      ];

      # Rootless podman prerequisites
      security.unprivilegedUsernsClone = true;
      systemd.services.gitlab-runner.serviceConfig.NoNewPrivileges = lib.mkForce false;
      systemd.services.gitlab-runner.serviceConfig.RestrictSUIDSGID  = lib.mkForce false;

      # GitLab Runner must be a *stable* system user for rootless podman (subuid/subgid)
      systemd.services.gitlab-runner.serviceConfig.DynamicUser = lib.mkForce false;
      systemd.services.gitlab-runner.serviceConfig.User = lib.mkForce "gitlab-runner";
      systemd.services.gitlab-runner.serviceConfig.Group = lib.mkForce "gitlab-runner";


      # Basic reliability / control
      systemd.services.gitlab-runner.serviceConfig = {
        Restart = "always";
        RestartSec = "5s";
        MemoryMax = "4G";
        CPUQuota = "200%";
      };

      ## User setup :
      # Ensure the gitlab-runner user is fully defined (required by NixOS assertions)
      users.groups.gitlab-runner = {};

      users.users.gitlab-runner = {
        isSystemUser = true;
        group = "gitlab-runner";

        # allow rootless podman
        extraGroups = lib.mkAfter [ "podman" ];

        # rootless mappings
        subUidRanges = [{ startUid = 210000; count = 65536; }];
        subGidRanges = [{ startGid = 210000; count = 65536; }];

        # optional but good hygiene
        home = "/var/lib/gitlab-runner";
        createHome = true;
      };

      ## sops-nix config
      # sops-nix: materialize the runner token env file at runtime (tmpfs), not in /nix/store
      sops = {
        age.keyFile = "/var/lib/sops-nix/key.txt";
        defaultSopsFile = ../secrets/secrets.yaml;

        secrets."gitlab-runner-ecg-shell-token-env" = {
          owner = "gitlab-runner";
          group = "gitlab-runner";
          mode = "0400";
          path = "/run/secrets/gitlab-runner-ecg-shell-token-env";
        };
      };



    })


  ];
}
