local hl = hl or {}
local hyde = hyde or {}
hyde.binds = hyde.binds or {}
hyde.binds.dedup_fields = {} -- Tell the deduplicator to ignore flags (like 'locked') when matching overrides

require("key_binds")
require("window_rules")

local move_window = function(dir, pix)
	local lut = { l = { -1, 0 }, r = { 1, 0 }, u = { 0, -1 }, d = { 0, 1 } }
	lut.left, lut.right, lut.up, lut.down = lut.l, lut.r, lut.u, lut.d
	local m = lut[dir]
	return function()
		local args = hl.get_active_window().floating and { x = m[1] * pix, y = m[2] * pix, relative = true }
			or { direction = dir }
		hl.dispatch(hl.dsp.window.move(args))
	end
end

local toggle_fullscreen = function(state_type)
	return function()
		local active_window = hl.get_active_window()
		if not active_window then
			return
		end
		local current_state = tonumber(active_window.fullscreen) or 0
		local next_state = current_state == state_type and 0 or state_type
		hl.dispatch(hl.dsp.window.fullscreen_state({
			internal = next_state,
			client = next_state,
			window = active_window,
		}))
	end
end

hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.25 })
hl.monitor({ output = "", mode = "highres", position = "auto-up", scale = 1 })

hl.config({
	input = {
		kb_layout = "ro",
		sensitivity = 0,
		accel_profile = "adaptive",
		touchpad = {
			natural_scroll = true,
			disable_while_typing = false,
		},
	},
	misc = {
		enable_swallow = false,
		swallow_regex = "^(foot|kitty|allacritty|Alacritty|ghostty|Ghostty|org.wezfurlong.wezterm)$",
	},
	ecosystem = {
		no_update_news = true,
	},
})

require("animations.optimized")
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "linear", style = "loop" })
local MOD = "SUPER"
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.bind(MOD .. " + W", hl.dsp.window.close())
hl.bind(MOD .. " + " .. "SHIFT" .. " + W", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(MOD .. " + " .. "ALT" .. " + W", hl.dsp.exec_cmd(hyde.sh.menu.wallpapers()))
hl.bind(MOD .. " + " .. "SHIFT" .. " + A", hl.dsp.exec_cmd("hyde-shell rofiselect"))
hl.bind("ALT" .. " + F4", hl.dsp.window.close())
hl.bind(MOD .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(MOD .. " + F", toggle_fullscreen(1))
hl.bind(MOD .. " + " .. "SHIFT" .. " + F", toggle_fullscreen(2))
hl.bind(MOD .. " + " .. "SHIFT" .. " + Q", hl.dsp.exec_cmd("hyde-shell logoutlaunch"))
hl.bind("CTRL" .. " + " .. "ALT" .. " + W", hl.dsp.exec_cmd("hyde-shell waybar --hide"))
hl.bind(MOD .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(MOD .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(MOD .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(MOD .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind("ALT" .. " + Tab", hl.dsp.exec_cmd('bash -c "hyprctl dispatch cyclenext"'))
hl.bind(
	MOD .. " + " .. "ALT" .. " + H",
	hl.dsp.window.resize({ x = -30, y = 0, relative = true }),
	{ repeating = true }
)
hl.bind(MOD .. " + " .. "ALT" .. " + J", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })
hl.bind(
	MOD .. " + " .. "ALT" .. " + K",
	hl.dsp.window.resize({ x = 0, y = -30, relative = true }),
	{ repeating = true }
)
hl.bind(MOD .. " + " .. "ALT" .. " + L", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind(MOD .. " + " .. "SHIFT" .. " + H", move_window("l", 30), { repeating = true })
hl.bind(MOD .. " + " .. "SHIFT" .. " + L", move_window("r", 30), { repeating = true })
hl.bind(MOD .. " + " .. "SHIFT" .. " + K", move_window("u", 30), { repeating = true })
hl.bind(MOD .. " + " .. "SHIFT" .. " + J", move_window("d", 30), { repeating = true })
hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(MOD .. " + Z", hl.dsp.window.drag(), { mouse = true })
hl.bind(MOD .. " + X", hl.dsp.window.resize(), { mouse = true })
hl.bind(MOD .. " + Return", hl.dsp.exec_cmd("kitty --single-instance"))
hl.bind(MOD .. " + " .. "ALT" .. " + Return", hl.dsp.exec_cmd("hyde-shell pypr toggle console"))
hl.bind(MOD .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(MOD .. " + N", hl.dsp.exec_cmd("kitty --single-instance nvim ."))
hl.bind(MOD .. " + B", hl.dsp.exec_cmd("zen-browser"))
hl.bind("CTRL" .. " + " .. "ALT" .. " + Delete", hl.dsp.exec_cmd("hyde-shell system.monitor"))
hl.bind(
	MOD .. " + Space",
	hl.dsp.exec_cmd("bash -c \"pkill -x rofi || hyde-shell rofilaunch d -theme-str 'window {location: southeast;}'\"")
)
hl.bind(MOD .. " + P", hl.dsp.exec_cmd('bash -c "hyde-shell screenshot s # partial screenshot capture"'))
hl.bind(
	MOD .. " + " .. "CTRL" .. " + P",
	hl.dsp.exec_cmd('bash -c "hyde-shell screenshot sf # partial screenshot capture (frozen screen)"')
)
hl.bind(
	MOD .. " + " .. "ALT" .. " + P",
	hl.dsp.exec_cmd('bash -c "hyde-shell screenshot m # monitor screenshot capture"')
)
hl.bind("" .. " + Print", hl.dsp.exec_cmd('bash -c "hyde-shell screenshot p # all monitors screenshot capture"'))

hl.bind(MOD .. " + " .. "CTRL" .. " + L", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(MOD .. " + " .. "CTRL" .. " + H", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(MOD .. " + " .. "CTRL" .. " + J", hl.dsp.focus({ workspace = "empty" }))
hl.bind(MOD .. " + " .. "CTRL" .. " + " .. "ALT" .. " + L", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(MOD .. " + " .. "CTRL" .. " + " .. "ALT" .. " + H", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(MOD .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(MOD .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(MOD .. " + " .. "SHIFT" .. " + S", hl.dsp.window.move({ workspace = "special" }))
hl.bind(MOD .. " + " .. "ALT" .. " + S", hl.dsp.window.move({ workspace = "special", silent = true }))
hl.bind(MOD .. " + S", hl.dsp.workspace.toggle_special("special"))
