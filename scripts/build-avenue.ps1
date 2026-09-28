$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Path (Join-Path $projectRoot 'build') -Force | Out-Null
& (Join-Path $projectRoot '.tools/rojo/7.7.0/rojo.exe') build (Join-Path $projectRoot 'alphabet.project.json') --output (Join-Path $projectRoot 'build/Dinografia-AvenidaAZ.rbxlx')
if ($LASTEXITCODE -ne 0) { throw 'Falha no build da avenida A-Z.' }
