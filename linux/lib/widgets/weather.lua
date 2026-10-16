-- Weather: reads the cache written by libexec/weather.py (Open-Meteo, free, no API key).
local hv = require 'hv'

local M = { W = 300, H = 108, interval = 5 }

local function kind(code)
  code = tonumber(code) or -1
  if code == 0 or code == 1 then return 'sun'
  elseif code == 2 then return 'partly'
  elseif code == 3 then return 'cloud'
  elseif code == 45 or code == 48 then return 'fog'
  elseif (code >= 51 and code <= 67) or (code >= 80 and code <= 82) then return 'rain'
  elseif (code >= 71 and code <= 77) or code == 85 or code == 86 then return 'snow'
  elseif code >= 95 then return 'storm' end
  return 'cloud'
end

local function cloud(cr, t, cx, cy, s, color)
  hv.rgba(cr, color)
  cairo_new_path(cr); cairo_arc(cr, cx - 10 * s, cy + 3 * s, 9 * s, 0, 2 * math.pi); cairo_fill(cr)
  cairo_new_path(cr); cairo_arc(cr, cx + 1 * s,  cy - 4 * s, 12 * s, 0, 2 * math.pi); cairo_fill(cr)
  cairo_new_path(cr); cairo_arc(cr, cx + 13 * s, cy + 3 * s, 8 * s, 0, 2 * math.pi); cairo_fill(cr)
  cairo_rectangle(cr, cx - 10 * s, cy + 3 * s, 23 * s, 9 * s); cairo_fill(cr)
end

local function sun(cr, t, cx, cy, r)
  hv.dot(cr, cx, cy, r, t.warn)
  for i = 0, 7 do
    local a = i * math.pi / 4
    hv.line(cr, cx + math.cos(a) * (r + 4), cy + math.sin(a) * (r + 4),
                cx + math.cos(a) * (r + 9), cy + math.sin(a) * (r + 9), t.warn, 2)
  end
end

local function icon(cr, t, k, cx, cy)
  if k == 'sun' then
    sun(cr, t, cx, cy, 10)
  elseif k == 'partly' then
    sun(cr, t, cx - 8, cy - 8, 8)
    cloud(cr, t, cx + 3, cy + 6, 0.95, t.dim)
  elseif k == 'cloud' then
    cloud(cr, t, cx, cy, 1.15, t.dim)
  elseif k == 'fog' then
    for i = 0, 3 do hv.line(cr, cx - 18 + (i % 2) * 6, cy - 12 + i * 9, cx + 18 - (i % 2) * 6, cy - 12 + i * 9, t.dim, 3) end
  elseif k == 'rain' then
    cloud(cr, t, cx, cy - 8, 1.0, t.dim)
    for i = -1, 1 do hv.line(cr, cx + i * 11 - 2, cy + 8, cx + i * 11 - 6, cy + 18, t.secondary, 2.2) end
  elseif k == 'snow' then
    cloud(cr, t, cx, cy - 8, 1.0, t.dim)
    for i = -1, 1 do hv.dot(cr, cx + i * 11, cy + 14, 2.4, t.textlight) end
  elseif k == 'storm' then
    cloud(cr, t, cx, cy - 8, 1.0, t.faint)
    cairo_new_path(cr)
    cairo_move_to(cr, cx + 2, cy + 3); cairo_line_to(cr, cx - 6, cy + 13)
    cairo_line_to(cr, cx, cy + 13);    cairo_line_to(cr, cx - 4, cy + 22)
    cairo_line_to(cr, cx + 8, cy + 9); cairo_line_to(cr, cx + 2, cy + 9)
    cairo_close_path(cr)
    hv.rgba(cr, t.warn); cairo_fill(cr)
  end
end

function M.draw(cr)
  local t = hv.theme()
  local S = hv.settings()
  hv.card(cr, M.W, M.H, t)

  local w = hv.read_kv(hv.dir.cache .. '/weather.kv')
  if not w.temp then
    hv.text(cr, 'WEATHER', 14, 22, 10, t.accent, { bold = true, spacing = 2 })
    local msg = w.error and ('offline: ' .. w.error:sub(1, 30)) or 'fetching…'
    hv.text(cr, msg, M.W / 2, 62, 11, t.dim, { align = 'center' })
    return
  end

  local unit_t = (S.UNITS == 'imperial') and '°F' or '°C'
  local unit_w = (S.UNITS == 'imperial') and 'mph' or 'km/h'

  icon(cr, t, kind(w.code), 44, 44)
  hv.text(cr, w.temp .. unit_t, 82, 52, 30, t.accent, { font = hv.F_DISPLAY, bold = true })
  hv.text(cr, (w.desc or ''):sub(1, 22), 84, 70, 10, t.textlight)

  local function row(y, label, value)
    hv.text(cr, value, M.W - 14, y, 10, t.textlight, { align = 'right' })
    hv.text(cr, label, M.W - 14 - hv.text_width(cr, value, 10) - 8, y, 9, t.dim, { align = 'right' })
  end
  row(30, 'FEELS', (w.feels or '?') .. unit_t)
  row(46, 'HUMID', (w.humidity or '?') .. '%')
  row(62, 'WIND', (w.wind or '?') .. ' ' .. unit_w)

  hv.line(cr, 12, 82, M.W - 12, 82, t.faint, 1, 0.6)
  hv.text(cr, (w.city or ''):sub(1, 24), 14, 98, 10, t.accent, { bold = true })
  local stale = (os.time() - (tonumber(w.updated) or 0)) > 7200
  hv.text(cr, string.format('H %s° L %s°%s', w.hi or '?', w.lo or '?', stale and '  (stale)' or ''),
          M.W - 14, 98, 9, t.dim, { align = 'right' })
end

return M
