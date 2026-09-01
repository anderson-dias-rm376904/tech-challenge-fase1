# Executa notebooks do pipeline a partir do 03_preprocessamento.
# Uso: .\run_notebooks.ps1

$ErrorActionPreference = "Stop"

# Evita "opcao" com acento quebrado no console Windows (cp1252).
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    $OutputEncoding = [System.Text.UTF8Encoding]::new()
    chcp 65001 | Out-Null
}
catch {
    # Continua mesmo se o console nao permitir alterar o code page.
}

$raiz = $PSScriptRoot
$preExecucao = Join-Path $raiz "pre_execucao.ps1"
$pastaNotebooks = Join-Path $raiz "notebooks"
$executor = Join-Path $raiz "run_notebook.py"

if (-not (Test-Path $preExecucao)) {
    throw "Arquivo de preparação não encontrado: $preExecucao"
}

if (-not (Test-Path $pastaNotebooks)) {
    throw "Pasta de notebooks não encontrada: $pastaNotebooks"
}

if (-not (Test-Path $executor)) {
    throw "Executor de notebook não encontrado: $executor"
}

# O dot sourcing mantém o ambiente virtual ativo neste processo.
. $preExecucao

Set-Location $raiz

# Ordem importa: "executar todos" usa esta sequência.
$notebooks = @(
    "03_preprocessamento.ipynb"
    "04_modelagem_treino.ipynb"
    "05_avaliacao_metricas.ipynb"
    "06_explicabilidade.ipynb"
    "07_discussao_demo.ipynb"
    "08_export_web.ipynb"
)

function Show-Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Executar notebooks do pipeline"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $notebooks.Count; $i++) {
        $numero = $i + 1
        Write-Host ("  [{0}] {1}" -f $numero, $notebooks[$i])
    }

    Write-Host ""
    Write-Host "  [T] Executar todos (na ordem)"
    Write-Host "  [S] Sair"
    Write-Host ""
}

function Invoke-Notebook {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Nome
    )

    $caminho = Join-Path $pastaNotebooks $Nome
    if (-not (Test-Path $caminho)) {
        throw "Notebook não encontrado: $caminho"
    }

    Write-Host ""
    Write-Host "Executando: $Nome ..." -ForegroundColor Yellow
    Write-Host ""

    python $executor $caminho
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar o notebook: $Nome"
    }

    Write-Host ""
    Write-Host "Concluído: $Nome" -ForegroundColor Green
}

function Invoke-AllNotebooks {
    $total = $notebooks.Count
    for ($i = 0; $i -lt $total; $i++) {
        $atual = $i + 1
        Write-Host ""
        Write-Host "===== Notebook $atual de $total =====" -ForegroundColor Cyan
        Invoke-Notebook -Nome $notebooks[$i]
    }

    Write-Host ""
    Write-Host "Todos os notebooks foram executados com sucesso." -ForegroundColor Green
}

while ($true) {
    Show-Menu
    $escolha = (Read-Host "Escolha uma opção").Trim()

    if ($escolha -match '^[Ss]$') {
        Write-Host "Encerrado."
        break
    }

    $executou = $false

    try {
        if ($escolha -match '^[Tt]$') {
            Invoke-AllNotebooks
            $executou = $true
        }
        elseif ($escolha -match '^\d+$') {
            $indice = [int]$escolha - 1
            if ($indice -lt 0 -or $indice -ge $notebooks.Count) {
                Write-Host "Opção inválida. Escolha de 1 a $($notebooks.Count)." -ForegroundColor Red
                continue
            }
            Invoke-Notebook -Nome $notebooks[$indice]
            $executou = $true
        }
        else {
            Write-Host "Opção inválida." -ForegroundColor Red
            continue
        }
    }
    catch {
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "A execução foi interrompida." -ForegroundColor Red
    }

    if (-not $executou) {
        continue
    }

    Write-Host ""
    $outra = (Read-Host "Deseja executar outro notebook? (S/N)").Trim()
    if ($outra -notmatch '^[Ss]$') {
        Write-Host "Encerrado."
        break
    }
}
