-- HackerVibe for Linux :: core library (settings, themes, cairo helpers, conky window config)
-- Loaded by conky (config phase and draw phase). Cairo functions are globals provided by conky's
-- lua bindings; they are only touched at draw time, never at load time.

local M = {}

local HOME = os.getenv('HOME') or ''
local XDG_CONFIG = os.getenv('XDG_CONFIG_HOME') or (HOME .. '/.config')
local XDG_DATA   = os.getenv('XDG_DATA_HOME')   or (HOME .. '/.local/share')
local XDG_CACHE  = os.getenv('XDG_CACHE_HOME')  or (HOME .. '/.cache')

M.dir = {
  config = os.getenv('HV_CONFIG') or (XDG_CONFIG .. '/hackervibe'),
  data   = os.getenv('HV_DATA')   or (XDG_DATA   .. '/hackervibe'),
  cache  = os.getenv('HV_CACHE')  or (XDG_CACHE  .. '/hackervibe'),
}

M.F_DISPLAY = 'Orbitron'
M.F_MONO    = 'JetBrains Mono'

---------------------------------------------------------------------------------------------------
-- small utilities
---------------------------------------------------------------------------------------------------
function M.read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local s = f:read('*a')
  f:close()
  return s
end

function M.trim(s)
  s = tostring(s):gsub('^%s+', '')
  s = s:gsub('%s+$', '')
  return s
end

function M.read_kv(path)
  local t = {}
  local s = M.read_file(path)
  if not s then return t end
  for line in s:gmatch('[^\r\n]+') do
    if not line:match('^%s*[#;]') then
      local k, v = line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$')
      if k then
        v = v:gsub('^"(.*)"$', '%1')
        v = v:gsub("^'(.*)'$", '%1')
        t[k] = v
      end
    end
  end
  return t
end

function M.popen_line(cmd)
  local p = io.popen(cmd .. ' 2>/dev/null')
  if not p then return nil end
  local l = p:read('*l')
  p:close()
  if l and l ~= '' then return l end
  return nil
end

function M.clamp(v, lo, hi)
  if v < lo then return lo elseif v > hi then return hi end
  return v
end

function M.round(v) return math.floor(v + 0.5) end

function M.fmt_rate(kib)               -- kib = KiB/s
  local b = kib * 1024
  if b < 1024 then return string.format('%.0f B/s', b) end
  if b < 1024 * 1024 then return string.format('%.1f KB/s', b / 1024) end
  return string.format('%.2f MB/s', b / 1048576)
end

function M.fmt_uptime()
  local s = M.read_file('/proc/uptime')
  local secs = s and tonumber(s:match('^(%d+)')) or 0
  local d = math.floor(secs / 86400)
  local h = math.floor((secs % 86400) / 3600)
  local m = math.floor((secs % 3600) / 60)
  return string.format('%dd %02dh %02dm', d, h, m)
end

---------------------------------------------------------------------------------------------------
-- settings  (re-read every 15 s so edits apply without a restart where possible)
---------------------------------------------------------------------------------------------------
local DEFAULTS = {
  USER_NAME = 'Hacker', CLOCK24 = '1', MOTTO = 'FOCUS / PLAN / EXECUTE / SUCCEED',
  EVENT_NAME = 'New Year', EVENT_DAY = '1', EVENT_MONTH = '1', WEEK_START = '0',
  QUOTE_MINUTES = '60', WEATHER_AUTO = '0', LAT = '51.5074', LON = '-0.1278',
  LOCATION_NAME = 'London, UK', UNITS = 'metric', WARN_AT = '60', CRIT_AT = '85',
  PING_HOST = '1.1.1.1', NET_IFACE = 'auto', DISKS = 'auto',
  PORTFOLIO_LABEL = 'GitHub', PORTFOLIO_URL = 'https://github.com',
  THEME_CYCLE_MINUTES = '30', THEME_WALLPAPER = '1',
}
local cache, cache_t = nil, 0
function M.settings()
  local now = os.time()
  if not cache or now - cache_t >= 15 then
    cache_t = now
    cache = M.read_kv(M.dir.config .. '/settings.conf')
    for k, v in pairs(DEFAULTS) do
      if cache[k] == nil or cache[k] == '' then cache[k] = v end
    end
  end
  return cache
end

function M.num(key, default)
  return tonumber(M.settings()[key]) or default
end

---------------------------------------------------------------------------------------------------
-- themes (same palettes as the Windows/Rainmeter edition)
---------------------------------------------------------------------------------------------------
M.THEME_ORDER = { 'Green', 'Blue', 'Red', 'Purple' }
M.THEMES = {
  Green  = { accent={140,255,190,255}, hover={190,255,220,255}, dim={90,200,140,200},  faint={60,140,100,160},
             secondary={90,170,255,255},  bg={0,0,0,150}, barbg={25,45,35,200}, textlight={200,255,220,255},
             warn={255,190,60,255},  crit={255,70,70,255} },
  Blue   = { accent={120,200,255,255}, hover={175,225,255,255}, dim={90,150,200,200},  faint={50,110,150,160},
             secondary={170,140,255,255}, bg={0,0,0,150}, barbg={20,35,50,200}, textlight={190,225,255,255},
             warn={255,190,60,255},  crit={255,70,70,255} },
  Red    = { accent={255,110,110,255}, hover={255,170,170,255}, dim={200,90,90,200},   faint={150,60,60,160},
             secondary={255,190,90,255},  bg={0,0,0,150}, barbg={45,25,25,200}, textlight={255,200,200,255},
             warn={255,220,120,255}, crit={255,255,255,255} },
  Purple = { accent={190,140,255,255}, hover={215,180,255,255}, dim={150,100,200,200}, faint={100,60,150,160},
             secondary={255,140,220,255}, bg={0,0,0,150}, barbg={35,25,50,200}, textlight={225,200,255,255},
             warn={255,190,60,255},  crit={255,70,70,255} },
}

local theme_name, theme_t = 'Green', 0
function M.theme()
  local now = os.time()
  if now - theme_t >= 2 then
    theme_t = now
    local s = M.read_file(M.dir.config .. '/state/theme')
    if s then
      s = M.trim(s)
      if M.THEMES[s] then theme_name = s end
    end
  end
  return M.THEMES[theme_name], theme_name
end

-- colour for a 0..100 value using the user's warn / crit thresholds
function M.level_color(t, pct)
  if pct >= M.num('CRIT_AT', 85) then return t.crit end
  if pct >= M.num('WARN_AT', 60) then return t.warn end
  return t.accent
end

---------------------------------------------------------------------------------------------------
-- layout (design units = a 1366x768 screen; scaled by HV_SCALE at run time)
---------------------------------------------------------------------------------------------------
M.DEFAULT_POS = {
  terminal    = { 'top_left',       16,  16 },
  system      = { 'top_left',       16, 334 },
  clock       = { 'top_middle',      0,  14 },
  shortcuts   = { 'top_middle',      0, 150 },
  quote       = { 'top_right',      16,  16 },
  calendar    = { 'bottom_right',   16,  16 },
  themecycler = { 'bottom_right',   16, 270 },
  weather     = { 'bottom_middle', -117, 16 },
  network     = { 'bottom_middle',  199, 16 },
}

function M.scale()
  local s = tonumber(os.getenv('HV_SCALE') or '')
  if s and s > 0 then return s end
  return 1.25
end

function M.position(name)
  local p = M.settings()['POS_' .. name:upper()]
  if p then
    local a, x, y = p:match('^%s*([%w_]+)%s*,%s*(-?[%d%.]+)%s*,%s*(-?[%d%.]+)%s*$')
    if a then return { a, tonumber(x), tonumber(y) } end
  end
  return M.DEFAULT_POS[name] or { 'top_left', 16, 16 }
end

function M.conky_config(name)
  local widget = require('widgets.' .. name)
  local s = M.scale()
  local pos = M.position(name)
  local S = M.settings()
  local compositor = (S.COMPOSITOR or 'on') ~= 'off'
  local cfg = {
    background = false,
    update_interval = widget.interval or 1,
    double_buffer = true,
    no_buffers = true,
    cpu_avg_samples = 2,
    net_avg_samples = 2,
    out_to_console = false,
    out_to_stderr = false,
    extra_newline = false,
    use_xft = true,
    draw_shades = false, draw_outline = false, draw_borders = false, draw_graph_borders = false,
    border_width = 0, stippled_borders = 0,
    default_color = 'ffffff',
    alignment = pos[1],
    -- conky measures gap_x from the centre in the opposite direction for *_middle alignments;
    -- flip it so that a positive x always means "further right" in settings.conf
    gap_x = M.round(pos[2] * s) * (pos[1]:match('_middle$') and -1 or 1),
    gap_y = M.round(pos[3] * s),
    minimum_width  = math.ceil(widget.W * s),
    minimum_height = math.ceil(widget.H * s),
    maximum_width  = math.ceil(widget.W * s),
    own_window = true,
    own_window_type = S.WINDOW_TYPE or 'desktop',
    own_window_class = 'HackerVibe_' .. name,
    own_window_title = 'HackerVibe ' .. name,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
    own_window_argb_visual = compositor,
    own_window_argb_value = 0,
    own_window_transparent = not compositor,
    lua_load = M.dir.data .. '/lib/main.lua',
    lua_draw_hook_post = 'main',
  }
  local head = tonumber(S.MONITOR or '')
  if head and head > 0 then cfg.xinerama_head = head end
  return cfg
end

---------------------------------------------------------------------------------------------------
-- cairo helpers (all take the cairo context first; coordinates are in design units)
---------------------------------------------------------------------------------------------------
local EXT

function M.rgba(cr, c, mult)
  cairo_set_source_rgba(cr, c[1] / 255, c[2] / 255, c[3] / 255, ((c[4] or 255) / 255) * (mult or 1))
end

function M.rrect(cr, x, y, w, h, r)
  r = math.min(r, w / 2, h / 2)
  local pi = math.pi
  cairo_new_path(cr)
  cairo_arc(cr, x + w - r, y + r,     r, -pi / 2, 0)
  cairo_arc(cr, x + w - r, y + h - r, r, 0,       pi / 2)
  cairo_arc(cr, x + r,     y + h - r, r, pi / 2,  pi)
  cairo_arc(cr, x + r,     y + r,     r, pi,      pi * 1.5)
  cairo_close_path(cr)
end

function M.card(cr, w, h, t)
  M.rrect(cr, 0.75, 0.75, w - 1.5, h - 1.5, 7)
  M.rgba(cr, t.bg)
  cairo_fill_preserve(cr)
  M.rgba(cr, t.accent, 0.55)
  cairo_set_line_width(cr, 1.2)
  cairo_stroke(cr)
end

local function set_font(cr, size, o)
  cairo_select_font_face(cr, o.font or M.F_MONO, CAIRO_FONT_SLANT_NORMAL,
    o.bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
  cairo_set_font_size(cr, size)
end

local function advance(cr, s)
  if not EXT then
    EXT = cairo_text_extents_t:create()
    tolua.takeownership(EXT)
  end
  cairo_text_extents(cr, s, EXT)
  return EXT.x_advance
end

local function chars(s)
  local out = {}
  for ch in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do out[#out + 1] = ch end
  return out
end

-- Draws text with its baseline at y. Returns the drawn width.
-- o: font, bold, align ('left'|'center'|'right'), alpha, spacing (extra px between glyphs)
function M.text(cr, s, x, y, size, color, o)
  o = o or {}
  s = tostring(s)
  set_font(cr, size, o)
  M.rgba(cr, color, o.alpha)
  local sp = o.spacing or 0
  local w
  if sp ~= 0 then
    w = 0
    for _, ch in ipairs(chars(s)) do w = w + advance(cr, ch) + sp end
    w = w - sp
  else
    w = advance(cr, s)
  end
  local px = x
  if o.align == 'right' then px = x - w elseif o.align == 'center' then px = x - w / 2 end
  if sp ~= 0 then
    local cx = px
    for _, ch in ipairs(chars(s)) do
      cairo_move_to(cr, cx, y)
      cairo_show_text(cr, ch)
      cx = cx + advance(cr, ch) + sp
    end
  else
    cairo_move_to(cr, px, y)
    cairo_show_text(cr, s)
  end
  return w
end

function M.text_width(cr, s, size, o)
  o = o or {}
  set_font(cr, size, o)
  return advance(cr, tostring(s))
end

-- greedy word wrap using real glyph metrics
function M.wrap(cr, s, maxw, size, o)
  o = o or {}
  set_font(cr, size, o)
  local lines, line = {}, ''
  for word in tostring(s):gmatch('%S+') do
    local try = (line == '') and word or (line .. ' ' .. word)
    if advance(cr, try) > maxw and line ~= '' then
      lines[#lines + 1] = line
      line = word
    else
      line = try
    end
  end
  if line ~= '' then lines[#lines + 1] = line end
  return lines
end

function M.bar(cr, x, y, w, h, pct, color, bg)
  pct = M.clamp(pct or 0, 0, 100)
  M.rrect(cr, x, y, w, h, h / 2)
  M.rgba(cr, bg)
  cairo_fill(cr)
  if pct > 0 then
    M.rrect(cr, x, y, math.max(h, w * pct / 100), h, h / 2)
    M.rgba(cr, color)
    cairo_fill(cr)
  end
end

-- sparkline; values = array, newest last. max may be nil (auto)
function M.graph(cr, x, y, w, h, values, max, color, fill)
  local n = #values
  if n < 2 then return end
  if not max then
    max = 1
    for i = 1, n do if values[i] > max then max = values[i] end end
  end
  local function pt(i)
    return x + (i - 1) * (w / (n - 1)), y + h - M.clamp(values[i] / max, 0, 1) * h
  end
  if fill then
    cairo_new_path(cr)
    cairo_move_to(cr, x, y + h)
    for i = 1, n do
      local px, py = pt(i)
      cairo_line_to(cr, px, py)
    end
    cairo_line_to(cr, x + w, y + h)
    cairo_close_path(cr)
    M.rgba(cr, color, 0.16)
    cairo_fill(cr)
  end
  cairo_new_path(cr)
  for i = 1, n do
    local px, py = pt(i)
    if i == 1 then cairo_move_to(cr, px, py) else cairo_line_to(cr, px, py) end
  end
  M.rgba(cr, color)
  cairo_set_line_width(cr, 1.4)
  cairo_stroke(cr)
end

function M.circle(cr, cx, cy, r, color, lw, mult)
  cairo_new_path(cr)
  cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
  M.rgba(cr, color, mult)
  cairo_set_line_width(cr, lw or 1.5)
  cairo_stroke(cr)
end

function M.dot(cr, cx, cy, r, color, mult)
  cairo_new_path(cr)
  cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
  M.rgba(cr, color, mult)
  cairo_fill(cr)
end

function M.line(cr, x1, y1, x2, y2, color, lw, mult)
  cairo_new_path(cr)
  cairo_move_to(cr, x1, y1)
  cairo_line_to(cr, x2, y2)
  M.rgba(cr, color, mult)
  cairo_set_line_width(cr, lw or 1)
  cairo_stroke(cr)
end

return M
