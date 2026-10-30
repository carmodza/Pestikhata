param([switch]$BuildWeb)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$localFlutter = Join-Path $projectRoot 'tool\flutter.cmd'
$localDart = Join-Path $projectRoot 'tool\dart.cmd'
$hasLocalSdk = Test-Path -LiteralPath (Join-Path $projectRoot '.tooling\flutter\bin\flutter.bat')
$flutterCommand = if ($hasLocalSdk) { $localFlutter } else { 'flutter' }
$dartCommand = if ($hasLocalSdk) { $localDart } else { 'dart' }
function Invoke-Checked([string]$Executable, [string[]]$Arguments) {
  # Native warnings on stderr do not indicate a failing exit code.
  $ErrorActionPreference = 'Continue'
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) { throw "$Executable failed ($LASTEXITCODE)" }
}
Invoke-Checked 'node' @('tool/generate_l10n.mjs')
Invoke-Checked 'node' @('tool/check_resources.mjs')
Invoke-Checked $flutterCommand @('pub','get')
Invoke-Checked $flutterCommand @('gen-l10n')
Invoke-Checked $dartCommand @('run','build_runner','build')
Invoke-Checked $flutterCommand @('analyze')
Invoke-Checked $flutterCommand @('test')
Push-Location -LiteralPath functions
try {
  Invoke-Checked 'npm.cmd' @('ci','--no-audit','--no-fund')
  Invoke-Checked 'npm.cmd' @('test')
} finally { Pop-Location }
if ($BuildWeb) {
  Invoke-Checked $flutterCommand @('build','web','--release','--no-web-resources-cdn')
  Invoke-Checked 'node' @('tool/build_service_worker.mjs')
}
