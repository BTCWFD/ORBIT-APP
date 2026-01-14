#!/bin/bash
set -e

# Configuration
CERTS_DIR="./cloud/gateway/certs"
mkdir -p $CERTS_DIR

# 1. Create CA (Certificate Authority)
echo "🔐 Generando CA..."
openssl genrsa -out $CERTS_DIR/ca.key 4096
openssl req -x509 -new -nodes -key $CERTS_DIR/ca.key -sha256 -days 3650 -out $CERTS_DIR/ca.crt -subj "/CN=Orbit Private CA"

# 2. Create Server Cert (Validated by CA)
echo "🖥️  Generando Certificado de Servidor..."
openssl genrsa -out $CERTS_DIR/server.key 2048
openssl req -new -key $CERTS_DIR/server.key -out $CERTS_DIR/server.csr -subj "/CN=localhost"
openssl x509 -req -in $CERTS_DIR/server.csr -CA $CERTS_DIR/ca.crt -CAkey $CERTS_DIR/ca.key -CAcreateserial -out $CERTS_DIR/server.crt -days 365 -sha256

# 3. Create Client Cert (For Flutter App)
echo "📱 Generando Certificado de Cliente..."
openssl genrsa -out $CERTS_DIR/client.key 2048
openssl req -new -key $CERTS_DIR/client.key -out $CERTS_DIR/client.csr -subj "/CN=OrbitCommander"
openssl x509 -req -in $CERTS_DIR/client.csr -CA $CERTS_DIR/ca.crt -CAkey $CERTS_DIR/ca.key -CAcreateserial -out $CERTS_DIR/client.crt -days 365 -sha256

# 4. Export Client Cert to PKCS#12 (For Mobile Import)
openssl pkcs12 -export -out $CERTS_DIR/client.p12 -inkey $CERTS_DIR/client.key -in $CERTS_DIR/client.crt -certfile $CERTS_DIR/ca.crt -passout pass:orbit123

echo "✅ Certificados generados en $CERTS_DIR"
echo "👉 Importa 'client.p12' (pass: orbit123) en tu dispositivo móvil."
