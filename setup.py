import os
import subprocess
import sys
import shutil

# Force utf-8 output for Windows consoles
sys.stdout.reconfigure(encoding='utf-8')

# Configuration
CERTS_DIR = os.path.join("cloud", "gateway", "certs")
ENV_FILE = ".env"

def print_step(message):
    print(f"\n{'='*50}")
    print(f"🚀 {message}")
    print(f"{'='*50}")

def check_command(command):
    if shutil.which(command):
        return command

    # Common Windows paths for OpenSSL
    if command == "openssl":
        common_paths = [
            r"C:\Program Files\Git\usr\bin\openssl.exe",
            r"C:\Program Files\OpenSSL-Win64\bin\openssl.exe",
            r"C:\Program Files (x86)\OpenSSL-Win32\bin\openssl.exe"
        ]
        for path in common_paths:
            if os.path.exists(path):
                print(f"ℹ️  Found {command} at {path}")
                return path

    print(f"❌ Error: '{command}' not found. Please install it and add it to your PATH.")
    return None

def check_prerequisites():
    print_step("Checking Prerequisites")
    required_commands = ["docker", "docker-compose", "openssl"]
    resolved_commands = {}
    missing = False
    
    for cmd in required_commands:
        path = check_command(cmd)
        if path:
            resolved_commands[cmd] = path
        else:
            missing = True
    
    if missing:
        sys.exit(1)
    print("✅ All prerequisites found.")
    return resolved_commands

def run_command(cmd_args, cwd=None, shell=False):
    try:
        subprocess.run(cmd_args, cwd=cwd, check=True, shell=shell)
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed: {' '.join(cmd_args)}")
        sys.exit(1)

def generate_certificates(openssl_cmd):
    print_step("Generating Certificates")
    
    if not os.path.exists(CERTS_DIR):
        os.makedirs(CERTS_DIR)
        print(f"📂 Created directory: {CERTS_DIR}")

    # Paths
    ca_key = os.path.join(CERTS_DIR, "ca.key")
    ca_crt = os.path.join(CERTS_DIR, "ca.crt")
    server_key = os.path.join(CERTS_DIR, "server.key")
    server_csr = os.path.join(CERTS_DIR, "server.csr")
    server_crt = os.path.join(CERTS_DIR, "server.crt")
    client_key = os.path.join(CERTS_DIR, "client.key")
    client_csr = os.path.join(CERTS_DIR, "client.csr")
    client_crt = os.path.join(CERTS_DIR, "client.crt")
    client_p12 = os.path.join(CERTS_DIR, "client.p12")

    # 1. Create CA
    print("🔐 Generating CA...")
    run_command([openssl_cmd, "genrsa", "-out", ca_key, "4096"])
    run_command([openssl_cmd, "req", "-x509", "-new", "-nodes", "-key", ca_key, 
                 "-sha256", "-days", "3650", "-out", ca_crt, "-subj", "/CN=Orbit Private CA"])

    # 2. Create Server Cert
    print("🖥️  Generating Server Certificate...")
    run_command([openssl_cmd, "genrsa", "-out", server_key, "2048"])
    run_command([openssl_cmd, "req", "-new", "-key", server_key, "-out", server_csr, "-subj", "/CN=localhost"])
    run_command([openssl_cmd, "x509", "-req", "-in", server_csr, "-CA", ca_crt, "-CAkey", ca_key, 
                 "-CAcreateserial", "-out", server_crt, "-days", "365", "-sha256"])

    # 3. Create Client Cert
    print("📱 Generating Client Certificate...")
    run_command([openssl_cmd, "genrsa", "-out", client_key, "2048"])
    run_command([openssl_cmd, "req", "-new", "-key", client_key, "-out", client_csr, "-subj", "/CN=OrbitCommander"])
    run_command([openssl_cmd, "x509", "-req", "-in", client_csr, "-CA", ca_crt, "-CAkey", ca_key, 
                 "-CAcreateserial", "-out", client_crt, "-days", "365", "-sha256"])

    # 4. Export Client Cert to PKCS#12
    print("📦 Exporting Client Certificate to PKCS#12...")
    # On Windows, openssl handling of pass: might be tricky in list format depending on shell, 
    # but subprocess list usually creates correct arguments.
    run_command([openssl_cmd, "pkcs12", "-export", "-out", client_p12, 
                 "-inkey", client_key, "-in", client_crt, "-certfile", ca_crt, 
                 "-passout", "pass:orbit123"])

    print(f"✅ Certificates generated in {CERTS_DIR}")

def configure_environment():
    print_step("Configuring Environment")
    if os.path.exists(ENV_FILE):
        print(f"ℹ️  {ENV_FILE} already exists. Skipping creation.")
        return

    print(f"📝 Creating {ENV_FILE} with default values...")
    content = """MCP_SECRET=orbit_secret_key_change_me
VNC_PASSWORD=orbit_vnc_password_change_me
OPENAI_API_KEY=sk-placeholder-please-update
"""
    with open(ENV_FILE, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✅ {ENV_FILE} created.")

def start_services():
    print_step("Starting Services with Docker Compose")
    print("🐳 Building and starting containers...")
    # Using shell=True for docker-compose might be safer on some Windows setups if looking for .exe or .cmd wrapper
    # But try without first.
    run_command(["docker-compose", "up", "--build", "-d"])
    print("✅ Services started.")

def post_install_instructions():
    print_step("Setup Complete!")
    print("To configure the Mobile Client:")
    print(f"1. Locate the file: {os.path.abspath(os.path.join(CERTS_DIR, 'client.p12'))}")
    print("2. Transfer this file to your mobile device.")
    print("3. Install it in Settings -> Security -> Encryption & Credentials -> Install a certificate -> VPN & app user certificate.")
    print("   Password: orbit123")
    print("\nTo run the client app locally:")
    print("   cd client/orbit_app")
    print("   flutter run")

def main():
    print("🪐 Starting Orbit App Setup...")
    commands = check_prerequisites()
    generate_certificates(commands["openssl"])
    configure_environment()
    start_services()
    post_install_instructions()

if __name__ == "__main__":
    main()
