-- Shortcuts: circular panel listing your launchers (SHORTCUT1..8_LABEL in settings.conf).
-- Conky windows can't receive clicks, so launch them with `hackervibe open <n|name>` or
-- `hackervibe launcher` (menu) and bind that to a key in your desktop settings.
local hv = require 'hv'

local M = { W = 340, H = 340, interval = 1 }

local function entries()
  local S = hv.settings()
  local list = {}
  for i = 1, 8 do
    local label = S['SHORTCUT' .. i .. '_LABEL']
    if label and label ~= '' then list[#list + 1] = label end
  end
  return list
end

function M.draw(cr)
  local t = hv.theme()
  local now = os.time()
  local cx, cy, r = M.W / 2, M.H / 2, 160

  -- ring + orbiting second marker
  hv.circle(cr, cx, cy, r, t.accent, 1.6, 0.9)
  hv.circle(cr, cx, cy, r - 7, t.faint, 1, 0.5)
  local a = (tonumber(os.date('%S', now)) or 0) / 60 * 2 * math.pi - math.pi / 2
  hv.dot(cr, cx + math.cos(a) * r, cy + math.sin(a) * r, 3.4, t.hover)

  hv.text(cr, 'SHORTCUTS', cx, cy - 98, 11, t.textlight, { bold = true, align = 'center', spacing = 2 })

  local list = entries()
  local n = #list
  local pitch = 26
  local y = cy - 98 + 36 + (6 - math.min(n, 6)) * pitch / 2
  for _, label in ipairs(list) do
    hv.text(cr, '> ' .. label, cx - 62, y, 14, t.accent)
    y = y + pitch
  end
end

return M
