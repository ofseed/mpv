local function set_vf()
  local scale = math.max(
    1,
    math.min(
      (mp.get_property "osd-width" or 0)
        / (mp.get_property "width" or math.huge),
      (mp.get_property "osd-height" or 0)
        / (mp.get_property "height" or math.huge)
    )
  )
  mp.command_native_async {
    name = "vf",
    operation = "set",
    value = string.format(
      "@nvidia-super-resolution:d3d11vpp=scale=%f:scaling-mode=nvidia",
      scale
    ),
    _flags = { "no-osd" },
  }
end

mp.register_event("file-loaded", set_vf)

-- For debouncing
local timer = nil
local function on_osd_size_change()
  if timer then
    timer:kill()
  end
  timer = mp.add_timeout(1, set_vf)
end

mp.observe_property("osd-width", "native", on_osd_size_change)
mp.observe_property("osd-height", "native", on_osd_size_change)
