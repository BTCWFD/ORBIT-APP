<#
}
    Write-Error "Error: $_"; exit 1
catch {
}
    exit 0
    git remote -v
    Write-Host "Repositorio creado y push realizado con éxito." -ForegroundColor Green

    }
        Write-Error "La creación del repo o el push falló. Revisa la salida previa."; exit 1
    if ($LASTEXITCODE -ne 0) {
    gh repo create "$owner/$repo" --private --source="." --remote=origin --push
    Write-Host "Creando repo remoto en GitHub y añadiendo remote origin (si no existe)." -ForegroundColor Cyan
    # Crear repo remoto con gh y hacer push

    }
        Write-Warning "gh ssh-key add devolvió un error (es posible que la clave ya exista). Continuando..."
    if ($LASTEXITCODE -ne 0) {
    gh ssh-key add $pubPath --title $title
    $title = "laptop-$(Get-Date -Format yyyyMMdd)"
    Write-Host "Subiendo clave pública a GitHub (título: 'laptop-<fecha>')..."

    if (-not $pubKey) { Write-Error "No se encontró la clave pública en $pubPath"; exit 1 }
    $pubKey = Get-Content -Raw -Path $pubPath
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Error "gh no disponible."; exit 1 }
    # Añadir clave pública a GitHub via gh

    ssh-add $keyPath 2>$null | Out-Null
    Start-Process -FilePath powershell -ArgumentList '-NoProfile','-Command','Start-Service ssh-agent' -Verb RunAs -WindowStyle Hidden -ErrorAction SilentlyContinue
    Write-Host "Iniciando ssh-agent y añadiendo clave..."
    # Iniciar ssh-agent y añadir clave

    } else { Write-Host "Clave SSH existente encontrada en $keyPath" -ForegroundColor Green }
        if ($LASTEXITCODE -ne 0) { Write-Error "Falló la generación de la clave SSH."; exit 1 }
        ssh-keygen -t ed25519 -f $keyPath -N "" -C "$($env:USERNAME)@$(hostname)"
        Write-Host "No existe clave SSH en $keyPath. Generando nueva clave (ed25519) sin passphrase..." -ForegroundColor Yellow
    if (-not (Test-Path $keyPath)) {

    $pubPath = "$keyPath.pub"
    $keyPath = Join-Path $sshDir 'id_ed25519'
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
    $sshDir = Join-Path $env:USERPROFILE '.ssh'
    # Ruta de clave SSH

    } else { Write-Host "gh ya autenticado." -ForegroundColor Green }
        if ($LASTEXITCODE -ne 0) { Write-Error "gh auth login falló o fue cancelado. Autentícate y vuelve a ejecutar."; exit 1 }
        gh auth login --web
        Write-Host "No estás autenticado en gh. Ejecutando 'gh auth login'..." -ForegroundColor Yellow
    if ($LASTEXITCODE -ne 0) {
    $authStatus = & gh auth status 2>&1

    }
        Write-Error "La CLI 'gh' no está instalada o no está en PATH. Instálala: https://cli.github.com/"; exit 1
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    # Comprobar gh instalado y autenticado

    if ([string]::IsNullOrWhiteSpace($repo)) { Write-Error "Nombre de repo vacío. Abortando."; exit 1 }
    $repo = Read-Host "Introduce el nombre del repo remoto a crear (ej: ORBIT-APP)"
    if ([string]::IsNullOrWhiteSpace($owner)) { Write-Error "Owner vacío. Abortando."; exit 1 }
    $owner = Read-Host "Introduce el owner en GitHub (tu usuario u organización)"
    # Pedimos owner/repo

    Write-Host "Rama actual: $branch"
    $branch = (git rev-parse --abbrev-ref HEAD) -replace "\n",""

    }
        Write-Error "Esto no parece un repositorio git (no existe .git). Inicializa o posicionate en la carpeta del repo local y vuelve a ejecutar."; exit 1
    if (-not (Test-Path .git)) {

    Write-Host "Directorio actual: $cwd"
    $cwd = Get-Location

    Write-Host "== Conectar repo local a GitHub (SSH) ==" -ForegroundColor Cyan
try {

#>
Requiere: git, gh (GitHub CLI), ssh-keygen, ssh-agent (Windows)

  PS> .\scripts\generate_ssh_and_add_remote.ps1
  PS> Set-Location 'C:\Users\kamil\.gemini\antigravity\scratch\ORBIT-APP'
Uso: Ejecuta desde la raíz de tu repo local:
Genera (si es necesario) una clave SSH, la añade a tu cuenta de GitHub (vía gh CLI), crea el repo remoto y hace push.
generate_ssh_and_add_remote.ps1

