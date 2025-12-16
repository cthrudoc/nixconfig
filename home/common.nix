{ config, pkgs, lib, osConfig, pm, ... }:

{
  imports = [
    pm.homeModules.plasma-manager
  ];

  home.username = "deltarnd";
  home.homeDirectory = "/home/deltarnd";

  programs.direnv.enable = true;
  programs.bash.enable =true;
  programs.direnv.nix-direnv.enable = true;

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
    mutableExtensionsDir = false;   # manual installs won't persist if set to true(?)

    profiles.default = {
      enableUpdateCheck = false;
      extensions =
        (with pkgs.vscode-extensions; [
            # Python / Jupyter
          ms-python.python
          ms-python.vscode-pylance
          ms-toolsai.jupyter
          # vscodevim.vim          # Vim bindings
          esbenp.prettier-vscode # Formatting for HTML/CSS/JS/JSON, etc.
        ])
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          # {
            # publisher = "vintharas";
            # name = "learn-vim";
            # version = "0.0.28";
            # sha256 = "sha256-HAEKetNHUZ1HopGeQTqkrGUWZNFWD7gMaoTNbpxqI1Y=";
          # }
          # {
            # publisher = "enkia";
            # name = "tokyo-night";
            # version = "1.1.2";
            # sha256 = "sha256-oW0bkLKimpcjzxTb/yjShagjyVTUFEg198oPbY5J2hM=";
          # }
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
          {
            publisher = "slhsxcmy";
            name = "vscode-double-line-numbers";
            version = "0.1.4";
            sha256 = "sha256-07Iiq8s6+8o7LfpcTCvwAyleBMnjEiRzV9BASoAig4A=";
          }
          {
            publisher = "openai";
            name = "chatgpt";
            version = "0.4.51";
            sha256 = "sha256-aYjiHTffYxH1+59xklp29oNh/qv5vVs3VS5yZYj2M4c=";
          }
        ];

      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "update.mode" = "none";
        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = false;

        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;

        # Python niceties
        "python.terminal.activateEnvironment" = true;
        "python.analysis.typeCheckingMode" = "basic";
        "python.testing.pytestEnabled" = true;

        #"workbench.colorTheme" = "Tokyo Night";

        "editor.cursorBlinking" = "phase";
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.lineNumbers" = "on";

        "window.titleBarStyle" = "native";
      };

      keybindings = [
        # Unbind MRU switcher defaults
        { key = "ctrl+tab";         command = "-workbench.action.quickOpenPreviousRecentlyUsedEditorInGroup"; }
        { key = "ctrl+shift+tab";   command = "-workbench.action.quickOpenLeastRecentlyUsedEditorInGroup"; }

        # Bind by-tab-order switching in the current group
        { key = "ctrl+tab";         command = "workbench.action.nextEditorInGroup"; }
        { key = "ctrl+shift+tab";   command = "workbench.action.previousEditorInGroup"; }
      ];
    };
  };

  home.packages = [
    (pkgs.writeShellScriptBin "plasma-theme-light" ''
      #!/usr/bin/env bash
      set -euo pipefail
      plasma-apply-colorscheme BreezeLight
      plasma-apply-colorscheme --accent-color "#AA7300"
      plasma-apply-wallpaperimage "/home/deltarnd/Pictures/wallpapers/light.png"
    '')

    (pkgs.writeShellScriptBin "plasma-theme-dark" ''
      #!/usr/bin/env bash
      set -euo pipefail
      plasma-apply-colorscheme BreezeDark
      plasma-apply-colorscheme --accent-color "#AA7300"
      plasma-apply-wallpaperimage "/home/deltarnd/Pictures/wallpapers/night.png"
    '')
  ];

  programs.plasma = {
    enable = true;

    hotkeys.commands."switch-to-light" = {
      name = "Switch to light theme";
      key = "Meta+Ctrl+L";
      command = "plasma-theme-light";
    };

    hotkeys.commands."switch-to-dark" = {
      name = "Switch to dark theme";
      key = "Meta+Ctrl+K";
      command = "plasma-theme-dark";
    };
  };

  # HM bookkeeping
  home.stateVersion = "25.05";
}
