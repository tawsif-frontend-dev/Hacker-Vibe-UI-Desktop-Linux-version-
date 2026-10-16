-- Calendar: month grid with today highlighted + countdown to a user-defined yearly event.
local hv = require 'hv'

local M = { W = 288, H = 246, interval = 10 }

local DAYS_SUN = { 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' }

local function days_in_month(y, m)
  return os.date('*t', os.time({ year = y, month = m + 1, day = 0, hour = 12 })).day
end

local function days_until(now, d, S)
  local em, ed = tonumber(S.EVENT_MONTH) or 1, tonumber(S.EVENT_DAY) or 1
  local today = os.time({ year = d.year, month = d.month, day = d.day, hour = 12 })
  local target = os.time({ year = d.year, month = em, day = ed, hour = 12 })
  if target < today then target = os.time({ year = d.year + 1, month = em, day = ed, hour = 12 }) end
  return math.floor((target - today) / 86400 + 0.5)
end

function M.draw(cr)
  local t = hv.theme()
  local S = hv.settings()
  local now = os.time()
  local d = os.date('*t', now)
  local ws = (tonumber(S.WEEK_START) or 0) % 7

  hv.card(cr, M.W, M.H, t)

  hv.text(cr, os.date('%B %Y', now):upper(), 16, 28, 14, t.accent, { font = hv.F_DISPLAY, bold = true })
  hv.text(cr, os.date('%A %d', now):upper(), 16, 44, 9, t.dim, { spacing = 1 })

  -- weekday header
  local cw, x0 = 36, 18
  for i = 0, 6 do
    local name = DAYS_SUN[((i + ws) % 7) + 1]
    hv.text(cr, name, x0 + i * cw + cw / 2, 68, 9, t.dim, { align = 'center' })
  end

  -- 6x7 grid, previous / next month days dimmed
  local first = os.date('*t', os.time({ year = d.year, month = d.month, day = 1, hour = 12 }))
  local offset = ((first.wday - 1) - ws) % 7
  local dim_cur = days_in_month(d.year, d.month)
  local pm = d.month == 1 and 12 or d.month - 1
  local py = d.month == 1 and d.year - 1 or d.year
  local dim_prev = days_in_month(py, pm)

  for cell = 0, 41 do
    local row, col = math.floor(cell / 7), cell % 7
    local n = cell - offset + 1
    local label, inmonth = nil, true
    if n < 1 then label, inmonth = dim_prev + n, false
    elseif n > dim_cur then label, inmonth = n - dim_cur, false
    else label = n end

    local cx = x0 + col * cw + cw / 2
    local cy = 90 + row * 20
    if inmonth and n == d.day then
      hv.rrect(cr, cx - 14, cy - 12, 28, 17, 4)
      hv.rgba(cr, t.accent, 0.92)
      cairo_fill(cr)
      hv.text(cr, label, cx, cy, 11, { 0, 0, 0, 255 }, { align = 'center', bold = true })
    else
      local color = inmonth and t.textlight or t.faint
      hv.text(cr, label, cx, cy, 11, color, { align = 'center' })
    end
  end

  -- countdown
  local left = days_until(now, d, S)
  local msg
  if left == 0 then msg = 'TODAY!' elseif left == 1 then msg = 'Tomorrow' else msg = left .. ' Days until' end
  hv.text(cr, msg, 16, M.H - 30, 10, t.textlight)
  hv.text(cr, '> ' .. S.EVENT_NAME, 16, M.H - 14, 11, t.accent, { bold = true })
end

return M
