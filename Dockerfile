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
ENV VERSION=v1.101106.0-rc.3
ENV CHECKSUM=0d4e95ec9d11f506a84e5b23d1c2b3c6c657612fa7ce1760e4df4b35ed1b52a7
ADD --checksum=sha256:$CHECKSUM $REPO/archive/$VERSION.tar.gz ./

RUN tar -xvf ./$VERSION.tar.gz --strip-components=1

RUN go run build/ci.go install -static ./cmd/geth

FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y jq curl supervisor && \
    rm -rf /var/lib/apt/lists
RUN mkdir -p /var/log/supervisor

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=op /app/op-batcher/bin/op-batcher ./
COPY --from=op /app/op-proposer/bin/op-proposer ./
COPY --from=geth /app/build/bin/geth ./
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY geth-entrypoint .
COPY op-node-entrypoint .
COPY goerli ./goerli

CMD ["/usr/bin/supervisord"]
