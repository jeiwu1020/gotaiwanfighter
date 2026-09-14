param(
    [string]$BucketName = 'taiwanfighter-benchmark-assets',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$webRoot = Join-Path $projectRoot 'build/web'
$entry = Join-Path $webRoot 'index.html'

if (-not (Test-Path -LiteralPath $entry)) {
    throw "Web export is missing: $entry. Run tools/export_web.ps1 first."
}

$files = Get-ChildItem -LiteralPath $webRoot -Recurse -File |
    Where-Object { $_.Extension -ne '.import' -and $_.Name -ne '_headers' } |
    Sort-Object {
    if ($_.Name -eq 'index.html') { 1 } else { 0 }
}, FullName

foreach ($file in $files) {
    $relative = $file.FullName.Substring($webRoot.Length).TrimStart([char]92).Replace('\\', '/')
    $object = "$BucketName/$relative"
    if ($DryRun) {
        Write-Host "Would upload $relative -> r2://$object"
        continue
    }
    & npx wrangler r2 object put $object --file $file.FullName --remote
    if ($LASTEXITCODE -ne 0) { throw "R2 upload failed: $relative" }
}

Write-Host "Uploaded $($files.Count) Web export files to r2://$BucketName."
