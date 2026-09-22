-- Helper ala Omarchy (default/hypr/helpers.lua), dipangkas: tanpa uwsm/webapp/omarchy-launch.
o = o or {}

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end
o.shell_quote = shell_quote

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

function o.cmd_present(command)
  if command:find("/", 1, true) then return file_exists(command) end
  local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
  for dir in (path .. ":"):gmatch("([^:]*):") do
    if file_exists((dir ~= "" and dir or ".") .. "/" .. command) then return true end
  end
  return false
end

-- o.bind("SUPER + X", "Deskripsi", "perintah shell" | hl.dsp.* | function, { locked=true, ... })
function o.bind(keys, description, dispatcher, options)
  local opts = options or {}
  if description then opts.description = description end
  if type(dispatcher) == "string" then dispatcher = hl.dsp.exec_cmd(dispatcher) end
  return hl.bind(keys, dispatcher, opts)
end

function o.rebind(keys, description, dispatcher, options)
  hl.unbind(keys)
  return o.bind(keys, description, dispatcher, options)
end

function o.exec_on_start(command)
  hl.on("hyprland.start", function() hl.exec_cmd(command) end)
end

-- o.window("class-regex" | { class=..., title=..., tag=... }, { rules })
function o.window(match, rules)
  rules.match = rules.match or {}
  if type(match) == "string" then
    rules.match.class = match
  else
    for k, v in pairs(match) do rules.match[k] = v end
  end
  hl.window_rule(rules)
end
