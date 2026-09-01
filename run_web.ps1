param(
    [ValidateRange(1, 65535)]
    [int]$Port
)

$ErrorActionPreference = "Stop"

$raiz = $PSScriptRoot
$preExecucao = Join-Path $raiz "pre_execucao.ps1"
$aplicacao = Join-Path $raiz "src\web\app.py"
$portasPadrao = @(8010, 8011, 8012, 8013)
$portaFoiInformada = $PSBoundParameters.ContainsKey("Port")

if (-not (Test-Path $preExecucao)) {
    throw "Arquivo de preparação não encontrado: $preExecucao"
}

if (-not (Test-Path $aplicacao)) {
    throw "Aplicação web não encontrada: $aplicacao"
}

# O dot sourcing mantém o ambiente virtual ativo neste processo.
. $preExecucao

$propriedadesRede = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
$portasEmUso = @(
    $propriedadesRede.GetActiveTcpListeners() |
        Select-Object -ExpandProperty Port -Unique
)

if ($portaFoiInformada) {
    if ($portasEmUso -contains $Port) {
        Write-Host ""
        Write-Host "A porta preferida $Port está ocupada." -ForegroundColor Red
        Write-Host "Escolha outra porta livre, por exemplo:"
        Write-Host "  .\run_web.ps1 -Port 8020" -ForegroundColor Yellow
        exit 1
    }

    $portaSelecionada = $Port
}
else {
    $portaSelecionada = $portasPadrao |
        Where-Object { $portasEmUso -notcontains $_ } |
        Select-Object -First 1

    if ($null -eq $portaSelecionada) {
        $listaPortas = $portasPadrao -join ", "
        Write-Host ""
        Write-Host "Não foi possível iniciar o projeto web." -ForegroundColor Red
        Write-Host "Todas as portas padrão estão ocupadas: $listaPortas."
        Write-Host "Informe uma porta livre de sua preferência, por exemplo:"
        Write-Host "  .\run_web.ps1 -Port 8020" -ForegroundColor Yellow
        exit 1
    }
}

Set-Location $raiz

Write-Host ""
Write-Host "Iniciando o dashboard em http://127.0.0.1:$portaSelecionada" -ForegroundColor Green
Write-Host "Documentação da API: http://127.0.0.1:$portaSelecionada/docs"
Write-Host "Pressione Ctrl+C para encerrar."
Write-Host ""

python -m uvicorn src.web.app:app `
    --host 127.0.0.1 `
    --port $portaSelecionada `
    --reload
