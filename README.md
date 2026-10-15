# Configs

My CachyOS Hyprland dotfiles for my daily machine. What I like most is how [matugen](https://github.com/InioX/matugen) pulls a palette from my active wallpaper and pushes it into the bar, launcher, terminal, GTK apps and Neovim, so everything matches automatically.

<!-- SCREENSHOT -->

## What's in here

| Folder       | What it configures |
|--------------|--------------------|
| `hypr/`      | [Hyprland](https://hypr.land) (Lua config) and hyprpaper |
| `waybar/`    | Top bar with workspaces and tray |
| `quickshell/`| [Quickshell](https://quickshell.org) widgets: a `panel` (system stats, quick toggles) and an `osd` (volume popup) |
| `kitty/`     | Terminal |
| `wofi/`      | App launcher |
| `nvim/`      | [LazyVim](https://lazyvim.org), with colors fed in by matugen through `mini.base16` |
| `gtk-3.0/`, `gtk-4.0/` | GTK overrides (Breeze-Dark base, matugen colors on top) |
| `matugen/`   | Color templates and where each one gets written |

## How the colors work

`matugen/config.toml` maps each template to its output:

| Template | Writes to |
|----------|-----------|
| `gtk-colors.css`     | `waybar/colors.css`, `wofi/colors.css` |
| `kitty-colors.conf`  | `kitty/colors.conf` |
| `Colors.qml`         | `quickshell/panel/Colors.qml`, `quickshell/osd/Colors.qml` |
| `gtk-adwaita.css`    | `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` |

To redo everything from a new wallpaper:

```sh
matugen image /path/to/wallpaper.jpg
```

## Dependencies

**Core:** `hyprland` (needs a version with Lua config support), `hyprpaper`, `waybar`, `kitty`, `wofi`, `matugen`, `neovim`

**Also used:**
- `quickshell` for the panel and OSD
- `hyprpolkitagent` for auth prompts
- `awww` for the wallpaper daemon
- `cliphist` and `wl-clipboard` for clipboard history
- `flameshot` for screenshots
- `playerctl`, `brightnessctl`, `pavucontrol` for media, brightness and audio
- `thunar` for files
- `nvidia-smi` for GPU stats in the Quickshell panel (optional, shows 0 without it)

**Themes:** Breeze-Dark (GTK), Sweet-cursors, Vivid-Glassy-Dark-Icons, Noto Sans

## Install

Back up your own `~/.config` first. This will overwrite what's there.

```sh
git clone https://github.com/wlygon7/Configs.git ~/Configs
cd ~/Configs

# symlink each folder into ~/.config
for dir in gtk-3.0 gtk-4.0 hypr kitty matugen nvim quickshell waybar wofi; do
  ln -sfn "$PWD/$dir" "$HOME/.config/$dir"
done
```

Then log out/back into Hyprland.

A few files hardcode my home path (`/home/wlygon7/...`), so swap in yours:

```sh
grep -rn '/home/wlygon7' .
```

The main ones are `hypr/hyprland.lua`, `hypr/hyprpaper.conf`, `waybar/style.css`, `wofi/style.css` and `quickshell/panel/shell.qml`.

## Keybinds

`SUPER` is the main modifier (Windows Key for Windows, Command for MacOS).

| Keys | Action |
|------|--------|
| `SUPER + C` | Terminal (kitty) |
| `SUPER + Q` | Close window |
| `SUPER + E` | File manager |
| `SUPER + R` | Wofi launcher |
| `SUPER + V` | Clipboard history |
| `SUPER + W` | Wallpaper picker |
| `SUPER + F` | Fullscreen |
| `SUPER + SHIFT + F` | Toggle floating |
| `SUPER + S` | Scratchpad workspace |
| `SUPER + SHIFT + S` | Screenshot a region |
| `SUPER + SHIFT + R` | Record a region |
| `Home` | Flameshot |
| `SUPER + 1-0` | Switch workspace |
| `SUPER + SHIFT + 1-0` | Move window to workspace |
| `SUPER + arrows` | Move focus |
| `SUPER + SHIFT + arrows` | Swap windows |
| `SUPER + CTRL + ←/→` | Send window to the left/right monitor |
| `SUPER + CTRL + ALT + Q` | Exit Hyprland |

The full list is in `hypr/hyprland.lua`.
## Credits

- Neovim config started from the [LazyVim starter](https://github.com/LazyVim/starter) (Apache 2.0, see `nvim/LICENSE`)
- Kitty themes: [Catppuccin Macchiato](https://github.com/catppuccin/kitty) by Pocco81, [Nordfox](https://github.com/EdenEast/nightfox.nvim) by EdenEast (both MIT)
