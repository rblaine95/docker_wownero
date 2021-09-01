FROM ghcr.io/rblaine95/debian:10-slim AS builder

ARG WOWNERO_VERSION=0.10.1.0

WORKDIR /opt

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y build-essential \
        cmake pkg-config libboost-all-dev \
        libssl-dev libzmq3-dev libunbound-dev \
        libsodium-dev libunwind8-dev liblzma-dev \
        libreadline6-dev libldns-dev libexpat1-dev \
        doxygen graphviz libpgm-dev qttools5-dev-tools \
        libhidapi-dev libusb-1.0-0-dev libprotobuf-dev \
        protobuf-compiler libudev-dev git && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN git clone --recursive https://git.wownero.com/wownero/wownero.git -b v${WOWNERO_VERSION}

RUN cd wownero && \
    make -j2 release-static-linux-$(uname -m)

FROM ghcr.io/rblaine95/debian:11-slim

ENV PATH=/opt/wownero:${PATH}

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y tini ca-certificates libkrb5-dev && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt && \
    useradd -ms /bin/bash wow && \
    mkdir /opt/bitwownero && \
    ln -s /opt/bitwownero /home/wow/.wownero && \
    chown -R wow:wow /home/wow/.wownero && \
    chown -R wow:wow /opt/bitwownero

COPY --from=builder /opt/wownero/build/Linux/_no_branch_/release/bin/* /opt/wownero/

USER wow
WORKDIR /home/wow
VOLUME /opt/bitwownero
EXPOSE 34567 34568

ENTRYPOINT ["tini", "--", "/opt/wownero/wownerod"]
