-- Network: interface, local IP, ping latency, live down / up speed with graph.
local hv = require 'hv'
local system = require 'widgets.system'

local M = { W = 300, H = 108, interval = 1 }

local st = { iface = nil, iface_t = 0, down = {}, up = {} }
local HIST = 50

local function push(tbl, v)
  tbl[#tbl + 1] = v
  if #tbl > HIST then table.remove(tbl, 1) end
end

local function safe_host(h)
  h = tostring(h or '')
  if h:match('^[%w%.%-:]+$') then return h end
  return '1.1.1.1'
end

function M.draw(cr)
  local t = hv.theme()
  local S = hv.settings()
  local now = os.time()
  hv.card(cr, M.W, M.H, t)

  if not st.iface or now - st.iface_t > 30 then st.iface, st.iface_t = system.detect_iface(), now end
  local iface = st.iface
  local down = tonumber(conky_parse('${downspeedf ' .. iface .. '}')) or 0
  local up   = tonumber(conky_parse('${upspeedf ' .. iface .. '}')) or 0
  push(st.down, down); push(st.up, up)

  hv.text(cr, 'NETWORK', 14, 22, 10, t.accent, { bold = true, spacing = 2 })
  local ip = conky_parse('${addr ' .. iface .. '}')
  if ip == '' or ip:find('No Address') then ip = 'no address' end
  hv.text(cr, iface .. '  ' .. ip, M.W - 14, 22, 9, t.dim, { align = 'right' })

  hv.text(cr, 'DOWN', 14, 44, 9, t.dim)
  hv.text(cr, hv.fmt_rate(down), 52, 44, 11, t.accent, { bold = true })
  hv.text(cr, 'UP', 158, 44, 9, t.dim)
  hv.text(cr, hv.fmt_rate(up), 178, 44, 11, t.secondary, { bold = true })

  -- ping (cached by conky for 5 s; a lost packet returns an empty string)
  local host = safe_host(S.PING_HOST)
  local cmd = "${execi 5 ping -c1 -W1 -n " .. host .. " 2>/dev/null | sed -n 's/.*time=\\([0-9.]*\\).*/\\1/p'}"
  local ms = tonumber(conky_parse(cmd))
  hv.text(cr, 'PING', 14, 62, 9, t.dim)
  if ms then
    local color = ms < 60 and t.accent or (ms < 150 and t.warn or t.crit)
    hv.text(cr, string.format('%.0f ms', ms), 52, 62, 11, color, { bold = true })
  else
    hv.text(cr, 'OFFLINE', 52, 62, 11, t.crit, { bold = true })
  end
  hv.text(cr, host, 158, 62, 9, t.faint)

  local peak = 8
  for i = 1, #st.down do peak = math.max(peak, st.down[i], st.up[i]) end
  hv.graph(cr, 14, 72, M.W - 28, 26, st.down, peak, t.accent, true)
  hv.graph(cr, 14, 72, M.W - 28, 26, st.up, peak, t.secondary, false)
end

return M
