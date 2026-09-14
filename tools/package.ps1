param([switch]$SkipTests)
$ErrorActionPreference = 'Stop'
if (-not $SkipTests) { & (Join-Path $PSScriptRoot 'test.ps1') }
$projectRoot = Split-Path $PSScriptRoot -Parent
$engineFolder = Join-Path $PSScriptRoot 'godot'
$outputFolder = Join-Path $projectRoot 'build/windows'
$runtimeRoot = Join-Path $projectRoot 'artifacts/runtime'
New-Item -ItemType Directory -Force $outputFolder,$runtimeRoot | Out-Null
$env:APPDATA = $runtimeRoot
$env:LOCALAPPDATA = $runtimeRoot
$engine = Join-Path $engineFolder 'Godot_v4.5.2-stable_win64_console.exe'
& $engine --headless --path $projectRoot --script res://tests/write_licenses.gd
if ($LASTEXITCODE -ne 0) { throw 'Engine license extraction failed' }
& $engine --headless --path $projectRoot --export-release 'Windows Desktop' (Join-Path $outputFolder 'TaiwanFighter.exe')
if ($LASTEXITCODE -ne 0) { throw 'Godot pack export failed' }
# Standard optimized runtime from the official 4.5.2 export template.
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'portable-play.cmd') -Destination (Join-Path $outputFolder 'Play.cmd') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md'),(Join-Path $projectRoot 'THIRD_PARTY_NOTICES.md'),(Join-Path $projectRoot 'GODOT_COPYRIGHT.txt') -Destination $outputFolder -Force
Get-FileHash (Join-Path $outputFolder 'TaiwanFighter.exe'),(Join-Path $outputFolder 'TaiwanFighter.pck') | Format-List | Out-File (Join-Path $outputFolder 'SHA256.txt') -Encoding utf8
$packageFiles = @('TaiwanFighter.exe','TaiwanFighter.pck','Play.cmd','README.md','THIRD_PARTY_NOTICES.md','GODOT_COPYRIGHT.txt','SHA256.txt') | ForEach-Object { Join-Path $outputFolder $_ }
Copy-Item -LiteralPath (Join-Path $projectRoot 'art/fonts/OFL.txt') -Destination (Join-Path $outputFolder 'FONT_LICENSE.txt') -Force
$packageFiles += Join-Path $outputFolder 'FONT_LICENSE.txt'
Compress-Archive -LiteralPath $packageFiles -DestinationPath (Join-Path $projectRoot 'build/TaiwanFighter-0.2.0-Windows.zip') -Force
