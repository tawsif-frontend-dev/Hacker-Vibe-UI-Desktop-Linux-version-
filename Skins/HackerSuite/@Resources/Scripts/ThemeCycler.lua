-- Hacker Suite theme engine: SetTheme('Blue'), NextTheme(), Current()
THEMES = { 'Green', 'Blue', 'Red', 'Purple' }

function Initialize()
    RES = SKIN:ReplaceVariables('#@#')
end

local function copyFile(src, dst)
    local inF = io.open(src, 'rb')
    if not inF then return false end
    local data = inF:read('*a')
    inF:close()
    local outF = io.open(dst, 'wb')
    if not outF then return false end
    outF:write(data)
    outF:close()
    return true
end

local function indexOf(name)
    for i, t in ipairs(THEMES) do
        if t:lower() == tostring(name):lower() then return i end
    end
    return 0
end

function Current()
    return SKIN:GetVariable('ThemeName', 'Blue')
end

function SetTheme(name)
    local i = indexOf(name)
    if i == 0 then
        print('ThemeCycler: unknown theme ' .. tostring(name))
        return
    end
    name = THEMES[i]
    if not copyFile(RES .. 'Themes\\Theme-' .. name .. '.inc', RES .. 'Themes\\Theme.inc') then
        print('ThemeCycler: could not write Theme.inc')
        return
    end
    copyFile(RES .. 'Variables-' .. name .. '.inc', RES .. 'Variables.inc')

    if SKIN:GetVariable('ThemeWallpaper', '1') == '1' then
        local wp = RES .. 'Wallpaper\\Hacker_Wallpaper_' .. name .. '_1920x1080.png'
        local f = io.open(wp, 'rb')
        if f then
            f:close()
            SKIN:Bang('!SetWallpaper', wp)
        end
    end
    SKIN:Bang('!RefreshApp')
end

function NextTheme()
    SetTheme(THEMES[indexOf(Current()) % #THEMES + 1])
end

function Update()
    return Current()
end
