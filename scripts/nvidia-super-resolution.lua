local options = {
  enabled = false,
}

mp.options = require "mp.options"
mp.options.read_options(options, "nvidia-super-resolution")

---@param msg? boolean Whether to show an OSD message
local function set_vf(msg)
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
    _flags = { msg and "osd-msg" or "no-osd" },
  }
end

---@param _ table Unused
local function on_file_loaded(_)
  set_vf()
end

mp.register_event("file-loaded", on_file_loaded)

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
      _flags = { "osd-msg" },
    }
  end
  options.enabled = not options.enabled
  set_vf(true)
end)
