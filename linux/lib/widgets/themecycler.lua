-- ThemeCycler: tiny status line. The actual cycling is done by `hackervibe` (a background timer)
-- which rotates Green -> Blue -> Red -> Purple and swaps the wallpaper to match.
local hv = require 'hv'

local M = { W = 288, H = 20, interval = 5 }

function M.draw(cr)
  local t, name = hv.theme()
  local next_at = tonumber(hv.trim(hv.read_file(hv.dir.config .. '/state/next_switch') or ''))
  local tail
  if next_at then
    local mins = math.max(0, math.ceil((next_at - os.time()) / 60))
    tail = 'NEXT IN ' .. mins .. ' MIN'
  else
    tail = 'AUTO-CYCLE OFF'
  end
  hv.text(cr, 'THEME: ' .. name .. '  //  ' .. tail, M.W, 14, 9, t.dim, { align = 'right', spacing = 1 })
end

return M
