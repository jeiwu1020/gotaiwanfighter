param([switch]$Editor, [switch]$Headless, [string]$Script = "", [string]$Renderer = "gl_compatibility")
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$engine = Join-Path $PSScriptRoot 'godot/Godot_v4.5.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $engine)) { throw 'Godot 4.5.2 missing. Run tools/setup.ps1 first.' }
$runtimeRoot = Join-Path $projectRoot 'artifacts/runtime'
New-Item -ItemType Directory -Force $runtimeRoot | Out-Null
# Process-local paths: avoid inaccessible Windows profile folders in restricted runners.
$env:APPDATA = $runtimeRoot
$env:LOCALAPPDATA = $runtimeRoot
$engineArgs = @('--path', $projectRoot, '--rendering-method', $Renderer)
if ($Renderer -eq 'gl_compatibility') { $engineArgs += @('--rendering-driver', 'opengl3') }
if ($Editor) { $engineArgs += '--editor' }
if ($Headless) { $engineArgs += '--headless' }
if ($Script) { $engineArgs += @('--script', $Script) }
& $engine @engineArgs
exit $LASTEXITCODE
