# syntax=docker/dockerfile:1-labs
FROM golang:1.19 as op

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/optimism
ENV VERSION=v1.1.0
ENV CHECKSUM=f84bbf1b069dc2f2570c3f6989ae464cd3ede12faf7f4f6796e97380de7f8923
ADD --checksum=sha256:$CHECKSUM $REPO/archive/op-node/$VERSION.tar.gz ./

RUN tar -xvf ./$VERSION.tar.gz --strip-components=1

RUN cd op-node && \
    make op-node

RUN cd op-batcher && \
    make op-batcher

RUN cd op-proposer && \
    make op-proposer

FROM golang:1.19 as geth

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/op-geth
ENV VERSION=v1.101105.3
ENV CHECKSUM=1749e8a8aaaccfc8a03e4983f263cd9834788039c9f2187c93af4a27a08dc199
ADD --checksum=sha256:$CHECKSUM $REPO/archive/$VERSION.tar.gz ./

RUN tar -xvf ./$VERSION.tar.gz --strip-components=1

RUN go run build/ci.go install -static ./cmd/geth

FROM golang:1.19

RUN apt-get update && \
    apt-get install -y jq curl && \
    rm -rf /var/lib/apt/lists

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=op /app/op-batcher/bin/op-batcher ./
COPY --from=op /app/op-proposer/bin/op-proposer ./
COPY --from=geth /app/build/bin/geth ./
COPY geth-entrypoint .
COPY op-node-entrypoint .
COPY goerli ./goerli
