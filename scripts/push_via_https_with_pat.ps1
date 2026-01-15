<#
push_via_https_with_pat.ps1
Empuja la rama actual al remote 'origin' usando HTTPS y un PAT temporal de forma segura (no guarda el token en disco).
Uso:
  PS> Set-Location 'C:\Users\kamil\.gemini\antigravity\scratch\ORBIT-APP'
  PS> .\scripts\push_via_https_with_pat.ps1
Requiere: git
#>

function SecureStringToPlainText([System.Security.SecureString]$secureString) {
    if ($secureString -eq $null) { return $null }
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    try { [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

try {
    Write-Host "== Push HTTPS usando PAT temporal ==" -ForegroundColor Cyan
    if (-not (Test-Path .git)) { Write-Error "No se encontró .git en el directorio actual."; exit 1 }

    $branch = (git rev-parse --abbrev-ref HEAD) -replace "\n",""
    Write-Host "Rama actual: $branch"

    $remote = git remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remote)) {
        Write-Error "No existe remote 'origin' configurado. Añade origin primero o usa otro script."; exit 1
    }

    Write-Host "Introduce tu Personal Access Token (PAT). Sólo se usará en esta sesión." -ForegroundColor Yellow
    $secure = Read-Host -AsSecureString "PAT (oculto)"
    $pat = SecureStringToPlainText $secure
    if ([string]::IsNullOrWhiteSpace($pat)) { Write-Error "Token vacío."; exit 1 }

    # Ejecutar push con header temporal
    Write-Host "Ejecutando git push usando http.extraheader (token en memoria)..."
    git -c http.extraheader="AUTHORIZATION: bearer $pat" push -u origin $branch
    $exit = $LASTEXITCODE

    # Limpiar variable en memoria (recomendación)
    Remove-Variable pat -ErrorAction SilentlyContinue

    if ($exit -ne 0) { Write-Error "git push falló. Revisa permisos del token y la URL del remote."; exit $exit }

    Write-Host "Push completado correctamente." -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Error: $_"; exit 1
}

