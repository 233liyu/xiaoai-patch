
# docker build -t xiaoai-patch - < Dockerfile
# docker run -v $PWD:/xiaoai xiaoai-patch

FROM ubuntu:20.04

# set default for automatic tzdata package config
ENV TZ=Asia/Shanghai

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt update && apt install -y \
    unzip squashfs-tools \
    build-essential wget rsync gawk bison bc xxd \
    python3 python3-pip python3-dev python3-yaml \
    cmake autoconf autopoint autogen autoconf-archive \
    libtool libtool-bin \
    git pkg-config gettext intltool qemu-user-static \
    libgcrypt20-dev gperf libglib2.0-dev docbook-xsl \
    xsltproc libncurses-dev flex texinfo tcl \
    openjdk-11-jre openjdk-11-jdk && \
    apt-get clean


# RUN apt update && apt install -y qemu-system-arm
RUN python3 -m pip install meson ninja

RUN wget https://www.python.org/ftp/python/3.13.2/Python-3.13.2.tgz -O Python-3.13.2.tgz && \
    tar -zxvf Python-3.13.2.tgz && \
    cd Python-3.13.2 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    rm -rf /root/Python-3.13.2*


# RUN mkdir /opt/musl-cross-make
# COPY build.sh /opt/musl-cross-make

# RUN cd /opt/musl-cross-make && ./build.sh

VOLUME /xiaoai
WORKDIR /xiaoai

