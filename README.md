# Homies

My dotfiles, managed with [chezmoi](https://www.chezmoi.io).

## What's in here

- Shell config (zsh, starship, atuin, direnv, zoxide)
- Neovim (NvChad-based)
- Tmux + TPM (pulled via chezmoiexternal)
- Git config + helpers
- Terminal emulator configs (ghostty, kitty)
- Hyprland/Wayland configs (Linux only, currently dormant)
- Brewfile and flatpak bootstrap scripts
- Topgrade config

## Multi-machine setup

Configs are templated for multiple machines — personal macOS, work macOS, Linux. On first init, chezmoi will prompt for machine role and work email if applicable.

## Quick start

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/lazypower/homies.git
```

Re-run `chezmoi init` to update machine-specific settings.

## Notes

These are my configs. Fork freely, but they're shaped for my workflow.
