-- Random quote rotator. Reads @Resources\Quotes.txt ("text|author" per line).
function Initialize()
    quotes = {}
    local f = io.open(SKIN:ReplaceVariables('#@#') .. 'Quotes.txt', 'r')
    if f then
        for line in f:lines() do
            line = line:gsub('\r', '')
            if line:match('%S') and not line:match('^%s*;') then
                local text, author = line:match('^%s*(.-)%s*|%s*(.-)%s*$')
                table.insert(quotes, { text or line, author or '' })
            end
        end
        f:close()
    end
    if #quotes == 0 then
        quotes = { { 'The only way to do great work is to love what you do.', '{USER}' } }
    end
    math.randomseed(os.time())
    last = 1
    nextAt = 0
end

local function interval()
    return math.max(tonumber(SKIN:GetVariable('QuoteMinutes', '60')) or 60, 1) * 60
end

function Next()
    local i = math.random(#quotes)
    if #quotes > 1 then
        while i == last do i = math.random(#quotes) end
    end
    last = i
    nextAt = os.time() + interval()
    SKIN:Bang('!SetVariable', 'QuoteText', quotes[i][1])
    local who = SKIN:GetVariable('UserName', 'Hacker')
    local author = quotes[i][2]:gsub('{USER}', who)
    SKIN:Bang('!SetVariable', 'QuoteAuthor', author)
    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end

function Update()
    if os.time() >= nextAt then Next() end
    return quotes[last][1]
end
