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
    }
})
