-- Terminal: neofetch-style readout (OS, kernel, CPU, GPU, memory, uptime, shell, screen, theme).
local hv = require 'hv'

local M = { W = 384, H = 300, interval = 1 }

local info  -- static facts, gathered lazily on first draw

local function os_name()
  local s = hv.read_file('/etc/os-release') or ''
  local n = s:match('PRETTY_NAME="?([^"\n]+)"?')
  return n or 'Linux'
end

local function cpu_name()
  local s = hv.read_file('/proc/cpuinfo') or ''
  local n = s:match('model name%s*:%s*([^\n]+)') or s:match('Model%s*:%s*([^\n]+)') or s:match('Hardware%s*:%s*([^\n]+)')
  if not n then return 'unknown' end
  n = n:gsub('%(R%)', ''):gsub('%(TM%)', ''):gsub('CPU @.*$', ''):gsub('%s+', ' ')
  return hv.trim(n)
end

local function gpu_name()
  local l = hv.popen_line("lspci | grep -iE 'vga|3d controller|display controller' | head -1")
  if not l then return 'n/a' end
  local n = l:match('%[(.-)%]%s*[^%]]*$') or l:match(': (.+)$') or l
  n = n:gsub('%s*%(rev [%x]+%)', ''):gsub('Corporation', ''):gsub('%s+', ' ')
  return hv.trim(n)
end

local function gather()
  info = {
    os     = os_name(),
    kernel = hv.popen_line('uname -r') or '?',
    cpu    = cpu_name(),
    gpu    = gpu_name(),
    shell  = (os.getenv('SHELL') or 'sh'):match('[^/]+$'),
    user   = os.getenv('USER') or hv.popen_line('whoami') or 'user',
    host   = hv.trim(hv.read_file('/etc/hostname') or hv.popen_line('hostname') or 'linux'),
    screen = hv.popen_line("xdpyinfo | awk '/dimensions:/{print $2}'") or 'n/a',
    de     = os.getenv('XDG_CURRENT_DESKTOP') or os.getenv('DESKTOP_SESSION') or 'n/a',
  }
end

local function clip(s, n)
  if #s > n then return s:sub(1, n - 1) .. '…' end
  return s
end

function M.draw(cr)
  local t, tname = hv.theme()
  if not info then gather() end

  hv.card(cr, M.W, M.H, t)

  -- title bar
  hv.text(cr, 'TERMINAL', 16, 22, 9, t.dim, { spacing = 2 })
  hv.dot(cr, M.W - 50, 18, 4.2, t.accent)
  hv.dot(cr, M.W - 36, 18, 4.2, t.crit)
  hv.dot(cr, M.W - 22, 18, 4.2, t.warn)
  hv.line(cr, 12, 30, M.W - 12, 30, t.faint, 1, 0.6)

  local prompt = info.user .. '@' .. info.host .. ':~$'
  local pw = hv.text(cr, prompt, 16, 50, 10, t.accent, { bold = true })
  hv.text(cr, 'neofetch', 16 + pw + 6, 50, 10, t.textlight)

  local used = conky_parse('${mem}')
  local max  = conky_parse('${memmax}')
  local up   = hv.fmt_uptime()

  local rows = {
    { 'OS',      clip(info.os, 38) },
    { 'KERNEL',  clip(info.kernel, 38) },
    { 'CPU',     clip(info.cpu, 38) },
    { 'GPU',     clip(info.gpu, 38) },
    { 'MEMORY',  used .. ' / ' .. max },
    { 'UPTIME',  up },
    { 'SHELL',   info.shell },
    { 'DESKTOP', clip(info.de, 38) },
    { 'SCREEN',  info.screen },
    { 'THEME',   tname },
  }
  local y = 70
  for _, r in ipairs(rows) do
    hv.text(cr, r[1], 16, y, 9.5, t.dim)
    hv.text(cr, r[2], 88, y, 9.5, t.textlight)
    y = y + 15
  end

  -- palette swatches
  local sw = { t.accent, t.faint, t.secondary, t.dim, t.warn, t.crit, t.textlight, t.hover }
  for i, c in ipairs(sw) do
    hv.rrect(cr, 16 + (i - 1) * 24, y + 3, 21, 11, 2)
    hv.rgba(cr, c)
    cairo_fill(cr)
  end

  -- closing prompt with a blinking cursor
  local py = M.H - 14
  local w = hv.text(cr, prompt, 16, py, 10, t.accent, { bold = true })
  if os.time() % 2 == 0 then
    hv.rgba(cr, t.accent)
    cairo_rectangle(cr, 16 + w + 6, py - 9, 6, 11)
    cairo_fill(cr)
  end
end

return M
