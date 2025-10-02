{ config, pkgs, ... }:

{
  home.username = "deltarnd";
  home.homeDirectory = "/home/deltarnd";

  programs.direnv.enable = true;
  programs.bash.enable =true;
  
  # SSH
  programs.ssh = {
    enable = true;

    # Github setup
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519";
    };
  };

  # Git setup for NixOS config
  programs.git = {
    enable = true;
    userName  = "cthrudoc";
    userEmail = "seethroughdoctor@gmail.com"; # or your real email

    extraConfig.init.defaultBranch = "main";
    };

  # Making Vault directory exist so Obsidian things don't break
  home.file."Vault/.keep".text = "";

  # HM bookkeeping
  home.stateVersion = "25.05";
}
