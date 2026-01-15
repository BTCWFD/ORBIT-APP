<#
create_repo_with_gh_and_push.ps1
Crea un repositorio remoto en GitHub con la CLI 'gh', añade el remote 'origin' y hace push de la rama actual.
Uso:
  PS> Set-Location 'C:\Users\kamil\.gemini\antigravity\scratch\ORBIT-APP'
  PS> .\scripts\create_repo_with_gh_and_push.ps1
Requiere: git, gh
#>

try {
    Write-Host "== Crear repo remoto con gh y push ==" -ForegroundColor Cyan
    if (-not (Test-Path .git)) { Write-Error "Esto no parece un repo git (no existe .git)."; exit 1 }

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Error "La CLI 'gh' no está instalada."; exit 1 }

    $owner = Read-Host "Introduce el owner en GitHub (tu usuario u organización)"
    if ([string]::IsNullOrWhiteSpace($owner)) { Write-Error "Owner vacío. Abortando."; exit 1 }
    $repo = Read-Host "Introduce el nombre del repo remoto a crear"
    if ([string]::IsNullOrWhiteSpace($repo)) { Write-Error "Nombre de repo vacío. Abortando."; exit 1 }

    $visibility = Read-Host "Visibilidad (private/public) [private]"
    if ([string]::IsNullOrWhiteSpace($visibility)) { $visibility = 'private' }
    if ($visibility -ne 'private' -and $visibility -ne 'public') { Write-Error "Visibilidad inválida."; exit 1 }

    $branch = (git rev-parse --abbrev-ref HEAD) -replace "\n",""
    Write-Host "Rama actual: $branch"

    # Autenticación
    $auth = & gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "No autenticado en gh. Ejecuta: gh auth login" -ForegroundColor Yellow
        gh auth login --web
        if ($LASTEXITCODE -ne 0) { Write-Error "gh auth login falló. Abortando."; exit 1 }
    }

    # Crear repo
    $createArgs = "repo create $owner/$repo --$visibility --source=. --remote=origin --push"
    Write-Host "Ejecutando: gh $createArgs"
    gh repo create "$owner/$repo" --$visibility --source="." --remote=origin --push
    if ($LASTEXITCODE -ne 0) { Write-Error "gh repo create falló."; exit 1 }

    Write-Host "Push completado. Verifica en: https://github.com/$owner/$repo" -ForegroundColor Green
    git remote -v
    exit 0
}
catch {
    Write-Error "Error: $_"; exit 1
}

