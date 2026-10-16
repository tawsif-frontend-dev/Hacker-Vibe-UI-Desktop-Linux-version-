-- Quote: rotates quotes from quotes.txt ("text|author", {USER} = your name).
-- The quote changes every QUOTE_MINUTES; `hackervibe quote` jumps to the next one right away.
local hv = require 'hv'

local M = { W = 368, H = 138, interval = 5 }

local quotes, quotes_t = {}, 0
local wrap_cache = { key = nil, lines = nil }

local function load_quotes()
  local S = hv.settings()
  local list = {}
  local src = hv.read_file(hv.dir.config .. '/quotes.txt') or ''
  for line in src:gmatch('[^\r\n]+') do
    if not line:match('^%s*;') and line:find('|', 1, true) then
      local text, author = line:match('^(.-)|(.*)$')
      if text and text ~= '' then
        list[#list + 1] = {
          text = text:gsub('{USER}', S.USER_NAME),
          author = hv.trim((author:gsub('{USER}', S.USER_NAME))),
        }
      end
    end
  end
  if #list == 0 then list[1] = { text = 'Add quotes to ' .. hv.dir.config .. '/quotes.txt', author = 'HackerVibe' } end
  return list
end

local function pick(now)
  if #quotes == 0 or now - quotes_t > 60 then quotes, quotes_t = load_quotes(), now end
  local mins = math.max(1, hv.num('QUOTE_MINUTES', 60))
  local offset = tonumber(hv.trim(hv.read_file(hv.dir.config .. '/state/quote_offset') or '0')) or 0
  local period = math.floor(now / (mins * 60)) + offset
  -- cheap deterministic scramble so the order doesn't feel like a plain loop
  local idx = (period * 2654435761 % 4294967296) % #quotes + 1
  return quotes[idx], idx
end

function M.draw(cr)
  local t = hv.theme()
  hv.card(cr, M.W, M.H, t)

  local q, idx = pick(os.time())
  local maxw = M.W - 40
  local key = idx .. ':' .. q.text
  if wrap_cache.key ~= key then
    wrap_cache.key = key
    wrap_cache.lines = hv.wrap(cr, q.text, maxw, 11)
  end
  local lines = wrap_cache.lines

  hv.text(cr, '\u{201C}', 14, 40, 34, t.accent, { bold = true })

  local y = 36
  for i, l in ipairs(lines) do
    if i > 4 then break end
    hv.text(cr, l, 36, y, 11, t.textlight)
    y = y + 16
  end
  hv.text(cr, '- ' .. q.author, M.W - 16, M.H - 14, 10, t.accent, { align = 'right', bold = true })
end

return M
