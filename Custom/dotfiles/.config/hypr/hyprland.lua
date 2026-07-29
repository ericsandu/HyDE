require("window_rules")

hl.config({
    input = {
        kb_layout = "ro",
        sensitivity = 0,
        accel_profile = "adaptive",
        touchpad = {
            natural_scroll = true,
            disable_while_typing = false,
        }
    },
    misc = {
        enable_swallow = false,
        swallow_regex = "^(foot|kitty|allacritty|Alacritty|ghostty|Ghostty|org.wezfurlong.wezterm)$",
    },
    ecosystem = {
        no_update_news = true,
})

local MOD = "SUPER"

-- App overrides
hyde.config.app.terminal = "kitty --single-instance"
hyde.config.app.editor = "kitty --single-instance nvim ."
hyde.config.app.explorer = "thunar"
hyde.config.app.browser = "zen-browser"

-- Window Management Overrides
hl.bind(MOD .. " + W", hl.dsp.exec_cmd("hyde-shell dontkillsteam"))
hl.bind(MOD .. " + SHIFT + W", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind("ALT + F4", hl.dsp.exec_cmd("hyde-shell dontkillsteam"))
hl.bind(MOD .. " + T", hl.dsp.window.float({action = "toggle"}))
hl.bind(MOD .. " + F", hl.dsp.window.fullscreen_state({ internal = 1, client = 1 }))
hl.bind(MOD .. " + SHIFT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
hl.bind(MOD .. " + SHIFT + Q", hl.dsp.exec_cmd("hyde-shell logoutlaunch"))
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd("hyde-shell waybar --hide"))

-- Vim-like Focus
hl.bind(MOD .. " + H", hl.dsp.focus({direction = "l"}))
hl.bind(MOD .. " + J", hl.dsp.focus({direction = "d"}))
hl.bind(MOD .. " + K", hl.dsp.focus({direction = "u"}))
hl.bind(MOD .. " + L", hl.dsp.focus({direction = "r"}))

-- Vim-like Resize
hl.bind(MOD .. " + ALT + H", hl.dsp.window.resize({x = -30, y = 0, relative = true}), {repeating = true})
hl.bind(MOD .. " + ALT + J", hl.dsp.window.resize({x = 0, y = 30, relative = true}), {repeating = true})
hl.bind(MOD .. " + ALT + K", hl.dsp.window.resize({x = 0, y = -30, relative = true}), {repeating = true})
hl.bind(MOD .. " + ALT + L", hl.dsp.window.resize({x = 30, y = 0, relative = true}), {repeating = true})

-- Vim-like Move
hl.bind(MOD .. " + SHIFT + H", hl.dsp.exec_cmd("grep -q 'true' <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive -30 0 || hyprctl dispatch movewindow l"), {repeating = true})
hl.bind(MOD .. " + SHIFT + J", hl.dsp.exec_cmd("grep -q 'true' <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive 0 30 || hyprctl dispatch movewindow d"), {repeating = true})
hl.bind(MOD .. " + SHIFT + K", hl.dsp.exec_cmd("grep -q 'true' <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive 0 -30 || hyprctl dispatch movewindow u"), {repeating = true})
hl.bind(MOD .. " + SHIFT + L", hl.dsp.exec_cmd("grep -q 'true' <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive 30 0 || hyprctl dispatch movewindow r"), {repeating = true})

-- Apps
hl.bind(MOD .. " + N", hl.dsp.exec_cmd(hyde.config.app.editor))
hl.bind(MOD .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -an"))
hl.bind(MOD .. " + S", hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace"))

