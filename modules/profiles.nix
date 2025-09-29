{ config, pkgs, lib, ...}:
let
  cfg = config.profiles;
in
{
  options.profiles = {
    core.enable = lib.mkEnableOption "Core baseline";
    gaming.enable = lib.mkEnableOption "Gaming";
    nvidia.enable = lib.mkEnableOption "Nvidia";
  };

  config = lib.mkMerge [

    # Core :
    (lib.mkIf cfg.core.enable {
      # Universal user declaration

      security.sudo.enable = true; # Wheel can sudo
      users.mutableUsers = false; # only declared users

      users.users.deltarnd = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
        hashedPassword = "$6$AV.V.aqHeffVIoIV$8td7wVIPxnXzV6XPhXLyGMBSWqQHYSNPQ2DOlkhAQrca3e7sr2MN1IjvMtAiROBN97W9U2i2oDyWfNvkU7JOT.";
      };
      programs.git.enable = true;
      programs.firefox.enable = true;
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
        modesetting.enable = true;
        nvidiaSettings = true;

        };
      }
    )


  ];
}
