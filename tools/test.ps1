$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$env:APPDATA=Join-Path $projectRoot 'artifacts/runtime'
$env:LOCALAPPDATA=$env:APPDATA
$engine=Join-Path $PSScriptRoot 'godot/Godot_v4.5.2-stable_win64_console.exe'
$tests=@('parity_combat_test','parity_depth_test','parity_modes_test','parity_scene_test','parity_devices_test','passive_test','rig_test')
foreach ($test in $tests) {
    $log=Join-Path $projectRoot "artifacts/benchmark/$test.log"
    # A fast headless loop can exhaust 120 frames before audio cleanup's timer.
    # Cap this harness at 60 FPS and retain a 30-second emergency frame limit.
    & $engine --headless --max-fps 60 --path $projectRoot --script "res://tests/$test.gd" --quit-after 1800 *> $log
    if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR|Parse Error|^FAIL:|ObjectDB instances leaked|resources still in use')) { throw "Failed: $test; see $log" }
    Write-Output "PASS $test"
}
