#!/bin/bash

tmp_file='TEMP.openssl.conf'
certs_dir="./certs"
current_hostname=$(hostname)

# Define your domain suffix here
DOMAIN_SUFFIX="${DOMAIN_SUFFIX:-myprivatedomain.local}"
# Construct the Fully Qualified Domain Name (FQDN)
FQDN="${current_hostname}.${DOMAIN_SUFFIX}"

ORG_NAME="${ORG_NAME:-MyPrivateOrg}"
IP_ADD2="${NGINX_SERVER_IP_ADDRESS:-127.0.0.2}"

mkdir -p $certs_dir

# 1. Create a temporary OpenSSL configuration file
cat >$tmp_file <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = SG
ST = Singapore
L = Singapore
O = $ORG_NAME
CN = $FQDN

[v3_req]
subjectAltName = @alt_names

[alt_names]
# Primary FQDN (Long Name)
DNS.1 = $FQDN
# Short Hostname (e.g., jakembp04)
DNS.2 = $current_hostname
# Localhost
DNS.3 = localhost
# IPs
IP.1 = 127.0.0.1
IP.2 = $IP_ADD2
EOF

# 2. Generate the certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $certs_dir/nginx.key \
    -out $certs_dir/nginx.crt \
    -config $tmp_file \
    -extensions v3_req

# 3. Cleanup
rm $tmp_file

echo "------------------------------------------------"
echo "Certificate generated in $certs_dir/"
echo "Organization: $ORG_NAME"
echo "Primary FQDN: $FQDN"
echo "SANs: $FQDN, $current_hostname, localhost, 127.0.0.1, $IP_ADD2"
echo "------------------------------------------------"
