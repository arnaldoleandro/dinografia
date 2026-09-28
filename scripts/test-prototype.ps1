$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$compiler = Join-Path $projectRoot '.tools/luau/luau-compile.exe'
$runtime = Join-Path $projectRoot '.tools/luau/luau.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw 'Execute scripts/setup-luau.ps1 antes dos testes.' }
$sources = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src') -Filter '*.luau' -Recurse
foreach ($source in $sources) {
    & $compiler --null $source.FullName
    if ($LASTEXITCODE -ne 0) { throw "Erro de sintaxe: $($source.FullName)" }
}
foreach ($test in (Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tests') -Filter '*.spec.luau')) {
    & $runtime $test.FullName
    if ($LASTEXITCODE -ne 0) { throw "Falha no teste: $($test.Name)" }
}
& (Join-Path $PSScriptRoot 'build-prototype.ps1')
& (Join-Path $PSScriptRoot 'build-avenue.ps1')
