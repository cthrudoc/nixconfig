{ config, pkgs, lib, osConfig, ... }:

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

  # VS Code
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # Reproducibility knobs
    mutableExtensionsDir = false;   # manual installs won't persist (set true to trial)

    profiles.default = {
      enableUpdateCheck = false;
      extensions =
        (with pkgs.vscode-extensions; [
          # Python / Jupyter
          ms-python.python
          ms-python.vscode-pylance
          ms-toolsai.jupyter
          # Vim bindings
          vscodevim.vim
          # Formatting for HTML/CSS/JS/JSON, etc.
          esbenp.prettier-vscode
        ])
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
          publisher = "vintharas";
          name = "learn-vim";
          version = "0.0.28";
          sha256 = "sha256-HAEKetNHUZ1HopGeQTqkrGUWZNFWD7gMaoTNbpxqI1Y=";
          }
          {
          publisher = "enkia";
          name = "tokyo-night";
          version = "1.1.2";
          sha256 = "sha256-oW0bkLKimpcjzxTb/yjShagjyVTUFEg198oPbY5J2hM=";
          }
          {
          publisher = "samuelcolvin";
          name = "jinjahtml";
          version = "0.20.0";
          sha256 = "sha256-wADL3AkLfT2N9io8h6XYgceKyltJCz5ZHZhB14ipqpM=";
          }
          {
          publisher = "jnoortheen";
          name = "nix-ide";
          version = "0.5.0";
          sha256 = "sha256-jVuGQzMspbMojYq+af5fmuiaS3l3moG8L8Kyf40vots=";
          }
        ];

      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none";
        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = false;

        "editor.formatOnSave" = true;
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;

        # Python niceties
        "python.terminal.activateEnvironment" = true;
        "python.analysis.typeCheckingMode" = "basic";
        "python.testing.pytestEnabled" = true;

        "workbench.colorTheme" = "Tokyo Night";
      };
    };
  };


  # HM bookkeeping
  home.stateVersion = "25.05";
}
