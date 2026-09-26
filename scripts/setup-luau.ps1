$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$directory = Join-Path $projectRoot '.tools/luau'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$archive = Join-Path $directory 'luau.zip'
Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/luau-lang/luau/releases/download/0.739/luau-windows.zip' -OutFile $archive
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne 'c5db8c3273f056416da224fd3cf20aa4644afb5af8498303b6b87ca0bd843ad1') {
    throw 'SHA256 inesperado para o pacote Luau 0.739.'
}
Expand-Archive -LiteralPath $archive -DestinationPath $directory -Force
Write-Host 'Luau 0.739 instalado para compilar scripts e executar os testes locais.'
