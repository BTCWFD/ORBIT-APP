#!/bin/bash
set -e

# Configurar credenciales de KasmVNC (PoC: orbituser / orbitpassword)
mkdir -p /home/orbituser/.vnc
echo "orbitpassword" | vncpasswd -f > /home/orbituser/.vnc/passwd
chmod 600 /home/orbituser/.vnc/passwd

# Generar certificado auto-firmado para HTTPS (requerido por KasmVNC)
if [ ! -f /home/orbituser/.vnc/self.pem ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /home/orbituser/.vnc/self.pem \
        -out /home/orbituser/.vnc/self.pem \
        -subj "/C=US/ST=Orbit/L=Space/O=ProjectOrbit/CN=OrbitPlanet"
fi

# Iniciar code-server en segundo plano
code-server --auth none --bind-addr 127.0.0.1:8080 /home/orbituser &

# Ejecutar KasmVNC con XFCE
# -fg mantiene el proceso en primer plano para el contenedor
vncserver :1 -name "OrbitPlanet" -geometry 1280x720 -localhost no -SecurityTypes VNCAuth -PasswordFile /home/orbituser/.vnc/passwd

# Mantener vivo el log
tail -f /home/orbituser/.vnc/*.log
