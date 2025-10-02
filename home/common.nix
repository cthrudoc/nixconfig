{ config, pkgs, ... }:

{
  home.username = "deltarnd";
  home.homeDirectory = "/home/deltarnd";

  programs.direnv.enable = true;
  programs.bash.enable =true;
  

  programs.ssh = {
    enable = true;

    # Github setup
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519";
    };
  };

  programs.git = {
    enable = true;
    userName  = "cthrudoc";
    userEmail = "seethroughdoctor@gmail.com"; # or your real email

    extraConfig.init.defaultBranch = "main";
    };

  # HM bookkeeping
  home.stateVersion = "25.05";
}
