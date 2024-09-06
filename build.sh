#!/bin/bash

MITHRIL_SIGNER_VERSION="2430.0"
MITHRIL_RELAY_VERSION="1.0.0"

docker build -f Dockerfile.signer \
    --build-arg VERSION=${MITHRIL_SIGNER_VERSION} \
    --tag lacepool/mithril-signer:${MITHRIL_SIGNER_VERSION} \
    --tag lacepool/mithril-signer:latest .

docker build -f Dockerfile.relay \
    --tag lacepool/mithril-relay:${MITHRIL_RELAY_VERSION} \
    --tag lacepool/mithril-relay:latest .
