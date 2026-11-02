#!/bin/sh
#SPDX-License-Identifier: MIT-0

# Generate CA Private Key
openssl genrsa -out CA.key 2048

# Generate Self-Signed CA Certificate (Valid for 10 years, typical for CA)
openssl req -x509 -new -nodes -key CA.key -sha256 -days 3650 -subj "/CN=SeaweedFS CA" -out CA.crt

# For volume01
openssl genrsa -out volume01.key 2048
openssl req -new -key volume01.key -subj "/CN=volume01.seaweedfs.domain.example" -out volume01.csr

# For master01
openssl genrsa -out master01.key 2048
openssl req -new -key master01.key -subj "/CN=master01.seaweedfs.domain.example" -out master01.csr

# For filer01
openssl genrsa -out filer01.key 2048
openssl req -new -key filer01.key -subj "/CN=filer01.seaweedfs.domain.example" -out filer01.csr

# For admin01
openssl genrsa -out admin01.key 2048
openssl req -new -key admin01.key -subj "/CN=admin01.seaweedfs.domain.example" -out admin01.csr

# For worker01
openssl genrsa -out worker01.key 2048
openssl req -new -key worker01.key -subj "/CN=worker01.seaweedfs.domain.example" -out worker01.csr

# For client01
openssl genrsa -out client01.key 2048
openssl req -new -key client01.key -subj "/CN=client01.seaweedfs.domain.example" -out client01.csr

# Sign volume01
openssl x509 -req -in volume01.csr -CA CA.crt -CAkey CA.key -CAcreateserial -out volume01.crt -days 730 -sha256

# Sign master01
openssl x509 -req -in master01.csr -CA CA.crt -CAkey CA.key -CAcreateserial -out master01.crt -days 730 -sha256

# Sign filer01
openssl x509 -req -in filer01.csr -CA CA.crt -CAkey CA.key -CAcreateserial -out filer01.crt -days 730 -sha256

# Sign admin01
openssl x509 -req -in admin01.csr -CA CA.crt -CAkey CA.key -CAcreateserial -out admin01.crt -days 730 -sha256

# Sign worker01
openssl x509 -req -in worker01.csr -CA CA.crt -CAkey CA.key -CAcreateserial -out worker01.crt -days 730 -sha256

# Sign client01
openssl x509 -req -in client01.csr -CA CA.crt -CAkey CA.key -CAcreateserial -out client01.crt -days 730 -sha256

rm -f *.csr *.srl
