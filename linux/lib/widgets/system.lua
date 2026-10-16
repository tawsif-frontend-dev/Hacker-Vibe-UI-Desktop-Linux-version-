-- System Status: CPU / RAM / swap / disks with colour-coded thresholds + live network graph.
local hv = require 'hv'

local M = { W = 384, H = 358, interval = 1 }

local REAL_FS = { ext4 = 1, ext3 = 1, ext2 = 1, btrfs = 1, xfs = 1, f2fs = 1, zfs = 1, jfs = 1,
                  ntfs = 1, ntfs3 = 1, ['fuse.ntfs-3g'] = 1, fuseblk = 1, exfat = 1, reiserfs = 1 }
local SKIP = { '^/boot', '^/snap', '^/var/lib/snapd', '^/run', '^/sys', '^/proc', '^/dev',
               '^/var/lib/docker', '^/var/lib/flatpak' }

local disks, disks_t = nil, 0
local net = { iface = nil, iface_t = 0, down = {}, up = {} }
local HIST = 60

local function disk_label(mp)
  if mp == '/' then return 'ROOT' end
  local base = mp:match('([^/]+)$') or mp
  return base:upper():sub(1, 8)
end

local function detect_disks()
  local want = hv.settings().DISKS
  local list = {}
  if want and want ~= 'auto' then
    for mp in want:gmatch('%S+') do list[#list + 1] = mp end
  else
    local seen = {}
    for line in (hv.read_file('/proc/mounts') or ''):gmatch('[^\n]+') do
      local dev, mp, fs = line:match('^(%S+)%s+(%S+)%s+(%S+)')
      if dev and REAL_FS[fs] and not seen[dev] then
        local skip = false
        for _, pat in ipairs(SKIP) do if mp:match(pat) then skip = true end end
        if not skip then
          seen[dev] = true
          list[#list + 1] = (mp:gsub('\\040', ' '))
        end
      end
    end
    table.sort(list, function(a, b)
      if a == '/' then return true elseif b == '/' then return false end
      return a < b
    end)
  end
  while #list > 3 do table.remove(list) end
  if #list == 0 then list[1] = '/' end
  return list
end

function M.detect_iface()
  local want = hv.settings().NET_IFACE
  if want and want ~= 'auto' and want ~= '' then return want end
  for line in (hv.read_file('/proc/net/route') or ''):gmatch('[^\n]+') do
    local iface, dest = line:match('^(%S+)%s+(%S+)')
    if iface and dest == '00000000' then return iface end
  end
  for line in (hv.read_file('/proc/net/dev') or ''):gmatch('[^\n]+') do
    local iface = line:match('^%s*([%w%-%.@]+):')
    if iface and iface ~= 'lo' then return iface end
  end
  return 'lo'
end

local function push(tbl, v)
  tbl[#tbl + 1] = v
  if #tbl > HIST then table.remove(tbl, 1) end
end

local function short(s) return (s:gsub('iB', 'B'):gsub('%s+', '')) end

local function meter(cr, t, y, label, pct, right)
  local color = hv.level_color(t, pct)
  hv.text(cr, string.format('%s %d%%', label, pct), 16, y, 11, color, { bold = true })
  hv.text(cr, right, M.W - 16, y, 10, t.textlight, { align = 'right' })
  hv.bar(cr, 16, y + 5, M.W - 32, 4, pct, color, t.barbg)
end

function M.draw(cr)
  local t = hv.theme()
  local now = os.time()
  hv.card(cr, M.W, M.H, t)

  -- header
  local user = os.getenv('USER') or 'user'
  local host = hv.trim(hv.read_file('/etc/hostname') or 'linux')
  hv.text(cr, user .. '@' .. host, 16, 24, 10, t.accent, { bold = true })
  hv.text(cr, os.date('%H:%M:%S', now), 16 + hv.text_width(cr, user .. '@' .. host, 10, { bold = true }) + 12, 24, 10, t.dim)
  hv.text(cr, 'UP ' .. hv.fmt_uptime(), M.W - 16, 24, 9, t.dim, { align = 'right' })
  hv.line(cr, 12, 32, M.W - 12, 32, t.faint, 1, 0.6)

  local y = 52
  local cpu = tonumber(conky_parse('${cpu cpu0}')) or 0
  meter(cr, t, y, 'CPU', cpu, conky_parse('${freq_g 1}') .. ' GHz'); y = y + 33

  local mem = tonumber(conky_parse('${memperc}')) or 0
  meter(cr, t, y, 'RAM', mem, short(conky_parse('${mem}')) .. ' / ' .. short(conky_parse('${memmax}'))); y = y + 33

  local swp = tonumber(conky_parse('${swapperc}')) or 0
  local swmax = short(conky_parse('${swapmax}'))
  meter(cr, t, y, 'SWAP', swp, (swmax == '0B' or swmax == '') and 'none' or (short(conky_parse('${swap}')) .. ' / ' .. swmax)); y = y + 33

  if not disks or now - disks_t > 60 then disks, disks_t = detect_disks(), now end
  for _, mp in ipairs(disks) do
    local pct = tonumber(conky_parse('${fs_used_perc ' .. mp .. '}')) or 0
    local right = short(conky_parse('${fs_used ' .. mp .. '}')) .. ' / ' .. short(conky_parse('${fs_size ' .. mp .. '}'))
    meter(cr, t, y, disk_label(mp), pct, right)
    y = y + 33
  end

  -- network graph
  if not net.iface or now - net.iface_t > 30 then net.iface, net.iface_t = M.detect_iface(), now end
  local down = tonumber(conky_parse('${downspeedf ' .. net.iface .. '}')) or 0
  local up   = tonumber(conky_parse('${upspeedf ' .. net.iface .. '}')) or 0
  push(net.down, down); push(net.up, up)

  local ny = y + 6
  hv.text(cr, 'NET', 16, ny, 10, t.accent, { bold = true })
  hv.text(cr, 'IN ' .. hv.fmt_rate(down), 54, ny, 10, t.textlight)
  hv.text(cr, 'UP ' .. hv.fmt_rate(up), M.W - 16, ny, 10, t.textlight, { align = 'right' })
  local peak = 8
  for i = 1, #net.down do peak = math.max(peak, net.down[i], net.up[i]) end
  local gh = math.max(24, (M.H - 28) - (ny + 10))
  hv.graph(cr, 16, ny + 10, M.W - 32, gh, net.down, peak, t.accent, true)
  hv.graph(cr, 16, ny + 10, M.W - 32, gh, net.up, peak, t.secondary, false)

  -- footer
  local site = (hv.settings().PORTFOLIO_URL or ''):gsub('^%a+://', ''):gsub('^www%.', ''):gsub('/.*$', '')
  hv.text(cr, site, 16, M.H - 12, 9, t.dim)
end

return M
