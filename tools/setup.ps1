$ErrorActionPreference = 'Stop'
$engineFolder = Join-Path $PSScriptRoot 'godot'
$archivePath = Join-Path $PSScriptRoot 'godot.zip'
if (-not (Test-Path (Join-Path $engineFolder 'Godot_v4.5.2-stable_win64_console.exe'))) {
    Invoke-WebRequest 'https://github.com/godotengine/godot-builds/releases/download/4.5.2-stable/Godot_v4.5.2-stable_win64.exe.zip' -OutFile $archivePath
    Expand-Archive -LiteralPath $archivePath -DestinationPath $engineFolder -Force
}
$runtimeRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'artifacts/runtime'
New-Item -ItemType Directory -Force $runtimeRoot | Out-Null
$env:APPDATA = $runtimeRoot
$env:LOCALAPPDATA = $runtimeRoot
& (Join-Path $engineFolder 'Godot_v4.5.2-stable_win64_console.exe') --headless --path (Split-Path $PSScriptRoot -Parent) --editor --import --quit
exit $LASTEXITCODE
