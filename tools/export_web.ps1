param([string]$Python='python',[switch]$SkipTests)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
if (-not $SkipTests) { & (Join-Path $PSScriptRoot 'test.ps1') }
$env:APPDATA=Join-Path $projectRoot 'artifacts/runtime'
$env:LOCALAPPDATA=$env:APPDATA
$engine=Join-Path $PSScriptRoot 'godot/Godot_v4.5.2-stable_win64_console.exe'
New-Item -ItemType Directory -Force (Join-Path $projectRoot 'build/web') | Out-Null
& $engine --headless --path $projectRoot --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
& $engine --headless --path $projectRoot --export-release Web
if ($LASTEXITCODE -ne 0) { throw 'Web export failed' }
& $Python (Join-Path $PSScriptRoot 'prepare_web.py')
if ($LASTEXITCODE -ne 0) { throw 'Web shell preparation failed' }
