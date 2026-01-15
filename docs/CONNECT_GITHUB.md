# Conectar este repositorio a GitHub

Este documento contiene comandos y scripts para crear un repositorio remoto en GitHub y empujar tu repo local.

Rutas en este proyecto:
- scripts/generate_ssh_and_add_remote.ps1  -> Genera clave SSH, la añade a GitHub y crea/empuja el repo.
- scripts/create_repo_with_gh_and_push.ps1 -> Crea repo con `gh` y empuja la rama actual.
- scripts/push_via_https_with_pat.ps1      -> Empuja usando HTTPS con un PAT temporal (no guarda el token).

Prerrequisitos
- git instalado y en PATH
- gh (GitHub CLI) instalado y autenticado para los scripts que lo usan
- ssh-keygen y ssh-agent (Windows)

Comprobaciones rápidas

```powershell
git --version
gh --version
gh auth status
git status
git branch --show-current
git remote -v
```

Flujos recomendados

1) SSH + gh (recomendado): ejecuta `scripts/generate_ssh_and_add_remote.ps1`. El script generará una clave SSH (si no existe), la añadirá a GitHub y creará el repo remoto haciendo push.

2) gh + push (si ya tienes SSH configurado o prefieres el helper de credenciales): ejecuta `scripts/create_repo_with_gh_and_push.ps1`.

3) HTTPS + PAT (temporal): ejecuta `scripts/push_via_https_with_pat.ps1` y pega tu PAT cuando te lo pida.

Seguridad
- Nunca incrustes PATs en URLs permanentes ni en ficheros del repo.
- Revoca PATs que ya no uses desde tu cuenta GitHub.
- Prefiere `gh auth login` o SSH keys para una experiencia más segura.

Si quieres, puedo ejecutar uno de los scripts por ti (dime cuál) o mostrar los comandos paso a paso para tu caso particular.

