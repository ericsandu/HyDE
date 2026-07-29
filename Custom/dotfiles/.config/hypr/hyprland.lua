print("HYPRLAND.LUA EXECUTED")
require("window_rules")

local move_window = function(dir, pix)
    local lut = {l = {-1, 0}, r = {1, 0}, u = {0, -1}, d = {0, 1}}
    lut.left, lut.right, lut.up, lut.down = lut.l, lut.r, lut.u, lut.d
    local m = lut[dir]
    return function()
        local args = hl.get_active_window().floating and {x = m[1] * pix, y = m[2] * pix, relative = true} or {direction = dir}
        hl.dispatch(hl.dsp.window.move(args))
    end
end

local toggle_fullscreen = function(state_type)
    return function()
        local active_window = hl.get_active_window()
        if not active_window then return end
        local current_state = tonumber(active_window.fullscreen) or 0
        local next_state = current_state == state_type and 0 or state_type
        hl.dispatch(
            hl.dsp.window.fullscreen_state({
                internal = next_state,
                client = next_state,
                window = active_window
            })
        )
    end
end

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
    },
})

hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "linear", style = "loop" })
local MOD = "SUPER"
hl.bind(MOD .. " + W", hl.dsp.window.close())
hl.bind(MOD .. " + " .. "SHIFT" .. " + W", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind("ALT" .. " + F4", hl.dsp.window.close())
hl.bind(MOD .. " + T", hl.dsp.window.float({action = "toggle"}))
hl.bind(MOD .. " + G", hl.dsp.group.toggle())
hl.bind(MOD .. " + F", toggle_fullscreen(1))
hl.bind(MOD .. " + " .. "SHIFT" .. " + F", toggle_fullscreen(2))
hl.bind(MOD .. " + " .. "SHIFT" .. " + Q", hl.dsp.exec_cmd("hyde-shell logoutlaunch"))
hl.bind("CTRL" .. " + " .. "ALT" .. " + W", hl.dsp.exec_cmd("hyde-shell waybar --hide"))
hl.bind(MOD .. " + H", hl.dsp.focus({direction = "l"}))
hl.bind(MOD .. " + J", hl.dsp.focus({direction = "d"}))
hl.bind(MOD .. " + K", hl.dsp.focus({direction = "u"}))
hl.bind(MOD .. " + L", hl.dsp.focus({direction = "r"}))
hl.bind("ALT" .. " + Tab", hl.dsp.exec_cmd("bash -c \"hyprctl dispatch cyclenext\""))
hl.bind(MOD .. " + " .. "ALT" .. " + H", hl.dsp.window.resize({x = -30, y = 0, relative = true}), {repeating = true})
hl.bind(MOD .. " + " .. "ALT" .. " + J", hl.dsp.window.resize({x = 0, y = 30, relative = true}), {repeating = true})
hl.bind(MOD .. " + " .. "ALT" .. " + K", hl.dsp.window.resize({x = 0, y = -30, relative = true}), {repeating = true})
hl.bind(MOD .. " + " .. "ALT" .. " + L", hl.dsp.window.resize({x = 30, y = 0, relative = true}), {repeating = true})
hl.bind(MOD .. " + " .. "SHIFT" .. " + H", move_window("l", 30), {repeating = true})
hl.bind(MOD .. " + " .. "SHIFT" .. " + L", move_window("r", 30), {repeating = true})
hl.bind(MOD .. " + " .. "SHIFT" .. " + K", move_window("u", 30), {repeating = true})
hl.bind(MOD .. " + " .. "SHIFT" .. " + J", move_window("d", 30), {repeating = true})
hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), {mouse = true})
hl.bind(MOD .. " + Z", hl.dsp.window.drag(), {mouse = true})
hl.bind(MOD .. " + X", hl.dsp.window.resize(), {mouse = true})
hl.bind(MOD .. " + Return", hl.dsp.exec_cmd("kitty --single-instance"))
hl.bind(MOD .. " + " .. "ALT" .. " + Return", hl.dsp.exec_cmd("hyde-shell pypr toggle console"))
hl.bind(MOD .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(MOD .. " + N", hl.dsp.exec_cmd("kitty --single-instance nvim ."))
hl.bind(MOD .. " + B", hl.dsp.exec_cmd("zen-browser"))
hl.bind("CTRL" .. " + " .. "ALT" .. " + Delete", hl.dsp.exec_cmd("hyde-shell system.monitor"))
hl.bind(MOD .. " + Space", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell rofilaunch d -theme-str 'window {location: southeast;}'\""))
hl.bind(MOD .. " + TAB", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell rofilaunch w\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + E", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell rofilaunch f\""))
hl.bind(MOD .. " + slash", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell keybinds_hint c # launch keybinds hint\""))
hl.bind(MOD .. " + comma", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell emoji-picker # launch emoji picker\""))
hl.bind(MOD .. " + period", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell glyph-picker # launch glyph picker\""))
hl.bind(MOD .. " + V", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell cliphist -c # launch clipboard,\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + V", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell cliphist # launch clipboard Manager\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + A", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell rofiselect # launch select menu\""))
hl.bind("" .. " + XF86AudioMute", hl.dsp.exec_cmd("bash -c \"hyde-shell volumecontrol -o m # toggle audio mute\""))
hl.bind("" .. " + XF86AudioMicMute", hl.dsp.exec_cmd("bash -c \"hyde-shell volumecontrol -i m # toggle microphone mute\""))
hl.bind("" .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("bash -c \"hyde-shell volumecontrol -o d # decrease volume\""), {repeating = true})
hl.bind("" .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("bash -c \"hyde-shell volumecontrol -o i # increase volume\""), {repeating = true})
hl.bind("" .. " + XF86AudioPlay", hl.dsp.exec_cmd("bash -c \"playerctl play-pause # toggle between media play and pause\""))
hl.bind("" .. " + XF86AudioPause", hl.dsp.exec_cmd("bash -c \"playerctl play-pause # toggle between media play and pause\""))
hl.bind("" .. " + XF86AudioNext", hl.dsp.exec_cmd("bash -c \"playerctl next # media next\""))
hl.bind("" .. " + XF86AudioPrev", hl.dsp.exec_cmd("bash -c \"playerctl previous # media previous\""))
hl.bind("" .. " + XF86MonBrightnessUp", hl.dsp.exec_cmd("bash -c \"hyde-shell brightnesscontrol i # increase brightness\""), {repeating = true})
hl.bind("" .. " + XF86MonBrightnessDown", hl.dsp.exec_cmd("bash -c \"hyde-shell brightnesscontrol d # decrease brightness\""), {repeating = true})
hl.bind("CTRL" .. " + " .. "ALT" .. " + K", hl.dsp.exec_cmd("bash -c \"hyde-shell keyboardswitch # switch keyboard layout\""))
hl.bind(MOD .. " + " .. "ALT" .. " + G", hl.dsp.exec_cmd("bash -c \"hyde-shell gamemode # disable hypr effects for gamemode\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + G", hl.dsp.exec_cmd("bash -c \"hyde-shell gamelauncher # run game launcher for steam and lutris\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + P", hl.dsp.exec_cmd("bash -c \"hyprpicker -an # Pick color (Hex) >> clipboard#\""))
hl.bind(MOD .. " + P", hl.dsp.exec_cmd("bash -c \"hyde-shell screenshot s # partial screenshot capture\""))
hl.bind(MOD .. " + " .. "CTRL" .. " + P", hl.dsp.exec_cmd("bash -c \"hyde-shell screenshot sf # partial screenshot capture (frozen screen)\""))
hl.bind(MOD .. " + " .. "ALT" .. " + P", hl.dsp.exec_cmd("bash -c \"hyde-shell screenshot m # monitor screenshot capture\""))
hl.bind("" .. " + Print", hl.dsp.exec_cmd("bash -c \"hyde-shell screenshot p # all monitors screenshot capture\""))
hl.bind(MOD .. " + " .. "ALT" .. " + W", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell wallpaper -SG # launch wallpaper select menu\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + R", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell wallbashtoggle -m # launch wallbash mode select menu\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + T", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell themeselect # launch theme select menu\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + Y", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell animations --select # launch animations select menu\""))
hl.bind(MOD .. " + " .. "SHIFT" .. " + U", hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell hyprlock --select # launch hyprlock layout select menu\""))
hl.bind(MOD .. " + 1", hl.dsp.focus({workspace = 1}))
hl.bind(MOD .. " + 2", hl.dsp.focus({workspace = 2}))
hl.bind(MOD .. " + 3", hl.dsp.focus({workspace = 3}))
hl.bind(MOD .. " + 4", hl.dsp.focus({workspace = 4}))
hl.bind(MOD .. " + 5", hl.dsp.focus({workspace = 5}))
hl.bind(MOD .. " + 6", hl.dsp.focus({workspace = 6}))
hl.bind(MOD .. " + 7", hl.dsp.focus({workspace = 7}))
hl.bind(MOD .. " + 8", hl.dsp.focus({workspace = 8}))
hl.bind(MOD .. " + 9", hl.dsp.focus({workspace = 9}))
hl.bind(MOD .. " + 0", hl.dsp.focus({workspace = 10}))
hl.bind(MOD .. " + " .. "CTRL" .. " + L", hl.dsp.focus({workspace = "r+1"}))
hl.bind(MOD .. " + " .. "CTRL" .. " + H", hl.dsp.focus({workspace = "r-1"}))
hl.bind(MOD .. " + " .. "CTRL" .. " + J", hl.dsp.focus({workspace = "empty"}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 1", hl.dsp.window.move({workspace = 1}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 2", hl.dsp.window.move({workspace = 2}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 3", hl.dsp.window.move({workspace = 3}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 4", hl.dsp.window.move({workspace = 4}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 5", hl.dsp.window.move({workspace = 5}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 6", hl.dsp.window.move({workspace = 6}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 7", hl.dsp.window.move({workspace = 7}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 8", hl.dsp.window.move({workspace = 8}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 9", hl.dsp.window.move({workspace = 9}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + 0", hl.dsp.window.move({workspace = 10}))
hl.bind(MOD .. " + " .. "CTRL" .. " + " .. "ALT" .. " + L", hl.dsp.window.move({workspace = "r+1"}))
hl.bind(MOD .. " + " .. "CTRL" .. " + " .. "ALT" .. " + H", hl.dsp.window.move({workspace = "r-1"}))
hl.bind(MOD .. " + mouse_down", hl.dsp.focus({workspace = "e+1"}))
hl.bind(MOD .. " + mouse_up", hl.dsp.focus({workspace = "e-1"}))
hl.bind(MOD .. " + " .. "SHIFT" .. " + S", hl.dsp.window.move({workspace = "special"}))
hl.bind(MOD .. " + " .. "ALT" .. " + S", hl.dsp.window.move({workspace = "special", silent = true}))
hl.bind(MOD .. " + S", hl.dsp.focus({workspace = "special", action = "toggle"}))
hl.bind(MOD .. " + " .. "ALT" .. " + 1", hl.dsp.window.move({workspace = 1, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 2", hl.dsp.window.move({workspace = 2, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 3", hl.dsp.window.move({workspace = 3, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 4", hl.dsp.window.move({workspace = 4, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 5", hl.dsp.window.move({workspace = 5, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 6", hl.dsp.window.move({workspace = 6, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 7", hl.dsp.window.move({workspace = 7, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 8", hl.dsp.window.move({workspace = 8, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 9", hl.dsp.window.move({workspace = 9, silent = true}))
hl.bind(MOD .. " + " .. "ALT" .. " + 0", hl.dsp.window.move({workspace = 10, silent = true}))
