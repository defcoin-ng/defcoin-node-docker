FROM ghcr.io/linuxserver/baseimage-ubuntu:focal

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DEFCOIN_VERSION
LABEL build_version="version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="bashNinja"

# set environment variables
ENV HOME="/config"

ARG REPO="mspicer/Defcoin"

ARG BUILD_PACKAGES="\
	build-essential \
	git \
	python \
	libtool \
	autotools-dev \
	automake \
	pkg-config \
	libssl-dev \
	libevent-dev \
	bsdmainutils \
	sudo"

# packages as variables

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
	DEFCOIN_VERSION=$(curl -sX GET "https://api.github.com/repos/${REPO}/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 export COMMIT_TAG="${DEFCOIN_VERSION}" && \
 echo "https://github.com/${REPO}/archive/${DEFCOIN_VERSION}.tar.gz" && \
 curl -o \
	/tmp/defcoin.tar.gz -L \
	"https://github.com/${REPO}/archive/${DEFCOIN_VERSION}.tar.gz" && \
 mkdir -p /tmp/defcoin && \
 tar xzf \
	/tmp/defcoin.tar.gz -C \
	/tmp/defcoin/ --strip-components=1

COPY install_db4.sh /tmp/defcoin/install_db4.sh

RUN \
 cd /tmp/defcoin && \
 echo "**** compile defcoin ****" && \
 cd depends && \
 chown abc:abc -R /tmp/defcoin/ && \
 sudo -u abc make HOST=x86_64-pc-linux-gnu -j8 && \
 cd /tmp/defcoin && \
 ./autogen.sh && \
 CONFIG_SITE=$PWD/depends/x86_64-pc-linux-gnu/share/config.site ./configure \
	--prefix=/app/defcoin \
	--mandir=/usr/share/man \
	--disable-tests \
	--disable-bench  \
	--disable-ccache  \
	--with-gui=no \
	--with-utils \
	--with-libs \
	--with-daemon && \
 make HOST=x86_64-pc-linux-gnu -j8 && \
 mkdir -p /app/defcoin && \
 make install && \
 touch /tester && \
 strip /app/defcoin/bin/defcoin-cli && \
 strip /app/defcoin/bin/defcoin-tx && \
 strip /app/defcoin/bin/defcoind && \
 strip /app/defcoin/lib/libbitcoinconsensus.a && \
 strip /app/defcoin/lib/libbitcoinconsensus.so.0.0.0 && \
 echo "**** cleanup ****" && \
 export SUDO_FORCE_REMOVE=yes && \
 apt-get purge -y --auto-remove \
	$BUILD_PACKAGES && \
 rm -rf \
	/root/.cache && \
 apt-get clean -y

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 1337
EXPOSE 1338
VOLUME /config
