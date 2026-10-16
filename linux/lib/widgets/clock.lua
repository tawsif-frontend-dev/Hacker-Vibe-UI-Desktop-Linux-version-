-- Clock: big time, date, rotating motto / greeting / year-progress line, thin year bar.
local hv = require 'hv'

local M = { W = 380, H = 140, interval = 1 }

local function is_leap(y) return (y % 4 == 0 and y % 100 ~= 0) or y % 400 == 0 end

local function greeting(hour)
  if hour >= 5 and hour <= 11 then return 'GOOD MORNING'
  elseif hour >= 12 and hour <= 16 then return 'GOOD AFTERNOON'
  elseif hour >= 17 and hour <= 20 then return 'GOOD EVENING' end
  return 'GOOD NIGHT'
end

function M.draw(cr)
  local t = hv.theme()
  local S = hv.settings()
  local now = os.time()
  local d = os.date('*t', now)
  local is24 = S.CLOCK24 == '1'

  local hm = os.date(is24 and '%H:%M' or '%I:%M', now)
  local cx = M.W / 2
  local tw = hv.text(cr, hm, cx, 58, 58, t.accent, { font = hv.F_DISPLAY, bold = true, align = 'center' })

  -- seconds (and AM/PM) tucked to the right of the time
  local sx = cx + tw / 2 + 8
  hv.text(cr, os.date('%S', now), sx, 58, 15, t.dim, { bold = true })
  if not is24 then hv.text(cr, os.date('%p', now), sx, 38, 11, t.dim) end

  hv.text(cr, os.date('%A, %d %B %Y', now), cx, 86, 13, t.textlight, { align = 'center' })

  -- bottom line rotates every 10 s: motto -> greeting -> year progress
  local phase = math.floor(now / 10) % 3
  local line
  if phase == 0 then
    line = S.MOTTO
  elseif phase == 1 then
    line = greeting(d.hour) .. ', ' .. S.USER_NAME:upper()
  else
    local days = is_leap(d.year) and 366 or 365
    line = string.format('YEAR %d%% DONE  /  WEEK %s', math.floor(d.yday / days * 100), os.date('%V', now))
  end
  hv.text(cr, line, cx, 108, 10, t.dim, { align = 'center', spacing = 2 })

  local days = is_leap(d.year) and 366 or 365
  hv.bar(cr, cx - 100, 121, 200, 3, d.yday / days * 100, t.accent, t.barbg)
end

return M
