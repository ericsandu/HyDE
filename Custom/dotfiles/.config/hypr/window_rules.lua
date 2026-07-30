local opacities = {
  {"0.90", "0.90", "^(firefox)$"},
  {"0.90", "0.90", "^(zen)$"},
  {"0.90", "0.90", "^(brave-browser)$"},
  {"0.80", "0.80", "^(code-oss)$"},
  {"0.80", "0.80", "^([Cc]ode)$"},
  {"0.80", "0.80", "^(code-url-handler)$"},
  {"0.80", "0.80", "^(code-insiders-url-handler)$"},
  {"0.80", "0.80", "^(kitty)$"},
  {"0.80", "0.80", "^(org.kde.dolphin)$"},
  {"0.80", "0.80", "^(org.kde.ark)$"},
  {"0.80", "0.80", "^(nwg-look)$"},
  {"0.80", "0.80", "^(qt5ct)$"},
  {"0.80", "0.80", "^(qt6ct)$"},
  {"0.80", "0.80", "^(kvantummanager)$"},
  {"0.80", "0.70", "^(org.pulseaudio.pavucontrol)$"},
  {"0.80", "0.70", "^(blueman-manager)$"},
  {"0.80", "0.70", "^(nm-applet)$"},
  {"0.80", "0.70", "^(nm-connection-editor)$"},
  {"0.80", "0.70", "^(hyprpolkitagent)$"},
  {"0.80", "0.70", "^(org.freedesktop.impl.portal.desktop.gtk)$"},
  {"0.80", "0.70", "^(org.freedesktop.impl.portal.desktop.hyprland)$"},
  {"0.70", "0.70", "^([Ss]team)$"},
  {"0.70", "0.70", "^(steamwebhelper)$"},
  {"0.70", "0.70", "^([Ss]potify)$"},
  {"1.00", "1.00", "^(blender)$"},
  {"0.90", "0.90", "^(com.github.rafostar.Clapper)$"},
  {"0.90", "0.90", "^(zathura)$"},
  {"0.80", "0.80", "^(com.github.tchx84.Flatseal)$"},
  {"0.80", "0.80", "^(hu.kramo.Cartridges)$"},
  {"0.80", "0.80", "^(com.obsproject.Studio)$"},
  {"0.80", "0.80", "^(gnome-boxes)$"},
  {"0.90", "0.90", "^(vesktop)$"},
  {"0.80", "0.80", "^(discord)$"},
  {"0.80", "0.80", "^(WebCord)$"},
  {"0.80", "0.80", "^(ArmCord)$"},
  {"0.80", "0.80", "^(app.drey.Warp)$"},
  {"0.80", "0.80", "^(net.davidotek.pupgui2)$"},
  {"0.80", "0.80", "^(yad)$"},
  {"0.80", "0.80", "^(Signal)$"},
  {"0.80", "0.80", "^(io.github.alainm23.planify)$"},
  {"0.80", "0.80", "^(io.gitlab.theevilskeleton.Upscaler)$"},
  {"0.80", "0.80", "^(com.github.unrud.VideoDownloader)$"},
  {"0.80", "0.80", "^(io.gitlab.adhami3310.Impression)$"},
  {"0.80", "0.80", "^(io.missioncenter.MissionCenter)$"},
  {"0.80", "0.80", "^(io.github.flattool.Warehouse)$"}
}

for _, rule in ipairs(opacities) do
  hl.window_rule({
    opacity = string.format("%s %s %s", rule[1], rule[2], "1.0"),
    match = {
      class = rule[3]
    }
  })
end

-- Float rules
local floats = {
  "^(Signal)$", "^(com.github.rafostar.Clapper)$", "^(app.drey.Warp)$",
  "^(net.davidotek.pupgui2)$", "^(yad)$", "^(eog)$",
  "^(io.github.alainm23.planify)$", "^(io.gitlab.theevilskeleton.Upscaler)$",
  "^(com.github.unrud.VideoDownloader)$", "^(io.gitlab.adhami3310.Impression)$",
  "^(io.missioncenter.MissionCenter)$"
}
hl.window_rule({
  float = true,
  match = { class = table.concat(floats, "|") }
})

hl.window_rule({
  float = true,
  match = { title = table.concat({"^(Friends List)$", "^(Steam Settings)$"}, "|") }
})

-- Blender
hl.window_rule({
  float = true,
  size = "(monitor_w*0.5) (monitor_h*0.5)",
  match = { initial_title = "^(Image Editor)$", class = "^(blender)$" }
})

-- JetBrains Dropdown Flickering Fix
hl.window_rule({
  no_initial_focus = true,
  match = { class = "^(.*jetbrains.*)$", title = "^(win[0-9]+)$" }
})

-- Layer rules for blurring
local blur_layers = {
  "rofi", "notifications", "swaync-notification-window",
  "swaync-control-center", "logout_dialog"
}
for _, layer in ipairs(blur_layers) do
  hl.layer_rule({ blur = true, match = { namespace = layer } })
  hl.layer_rule({ ignore_alpha = true, match = { namespace = layer } })
end

-- Rofi Opacity
hl.window_rule({
  opacity = { 0.9, 0.9 },
  match = { class = "^([Rr]ofi)$" }
})
hl.config({
  layerrule = {
    "opacity 0.9, rofi"
  }
})
