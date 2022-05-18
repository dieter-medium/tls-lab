#!/bin/bash

SEMAPHORE=/tls-server/done.txt

if [ -f ${SEMAPHORE} ]; then
    echo "all files in place, do nothing"
    exit 0
fi

openssl rand -writerand /root/.rnd
mkdir -p /src/tls/{hosts,intermediate_1,intermediate_2,root_1,root_2}/{certs,csr,newcerts,private}
echo ${PASS_PHRASE} > tls/mypass

for INSTANCE in 1 2
do


  cp /dev/null tls/root_${INSTANCE}/index.txt

  openssl req -x509  -writerand -sha256 -days 1825 -newkey rsa:4096 -passout file:tls/mypass  -keyout tls/root_${INSTANCE}/private/rootCA.key -config openssl_ca_1.cnf -extensions v3_ca -out tls/root_${INSTANCE}/certs/rootCACert.pem -subj "/C=DE/ST=Berlin/L=Berlin/O=Acme/CN=Root ca"

# openssl rsa -noout -text -in tls/root_${INSTANCE}/private/rootCA.key -passin file:tls/mypass
done

for INSTANCE in 1 2 
do

cp /dev/null tls/intermediate_${INSTANCE}/index.txt

openssl req  -new -sha256 -newkey rsa:4096 -passout file:tls/mypass  -keyout tls/intermediate_${INSTANCE}/private/intermediate.cakey.key -config openssl_int${INSTANCE}.cnf  -out tls/intermediate_${INSTANCE}/csr/intermediate.csr.pem -subj "/C=DE/ST=Berlin/L=Berlin/O=Acme/CN=intermediate ${INSTANCE} ca"

# openssl rsa -noout -text -in tls/intermediate_${INSTANCE}/private/intermediate.cakey.key -passin file:tls/mypass

done

openssl ca -config openssl_ca_1.cnf -rand_serial -extensions v3_intermediate_ca -days 2650 -notext -batch -passin file:tls/mypass -in tls/intermediate_1/csr/intermediate.csr.pem -out tls/intermediate_1/certs/intermediate.cacert.pem

# openssl verify tls/intermediate_1/certs/intermediate.cacert.pem
# openssl verify  -CAfile tls/root_1/certs/rootCACert.pem tls/intermediate_1/certs/intermediate.cacert.pem

cat tls/intermediate_1/certs/intermediate.cacert.pem tls/root_1/certs/rootCACert.pem > tls/intermediate_1/certs/ca-chain-bundle_1.cert.pem

# openssl verify -CAfile tls/root_1/certs/rootCACert.pem tls/intermediate_1/certs/ca-chain-bundle_1.cert.pem


openssl ca -config openssl_int1.cnf -rand_serial -extensions v3_intermediate_ca -days 2650 -notext -batch -passin file:tls/mypass -in tls/intermediate_2/csr/intermediate.csr.pem -out tls/intermediate_2/certs/intermediate.cacert.pem

# openssl verify  -CAfile tls/root_1/certs/rootCACert.pem tls/intermediate_2/certs/intermediate.cacert.pem
# openssl verify  -CAfile tls/root_1/certs/rootCACert.pem -untrusted  tls/intermediate_1/certs/intermediate.cacert.pem tls/intermediate_2/certs/intermediate.cacert.pem

cat tls/intermediate_2/certs/intermediate.cacert.pem tls/intermediate_1/certs/ca-chain-bundle_1.cert.pem > tls/intermediate_2/certs/ca-chain-bundle_2.cert.pem

# openssl verify -CAfile tls/root_1/certs/rootCACert.pem tls/intermediate_2/certs/ca-chain-bundle_2.cert.pem
# openssl verify -CAfile tls/root_1/certs/rootCACert.pem -untrusted tls/intermediate_1/certs/ca-chain-bundle_1.cert.pem  tls/intermediate_2/certs/ca-chain-bundle_2.cert.pem

openssl req -nodes -new -sha256 -newkey rsa:4096 -keyout tls/hosts/service.key  -config openssl_req.cnf -out tls/hosts/service.csr.pem

# openssl req -text -noout -verify -in  tls/hosts/service.csr.pem

openssl ca -config openssl_int2.cnf -rand_serial -extensions v3_req -days 365 -notext -batch -passin file:tls/mypass -in tls/hosts/service.csr.pem -out tls/hosts/service.crt.pem

# openssl x509 -text -noout -in tls/hosts/service.crt.pem

openssl req -nodes -new -sha256 -newkey rsa:4096 -keyout tls/hosts/service5.key  -config openssl_req_5.cnf -out tls/hosts/service5.csr.pem
openssl ca -config openssl_ca_2.cnf -rand_serial -extensions v3_req -days 365 -notext -batch -passin file:tls/mypass -in tls/hosts/service5.csr.pem -out tls/hosts/service5.crt.pem

rm -rf /tls-server/*
rm -rf /tls-clients/*

cat tls/hosts/service.crt.pem tls/intermediate_2/certs/ca-chain-bundle_2.cert.pem > /tls-server/service-bundle.crt.pem
cat tls/hosts/service.crt.pem tls/intermediate_1/certs/ca-chain-bundle_1.cert.pem  > /tls-server/service-missing-cert-bundle.crt.pem
cat tls/hosts/service.crt.pem tls/root_1/certs/rootCACert.pem  tls/intermediate_2/certs/intermediate.cacert.pem tls/intermediate_1/certs/intermediate.cacert.pem > /tls-server/service-wrong-order-bundle.crt.pem
cat tls/hosts/service5.crt.pem tls/root_2/certs/rootCACert.pem > /tls-server/service5.crt.pem

cp tls/hosts/service*.key /tls-server/
cp tls/hosts/service.crt.pem /tls-server/

cp tls/**/newcerts/* /tls-clients/

ROOT_CA_1_NAME=$(cat /dev/urandom | tr -cd 'A-F0-9' | head -c 40).pem
ROOT_CA_2_NAME=$(cat /dev/urandom | tr -cd 'A-F0-9' | head -c 40).pem

cp tls/root_1/certs/rootCACert.pem /tls-clients/${ROOT_CA_1_NAME}
cp tls/root_2/certs/rootCACert.pem /tls-clients/${ROOT_CA_2_NAME}

touch ${SEMAPHORE}
