# Project Orbit - Planet Server (Standardized PoC)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=orbituser

# Install core and GUI components
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-goodies \
    dbus-x11 x11-xserver-utils \
    sudo curl git wget openssl \
    python3 python3-pip node.js npm \
    && apt-get clean

# Install python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Install KasmVNC
RUN wget https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb \
    && apt-get update && apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb \
    && rm kasmvncserver_jammy_1.3.1_amd64.deb

# Setup User
RUN useradd -m -s /bin/bash orbituser && \
    echo "orbituser:orbitpassword" | chpasswd && \
    echo "orbituser:orbitpassword" | chpasswd
# REMOVED: adduser orbituser sudo (Security Hardening)

# Setup VS Code (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# App directories
WORKDIR /home/orbituser
COPY entrypoint.sh /entrypoint.sh
COPY mcp_server.py /home/orbituser/mcp_server.py
RUN chmod +x /entrypoint.sh

USER orbituser
EXPOSE 6901 8080

ENTRYPOINT ["/entrypoint.sh"]
