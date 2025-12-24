{
  pkgs,
  pkgs-unstable,
  ...
}: {
#  nixpkgs.config = {
#    programs.npm.npmrc = ''
#      prefix = ''${HOME}/.npm-global
#    '';
#  };

  home.packages = with pkgs; (
    # -*- Data & Configuration Languages -*-#
    [
      #-- nix
      nil
      # rnix-lsp
      # nixd
      statix # Lints and suggestions for the nix programming language
      deadnix # Find and remove unused code in .nix source files
      alejandra # Nix Code Formatter

      #-- json like
      # terraform  # install via brew on macOS
      terraform-ls
      jsonnet
      jsonnet-language-server
      taplo # TOML language server / formatter / validator
      nodePackages.yaml-language-server
      actionlint # GitHub Actions linter

      #-- markdown
      marksman # language server for markdown
      glow # markdown previewer
      pandoc # document converter
      pkgs-unstable.hugo # static site generator
    ]
    ++
    #-*- General Purpose Languages -*-#
    [
      #-- c/c++
      cmake
      cmake-language-server
      gnumake
      checkmake
      # c/c++ compiler, required by nvim-treesitter!
      gcc
      gdb
      # c/c++ tools with clang-tools, the unwrapped version won't
      # add alias like `cc` and `c++`, so that it won't conflict with gcc
      # llvmPackages.clang-unwrapped
      clang-tools
      lldb
      vscode-extensions.vadimcn.vscode-lldb.adapter # codelldb - debugger

      #-- python
      pyright # python language server
      (python313.withPackages (
        ps:
          with ps; [
            ruff
            black # python formatter
            # debugpy

            # my commonly used python packages
            pandas
            requests
            pyquery
            pyyaml
          ]
      ))

      #-- rust
      # we'd better use the rust-overlays for rust development
      cargo
      rustc

      #-- lua
      stylua
      lua-language-server

      #-- bash
      nodePackages.bash-language-server
      shellcheck
      shfmt
    ]
    #-*- Web Development -*-#
    ++ [
      nodePackages.nodejs
      nodePackages.typescript
      nodePackages.typescript-language-server
      # HTML/CSS/JSON/ESLint language servers extracted from vscode
      nodePackages.vscode-langservers-extracted
      nodePackages."@tailwindcss/language-server"
      emmet-ls
    ]
    ++ [
      #-- Optional Requirements:
      nodePackages.prettier # common code formatter
      fzf
      (ripgrep.override {withPCRE2 = true;}) # recursively searches directories for a regex pattern
    ]
  );
}
