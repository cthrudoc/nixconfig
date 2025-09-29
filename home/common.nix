{ config, pkgs, ... }:

{
  home.username = "deltarnd";
  home.homeDirectory = "/home/deltarnd";

  home.packages = with pkgs; [
  ];

  programs.direnv.enable = true;
  programs.bash.enable =true;

  # HM bookkeeping
  home.stateVersion = "25.05";
}
