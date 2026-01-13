# Project Orbit - Planet Server (PoC)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    sudo \
    curl \
    git \
    wget \
    python3 \
    python3-pip \
    nodejs \
    npm \
    gpg \
    && apt-get clean

# Install KasmVNC
RUN wget https://github.com/kasmtech/KasmVNC/releases/download/v1.3.1/kasmvncserver_jammy_1.3.1_amd64.deb \
    && apt-get update && apt-get install -y ./kasmvncserver_jammy_1.3.1_amd64.deb \
    && rm kasmvncserver_jammy_1.3.1_amd64.deb

# Create a user
RUN useradd -m -s /bin/bash orbituser && \
    echo "orbituser:orbitpassword" | chpasswd && \
    adduser orbituser sudo

# Setup VS Code (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

USER orbituser
WORKDIR /home/orbituser

# Expose KasmVNC port
EXPOSE 6901

# Default command (Simplified for PoC, usually requires more config for KasmVNC)
# In a real scenario, we'd use a startup script to launch XFCE and KasmVNC
CMD ["/usr/bin/vncserver", "-select-column", "1", "-interface", "0.0.0.0", "-websocket-port", "6901", "-no-httpd"]
