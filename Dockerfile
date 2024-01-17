FROM golang:1.21-alpine AS go-builder
#ARG arch=x86_64

# See https://github.com/initia-labs/initiavm/releases
ENV LIBINITIAVM_VERSION=v0.2.0-beta.0

# this comes from standard alpine nightly file
#  https://github.com/rust-lang/docker-rust-nightly/blob/master/alpine3.12/Dockerfile
# with some changes to support our toolchain, etc
RUN set -eux; apk add --no-cache ca-certificates build-base;

RUN apk add git cmake
# NOTE: add these to run with LEDGER_ENABLED=true
# RUN apk add libusb-dev linux-headers

WORKDIR /code
COPY . /code/

# Install mimalloc
RUN git clone --depth 1 https://github.com/microsoft/mimalloc; cd mimalloc; mkdir build; cd build; cmake ..; make -j$(nproc); make install
ENV MIMALLOC_RESERVE_HUGE_OS_PAGES=4

# See https://github.com/initia-labs/initiavm/releases
ADD https://github.com/initia-labs/initiavm/releases/download/${LIBINITIAVM_VERSION}/libinitia_muslc.aarch64.a /lib/libinitia_muslc.aarch64.a
ADD https://github.com/initia-labs/initiavm/releases/download/${LIBINITIAVM_VERSION}/libinitia_muslc.x86_64.a /lib/libinitia_muslc.x86_64.a

# Highly recommend to verify the version hash
# RUN sha256sum /lib/libinitia_muslc.aarch64.a | grep a5e63292ec67f5bdefab51b42c3fbc3fa307c6aefeb6b409d971f1df909c3927
# RUN sha256sum /lib/libinitia_muslc.x86_64.a | grep 762307147bf8f550bd5324b7f7c4f17ee20805ff93dc06cc073ffbd909438320

# Copy the library you want to the final location that will be found by the linker flag `-linitia_muslc`
RUN cp /lib/libinitia_muslc.`uname -m`.a /lib/libinitia_muslc.a

# force it to use static lib (from above) not standard libinitia.so file
RUN LEDGER_ENABLED=false BUILD_TAGS=muslc LDFLAGS="-linkmode=external -extldflags \"-L/code/mimalloc/build -lmimalloc -Wl,-z,muldefs -static\"" make build

FROM alpine:3.15.4

RUN addgroup initia \
    && adduser -G initia -D -h /initia initia

WORKDIR /initia

COPY --from=go-builder /code/build/initiad /usr/local/bin/initiad

USER initia

# rest server
EXPOSE 1317
# grpc
EXPOSE 9090
# tendermint p2p
EXPOSE 26656
# tendermint rpc
EXPOSE 26657

CMD ["/usr/local/bin/initiad", "version"]
