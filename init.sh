# Generate keys
openssl genrsa -out /tmp/tokenKeypair.pem 2048
openssl rsa -in /tmp/tokenKeypair.pem -outform PEM -pubout -out /tmp/tokenPublicKey.pem

# Generate MDS login file
echo 'mds:mds1' > /tmp/login.properties
