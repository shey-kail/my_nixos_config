<h2 align="center">:snowflake: Shey's Nix Config :snowflake:</h2>

> My configuration is becoming more and more complex

This repository is home to the nix code that builds my systems:

1. NixOS Desktops: NixOS with home-manager, KDE Plasma6.
See [./hosts](./hosts) for details of each host.

## Why NixOS & Flakes?

Nix allows for easy-to-manage, collaborative, reproducible deployments. This means that once
something is setup and configured once, it works (almost) forever. If someone else shares their
configuration, anyone else can just use it (if you really understand what you're copying/referring
now).

As for Flakes, refer to
[Introduction to Flakes - NixOS & Nix Flakes Book](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/introduction-to-flakes)

**Want to know NixOS & Flakes in detail? Looking for a beginner-friendly tutorial or best practices?
You don't have to go through the pain I've experienced again! Check out my
[NixOS & Nix Flakes Book - 🛠️ ❤️ An unofficial & opinionated :book: for beginners](https://github.com/ryan4yin/nixos-and-flakes-book)!**

## Neovim

See [./home/base/tui/editors/neovim/](./home/base/tui/editors/neovim/) for details.

```bash
# deploy one of the configuration based on the hostname
sudo nixos-rebuild switch --flake .#wujie
```

> [What y'all will need when Nix drives you to drink.](https://www.youtube.com/watch?v=Eni9PPPPBpg)
> (copy from hlissner's dotfiles, it really matches my feelings when I first started using NixOS...)

## References

Other dotfiles that inspired me:

- Nix Flakes
  - [NixOS-CN/NixOS-CN-telegram](https://github.com/NixOS-CN/NixOS-CN-telegram)
  - [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)
  - [taj-ny/nix-config](https://github.com/taj-ny/nix-config)
