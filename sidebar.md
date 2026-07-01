# Sidebar

To build and install dwm with the sidebar:

make clean
make -j$(nproc)
sudo make install

## Usage

- Ensure the toggle script is installed and executable:

  mkdir -p "$HOME/bin"
  install -Dm755 scripts/toggle_md_sidebar.sh "$HOME/bin/toggle_md_sidebar.sh"

- Dependencies: st (terminal), and either xdotool (recommended) or wmctrl for positioning.

- Toggle the sidebar with the hotkey: Super + h
  - This runs: $HOME/bin/toggle_md_sidebar.sh
  - If the sidebar is not present, the script spawns a floating st window with WM_CLASS `md_sidebar` at the right edge (20% width, min 200px).
  - If the sidebar is present, the script will close it.

- Manual invocation:

  $HOME/bin/toggle_md_sidebar.sh

- Notes:
  - The sidebar is overlay-style (floating and always-on-top) and will cover windows beneath it.
  - The window matching rule is in `config/window-rules.toml`:

    { class="md_sidebar", isfloating=1, alwaysontop=1 }

  - Hotkeys are configured in `config/hotkeys.toml` (Super+h).

