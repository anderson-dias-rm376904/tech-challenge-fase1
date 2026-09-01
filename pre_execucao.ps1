# Prepara o ambiente: ativa o .venv se necessario e instala requirements.txt.
# Usa Python 3.12. Para manter o venv ativo na sessao atual, execute com:
#   . .\pre_execucao.ps1

$ErrorActionPreference = "Stop"

$raiz = $PSScriptRoot
if (-not $raiz) {
    $raiz = Get-Location
}

$pythonVersao = "3.12"
$venvPath = Join-Path $raiz ".venv"
$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
$venvPython = Join-Path $venvPath "Scripts\python.exe"
$requirements = Join-Path $raiz "requirements.txt"

function Get-PythonMinorVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [string[]]$Arguments = @()
    )

    $output = & $Command @Arguments -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $output) {
        return $null
    }
    return ($output | Select-Object -Last 1).Trim()
}

function Resolve-Python312 {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $ver = Get-PythonMinorVersion -Command "py" -Arguments @("-3.12")
        if ($ver -eq "3.12") {
            return @{ Command = "py"; Arguments = @("-3.12") }
        }
    }

    foreach ($cmd in @("python3.12", "python")) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            $ver = Get-PythonMinorVersion -Command $cmd
            if ($ver -eq "3.12") {
                return @{ Command = $cmd; Arguments = @() }
            }
        }
    }

    throw "Python 3.12 nao encontrado. Instale o Python 3.12 e garanta 'py -3.12' ou 'python' 3.12 no PATH."
}

function Invoke-Python312 {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Python312,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & $Python312.Command @($Python312.Arguments + $Arguments)
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar Python 3.12 ($($Python312.Command) $($Python312.Arguments -join ' '))."
    }
}

$python312 = Resolve-Python312

$venvEsperado = $null
if (Test-Path $venvPath) {
    $venvEsperado = (Resolve-Path $venvPath).Path
}

$venvAtivo = $env:VIRTUAL_ENV
$jaAtivoNesteProjeto = $venvAtivo -and $venvEsperado -and (
    [string]::Equals($venvAtivo, $venvEsperado, [System.StringComparison]::OrdinalIgnoreCase)
)

if (Test-Path $venvPython) {
    $venvVer = Get-PythonMinorVersion -Command $venvPython
    if ($venvVer -ne $pythonVersao) {
        if ($jaAtivoNesteProjeto) {
            throw "O .venv ativo usa Python $venvVer. Desative o venv, apague a pasta .venv e execute o script de novo para recriar com Python $pythonVersao."
        }

        Write-Host "venv existente usa Python $venvVer. Recriando com Python $pythonVersao ..."
        Remove-Item -Recurse -Force $venvPath
        $jaAtivoNesteProjeto = $false
        $venvEsperado = $null
    }
}

if ($jaAtivoNesteProjeto) {
    Write-Host "venv ja esta ativo: $venvAtivo"
}
else {
    if (-not (Test-Path $activateScript)) {
        Write-Host "venv nao encontrado. Criando .venv com Python $pythonVersao em $venvPath ..."
        Invoke-Python312 -Python312 $python312 -Arguments @("-m", "venv", $venvPath)
        if (-not (Test-Path $activateScript)) {
            throw "Falha ao criar o venv. Verifique se o Python $pythonVersao esta instalado."
        }
    }

    Write-Host "Ativando venv: $venvPath"
    . $activateScript
}

$pythonAtivoVer = Get-PythonMinorVersion -Command "python"
if ($pythonAtivoVer -ne $pythonVersao) {
    throw "O interpretador ativo e Python $pythonAtivoVer, mas este projeto exige $pythonVersao."
}

if (-not (Test-Path $requirements)) {
    throw "Arquivo nao encontrado: $requirements"
}

Write-Host "Instalando pacotes de requirements.txt (Python $pythonVersao) ..."
python -m pip install -r $requirements

Write-Host "Ambiente pronto (Python $pythonVersao)."
