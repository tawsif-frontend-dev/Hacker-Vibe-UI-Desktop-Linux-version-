<#
  Hacker Desktop Suite - installer / personaliser (Windows, Rainmeter 4.4+)
  Run:  right-click install.bat > Run   (or)   powershell -ExecutionPolicy Bypass -File install.ps1
  Safe to run again any time to change your name, links or event.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Ask($q, $default) {
    $a = Read-Host "$q [$default]"
    if ([string]::IsNullOrWhiteSpace($a)) { $default } else { $a.Trim() }
}
function Set-Setting($file, $key, $value) {
    $text = [IO.File]::ReadAllText($file)
    $pattern = "(?m)^$([regex]::Escape($key))=.*$"
    $safe = $value -replace '\$', '$$$$'
    $text = [regex]::Replace($text, $pattern, "$key=$safe")
    [IO.File]::WriteAllText($file, $text, (New-Object Text.UTF8Encoding($true)))
}

# ---- 1. find Rainmeter ------------------------------------------------
$rmExe = @("$env:ProgramFiles\Rainmeter\Rainmeter.exe", "${env:ProgramFiles(x86)}\Rainmeter\Rainmeter.exe") |
         Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $rmExe) {
    Write-Host "Rainmeter is not installed. Install it first:  winget install Rainmeter.Rainmeter" -ForegroundColor Yellow
    Write-Host "(or download from https://www.rainmeter.net) - then run this script again."
    exit 1
}
$skinsRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins'
$ini = Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
if (Test-Path $ini) {
    $m = Select-String -Path $ini -Pattern '^SkinPath=(.+)$' | Select-Object -First 1
    if ($m) { $skinsRoot = $m.Matches[0].Groups[1].Value.Trim() }
}
$target = Join-Path $skinsRoot 'HackerSuite'
$source = Join-Path $PSScriptRoot 'Skins\HackerSuite'
Write-Host "`nInstalling to: $target`n" -ForegroundColor Cyan

# ---- 2. questions -----------------------------------------------------
$name  = Ask 'Your name (shown on wallpaper + terminal widget, Latin letters, max 14)' $env:USERNAME
$label = Ask 'Label for your website / GitHub shortcut' 'GitHub'
$url   = Ask 'URL for that shortcut' 'https://github.com'
$evName  = Ask 'Countdown event name (calendar widget)' 'New Year'
$evDay   = Ask 'Event day (1-31)' '1'
$evMonth = Ask 'Event month (1-12)' '1'

# ---- 3. copy files (keep nothing stale) -------------------------------
if (Test-Path $target) { Remove-Item $target -Recurse -Force }
Copy-Item $source $target -Recurse -Force
$settings = Join-Path $target '@Resources\Settings.inc'

# ---- 4. detect machine-specific paths ---------------------------------
$vs = @("$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe", "$env:ProgramFiles\Microsoft VS Code\Code.exe") |
      Where-Object { Test-Path $_ } | Select-Object -First 1
try   { $dl = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path }
catch { $dl = Join-Path $env:USERPROFILE 'Downloads' }

Set-Setting $settings 'UserName' $name
Set-Setting $settings 'PortfolioLabel' $label
Set-Setting $settings 'PortfolioURL' $url
Set-Setting $settings 'EventName' $evName
Set-Setting $settings 'EventDay' $evDay
Set-Setting $settings 'EventMonth' $evMonth
Set-Setting $settings 'DownloadsPath' $dl
if ($vs) { Set-Setting $settings 'VSCodePath' $vs } else { Write-Host "VS Code not found - edit VSCodePath in Settings.inc if you use it." -ForegroundColor Yellow }

# ---- 5. wallpapers with your name -------------------------------------
$accent = @{ Blue = '153,213,255'; Green = '168,255,206'; Red = '255,146,146'; Purple = '206,168,255' }
$wpDir = Join-Path $target '@Resources\Wallpaper'
$text = $name.ToUpper(); if ($text.Length -gt 14) { $text = $text.Substring(0, 14) }
foreach ($theme in $accent.Keys) {
    $c = $accent[$theme].Split(',') | ForEach-Object { [int]$_ }
    $bmp = New-Object Drawing.Bitmap (Join-Path $wpDir "Base\Hacker_Wallpaper_${theme}_1920x1080.png")
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.TextRenderingHint = 'AntiAliasGridFit'; $g.SmoothingMode = 'AntiAlias'
    $fmt = [Drawing.StringFormat]::GenericTypographic
    $size = 105
    do {
        $font = New-Object Drawing.Font('Consolas', $size, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
        $sz = $g.MeasureString($text, $font, 2000, $fmt); $size -= 4
    } while ($sz.Width -gt 440 -and $size -gt 28)
    $x = 958 - $sz.Width / 2; $y = 742 - $sz.Height / 2
    $glow = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(16, $c[0], $c[1], $c[2]))
    foreach ($dx in -8, -5, -2, 0, 2, 5, 8) { foreach ($dy in -8, -5, -2, 0, 2, 5, 8) {
        $g.DrawString($text, $font, $glow, $x + $dx, $y + $dy, $fmt) } }
    $g.DrawString($text, $font, (New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, $c[0], $c[1], $c[2]))), $x, $y, $fmt)
    $g.Dispose()
    $bmp.Save((Join-Path $wpDir "Hacker_Wallpaper_${theme}_1920x1080.png"), [Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# ---- 6. fonts (per-user, no admin needed) -----------------------------
$fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
New-Item $fontDir -ItemType Directory -Force | Out-Null
$reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
Get-ChildItem (Join-Path $target '@Resources\Fonts') -Filter *.ttf | ForEach-Object {
    Copy-Item $_.FullName $fontDir -Force
    New-ItemProperty -Path $reg -Name "$($_.BaseName) (TrueType)" -Value (Join-Path $fontDir $_.Name) -PropertyType String -Force | Out-Null
}

# ---- 7. start Rainmeter and load the widgets --------------------------
if (-not (Get-Process Rainmeter -ErrorAction SilentlyContinue)) { Start-Process $rmExe; Start-Sleep 4 }
else { & $rmExe '!RefreshApp'; Start-Sleep 2 }
foreach ($w in 'Clock', 'Calendar', 'Weather', 'SystemStatus', 'Network', 'Terminal', 'Quote', 'Shortcuts', 'ThemeCycler') {
    & $rmExe '!ActivateConfig' "HackerSuite\$w" "$w.ini"
}

Write-Host "`nDone!  Next steps:" -ForegroundColor Green
Write-Host " 1. Drag each widget where you want it (they start stacked in one corner)."
Write-Host " 2. Right-click any widget > Theme > Green   (this also sets your wallpaper)."
Write-Host " 3. Rainmeter > Layouts > Save, so your arrangement survives restarts."
Write-Host " 4. If fonts look wrong, restart Rainmeter once (Windows may need a sign-out on older builds)."
Write-Host " Rerun this script any time to change your name or links.`n"
