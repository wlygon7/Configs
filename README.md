# Configs

My Hyprland desktop dotfiles. The wallpaper sets the colors: [matugen](https://github.com/InioX/matugen) generates a palette from it and writes it into the bar, launcher, terminal, GTK apps and Neovim, so everything matches.

<!-- Add a screenshot here: ![desktop](screenshots/desktop.png) -->

## What's in here

| Folder       | What it configures |
|--------------|--------------------|
| `hypr/`      | [Hyprland](https://hypr.land) (Lua config), hyprpaper, and the Odyssey shell integration |
| `waybar/`    | Top bar: workspaces + tray |
| `quickshell/`| [Quickshell](https://quickshell.org) widgets: a `panel` (system stats, quick toggles) and an `osd` (volume popup) |
| `kitty/`     | Terminal |
| `wofi/`      | App launcher |
| `nvim/`      | [LazyVim](https://lazyvim.org) setup, colors driven by matugen through `mini.base16` |
| `gtk-3.0/`, `gtk-4.0/` | GTK theme overrides (Breeze-Dark base, matugen colors on top) |
| `matugen/`   | The color templates and where each one gets written |

## How the colors work

`matugen/config.toml` maps each template to its output:

| Template | Writes to |
|----------|-----------|
| `gtk-colors.css`     | `waybar/colors.css`, `wofi/colors.css` |
| `kitty-colors.conf`  | `kitty/colors.conf` |
| `Colors.qml`         | `quickshell/panel/Colors.qml`, `quickshell/osd/Colors.qml` |
| `gtk-adwaita.css`    | `gtk-3.0/gtk.css`, `gtk-4.0/gtk.css` |

To regenerate everything from a new wallpaper:

```sh
matugen image /path/to/wallpaper.jpg
```

Generated files are committed, so the setup still looks right before you run matugen.

## Dependencies

**Core:** `hyprland` (a version with Lua config support), `hyprpaper`, `waybar`, `kitty`, `wofi`, `matugen`, `neovim`

**Used by the config:**
- `quickshell` — panel and OSD
- `hyprpolkitagent` — auth prompts
- `awww` — wallpaper daemon
- `cliphist`, `wl-clipboard` — clipboard history
- `flameshot` — screenshots
- `playerctl`, `brightnessctl`, `pavucontrol` — media, brightness, audio
- `thunar` — file manager
- `nvidia-smi` — GPU stats in the Quickshell panel (optional; shows 0 without it)
- Odyssey — launcher, notifications, control center, lock screen (see `hypr/odyssey.lua`)

**Themes:** Breeze-Dark (GTK), Sweet-cursors, Vivid-Glassy-Dark-Icons, Noto Sans

## Install

> Back up your own `~/.config` first. These files will overwrite what's there.

```sh
git clone https://github.com/wlygon7/Configs.git ~/Configs
cd ~/Configs

# Symlink each folder into ~/.config
for dir in gtk-3.0 gtk-4.0 hypr kitty matugen nvim quickshell waybar wofi; do
  ln -sfn "$PWD/$dir" "$HOME/.config/$dir"
done
```

Then log into Hyprland.

**Heads up:** a few files have my home path (`/home/wlygon7/...`) hard-coded. Search and swap in your own before using them:

```sh
grep -rn '/home/wlygon7' .
```

Mainly `hypr/hyprland.lua`, `hypr/odyssey.lua`, `hypr/hyprpaper.conf`, `waybar/style.css`, `wofi/style.css` and `quickshell/panel/shell.qml`.

## Keybinds

`SUPER` is the main modifier.

| Keys | Action |
|------|--------|
| `SUPER + C` | Terminal (kitty) |
| `SUPER + Q` | Close window |
| `SUPER + E` | File manager |
| `SUPER + R` | Wofi launcher |
| `SUPER + A` | Odyssey launcher |
| `SUPER + Space` | Control center |
| `SUPER + V` | Clipboard history |
| `SUPER + N` | Notifications |
| `SUPER + W` | Wallpaper picker |
| `SUPER + F` | Fullscreen |
| `SUPER + SHIFT + F` | Toggle floating |
| `SUPER + S` | Scratchpad workspace |
| `SUPER + L` | Lock |
| `SUPER + SHIFT + S` | Screenshot a region |
| `SUPER + SHIFT + R` | Record a region |
| `Home` | Flameshot |
| `SUPER + 1–0` | Switch workspace |
| `SUPER + SHIFT + 1–0` | Move window to workspace |
| `SUPER + arrows` | Move focus |
| `SUPER + SHIFT + arrows` | Swap windows |
| `SUPER + CTRL + ←/→` | Move window to the left/right monitor |
| `SUPER + CTRL + ALT + Q` | Exit Hyprland |

The full list is in `hypr/hyprland.lua` and `hypr/odyssey.lua`.

## Credits

- Neovim config started from the [LazyVim starter](https://github.com/LazyVim/starter) (Apache 2.0, see `nvim/LICENSE`)
- Kitty themes: [Catppuccin Macchiato](https://github.com/catppuccin/kitty) by Pocco81, [Nordfox](https://github.com/EdenEast/nightfox.nvim) by EdenEast (both MIT)
