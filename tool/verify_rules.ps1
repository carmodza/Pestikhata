$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$portableJava = Get-ChildItem (Join-Path $projectRoot '.tooling\java21') -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
if ($portableJava) {
  $env:JAVA_HOME = $portableJava.FullName
  $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
}
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
  throw 'Install Java 21 and add java to PATH before running Firestore emulator tests.'
}
$localCli = Join-Path $projectRoot '.tooling\firebase-cli\node_modules\firebase-tools\lib\bin\firebase.js'
$emulatorArgs = @('emulators:exec', '--project', 'demo-pestikhata', '--only', 'firestore', 'npm --prefix functions run test:rules')
$ErrorActionPreference = 'Continue'
if (Test-Path -LiteralPath $localCli) {
  & node $localCli @emulatorArgs
} else {
  & npx.cmd --yes firebase-tools @emulatorArgs
}
if ($LASTEXITCODE -ne 0) { throw "Firestore emulator tests failed ($LASTEXITCODE)" }
