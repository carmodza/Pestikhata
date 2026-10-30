$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$lockPath = Join-Path $projectRoot 'pubspec.lock'
if (-not (Test-Path -LiteralPath $lockPath)) { throw 'Run flutter pub get first.' }
$lock = Get-Content -LiteralPath $lockPath -Raw
$versionMatch = [regex]::Match($lock, '(?ms)^  drift:\s*\r?\n(?:(?!^  \S).)*?^    version: "([^"]+)"')
if (-not $versionMatch.Success) { throw 'Cannot determine the locked Drift version.' }
$version = $versionMatch.Groups[1].Value
$releaseUri = "https://api.github.com/repos/simolus3/drift/releases/tags/drift-$version"
$release = Invoke-RestMethod -Uri $releaseUri
foreach ($target in @('sqlite3.wasm','drift_worker.dart.js')) {
  $asset = $release.assets | Where-Object { $_.name -eq $target -or ($target -eq 'drift_worker.dart.js' -and $_.name -eq 'drift_worker.js') } | Select-Object -First 1
  if ($null -eq $asset) { throw "Missing $target in official Drift release $version" }
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile (Join-Path $projectRoot "web/$target")
  if ($asset.digest -and $asset.digest.StartsWith('sha256:')) {
    $actualHash = (Get-FileHash -LiteralPath (Join-Path $projectRoot "web/$target") -Algorithm SHA256).Hash.ToLower()
    if ($actualHash -ne $asset.digest.Substring(7)) { throw "Hash mismatch for $target" }
  }
  Write-Output "Downloaded $target for Drift $version"
}
