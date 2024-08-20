local options = {
  enabled = false,
}

mp.options = require "mp.options"
mp.options.read_options(options, "nvidia-super-resolution")

local function set_vf()
  if not options.enabled then
    return
  end
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

mp.add_key_binding("n", "toggle-nvidia-super-resolution", function()
  if options.enabled then
    mp.command_native_async {
      name = "vf",
      operation = "remove",
      value = "@nvidia-super-resolution",
      _flags = { "no-osd" },
    }
  end
  options.enabled = not options.enabled
  set_vf()
end)
