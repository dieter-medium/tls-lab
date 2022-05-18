FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
  openssl \
  && rm -rf /var/lib/apt/lists/*

RUN bash -c 'mkdir -p /src/tls/{hosts,intermediate_1,intermediate_2,root}/{certs,csr,newcerts,private}'

COPY gen_cert.sh /src/
COPY openssl*.cnf /src/

ENV PASS_PHRASE "changeit"
WORKDIR /src