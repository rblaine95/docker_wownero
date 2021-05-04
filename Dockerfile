FROM ghcr.io/rblaine95/debian:10-slim AS builder

ARG WOWNERO_VERSION=0.9.3.3

WORKDIR /opt

RUN apt update && \
    apt upgrade -y && \
    apt install -y build-essential \
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
    make -j2 release-static-linux-x86_64

FROM ghcr.io/rblaine95/debian:10-slim

ENV PATH=/opt/wownero:${PATH}

RUN apt update && \
    apt upgrade -y && \
    apt install -y ca-certificates libkrb5-dev && \
    apt clean && \
    apt autoremove -y && \
    rm -rf /var/lib/apt && \
    useradd -ms /bin/bash wow && \
    mkdir -p /home/wow/.wownero && \
    chown -R wow:wow /home/wow/.wownero

COPY --from=builder /opt/wownero/build/Linux/_no_branch_/release/bin/* /opt/wownero/

USER wow

WORKDIR /home/wow

VOLUME /home/wow/.wownero

EXPOSE 18080 18081

ENTRYPOINT ["/opt/wownero/wownerod"]
