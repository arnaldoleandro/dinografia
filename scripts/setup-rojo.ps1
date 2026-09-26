$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolDirectory = Join-Path $projectRoot '.tools/rojo/7.7.0'
$archivePath = Join-Path $toolDirectory 'rojo.zip'
$executablePath = Join-Path $toolDirectory 'rojo.exe'

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Este instalador foi preparado para Windows x64.'
}

New-Item -ItemType Directory -Path $toolDirectory -Force | Out-Null
Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-windows-x86_64.zip' -OutFile $archivePath
$expectedHash = '2179c44862a10ecbd725bdfeb4abc64e16dc4aad9b6c8f3e1a7c46a87280b949'
if ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Hash do download diferente do SHA256 publicado no release oficial.'
}
Expand-Archive -LiteralPath $archivePath -DestinationPath $toolDirectory -Force
& $executablePath --version
if ($LASTEXITCODE -ne 0) { throw 'Falha ao executar o Rojo instalado.' }
Write-Host 'Rojo instalado no projeto. Para instalar o plugin do Studio:'
Write-Host '.\.tools\rojo\7.7.0\rojo.exe plugin install'
