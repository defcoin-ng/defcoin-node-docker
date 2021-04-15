FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DEFCOIN_VERSION
LABEL build_version="version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="bashNinja"

# set environment variables
ENV HOME="/config"

ARG BUILD_PACKAGES="\
	build-essential \
	git \
	libtool \
	autotools-dev \
	automake \
	pkg-config \
	libssl-dev \
	libevent-dev \
	bsdmainutils \
	libminiupnpc-dev \
	libzmq3-dev \
	libboost-system-dev \
	libboost-filesystem-dev \
	libboost-chrono-dev \
	libboost-program-options-dev \
	libboost-test-dev \
	libboost-thread-dev"

# packages as variables

ARG RUNTIME_PACKAGES="wget"

RUN \
 apt-get update && \
 echo "**** install build packages ****" && \
 apt-get install -y \
 	--no-install-recommends \
	$BUILD_PACKAGES && \
 echo "**** install runtime packages ****" && \
 apt-get install -y \
 	--no-install-recommends \
	$RUNTIME_PACKAGES && \
 echo "**** download defcoin source ****" && \
 if [ -z ${DEFCOIN_VERSION+x} ]; then \
	DEFCOIN_VERSION=$(curl -sX GET "https://api.github.com/repos/miketweaver/Defcoin/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 export COMMIT_TAG="${DEFCOIN_VERSION}" && \
 echo "https://github.com/miketweaver/Defcoin/archive/${DEFCOIN_VERSION}.tar.gz" && \
 curl -o \
	/tmp/defcoin.tar.gz -L \
	"https://github.com/miketweaver/Defcoin/archive/${DEFCOIN_VERSION}.tar.gz" && \
 mkdir -p /tmp/defcoin && \
 tar xzf \
	/tmp/defcoin.tar.gz -C \
	/tmp/defcoin/ --strip-components=1

COPY install_db4.sh /tmp/defcoin/install_db4.sh

RUN \
 cd /tmp/defcoin && \
 echo "**** compile defcoin ****" && \
 /tmp/defcoin/install_db4.sh /tmp/defcoin && \
 ./autogen.sh && \
 ./configure \
	--prefix=/app/defcoin \
	LDFLAGS=-L/tmp/defcoin/db4/lib/ \
	CPPFLAGS=-I/tmp/defcoin/db4/include/ \
	--mandir=/usr/share/man \
	--disable-tests \
	--disable-bench  \
	--disable-ccache  \
	--with-gui=no \
	--with-utils \
	--with-libs \
	--with-daemon && \
 make -j8 && \
 mkdir -p /app/defcoin && \
 make install && \
 strip /app/defcoin/bin/defcoin-cli && \
 strip /app/defcoin/bin/defcoin-tx && \
 strip /app/defcoin/bin/defcoind && \
 strip /app/defcoin/lib/libbitcoinconsensus.a && \
 strip /app/defcoin/lib/libbitcoinconsensus.so.0.0.0 && \
 echo "**** cleanup ****" && \
 apt-get purge -y --auto-remove \
	$BUILD_PACKAGES && \
 rm -rf \
	/root/.cache \
	/tmp/* && \
 apt-get clean -y

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 1337
EXPOSE 1338
VOLUME /config
