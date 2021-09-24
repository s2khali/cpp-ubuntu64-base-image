# Pulled the majority of the base file from:
# https://github.com/A-j-K/base-dockers/blob/master/aws-sdk-cpp/Dockerfile

FROM ubuntu:latest

ENV CMAKE_VER "3.16"
ENV CMAKE_VERSION "3.16.6"

ENV DEBIAN_FRONTEND noninteractive

# These libs are required by the AWS C++ SDK and should remain inside
# of any child container using this image as a base image.
ENV AWS_SDK_CPP_REQUIRED_LIBS \
	libssl-dev \
	libcurl4-openssl-dev \
	curl \
	libxml2 \
	libc-dev \
	libpulse-dev \
	ca-certificates 

# These installs are required for compiling the AWS C++ SDK. It is probable
# that any child image will also need these to compile their projects. But as
# with USEFUL_TOOLS below, could be removed from the final release build image
# to save image space.
ENV AWS_SDK_CPP_BUILD_TOOLS \
	build-essential \
	autoconf \
	g++ \
	gcc \
	make 
  
# If you use this container as a base image then the following
# installs can be removed from the final image to save image space.
# I install them here as they are useful during development.
ENV AWS_SDK_CPP_USEFUL_TOOLS \
	apt-utils \
	vim \
	wget \
	mysql-client \
	xz-utils \
	file \
	mlocate \
	unzip \
	git

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	$AWS_SDK_CPP_BUILD_TOOLS \
	$AWS_SDK_CPP_REQUIRED_LIBS \
	$AWS_SDK_CPP_USEFUL_TOOLS \
	--no-install-recommends \
	&& mkdir -p /tmp/build && cd /tmp/build
RUN curl -sSL https://cmake.org/files/v${CMAKE_VER}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz > cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz \
	&& tar -v -zxf cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz \
	&& rm -f cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz \
	&& cd cmake-${CMAKE_VERSION}-Linux-x86_64 \
	&& cp -rp bin/* /usr/local/bin/ \
	&& cp -rp share/* /usr/local/share/ \
	&& cd / && rm -rf /tmp/build \
	&& mkdir -p /tmp/build/build && cd /tmp/build
RUN git clone --recurse-submodules https://github.com/aws/aws-sdk-cpp \
	&& cd /tmp/build/build
RUN cmake \
		-DCMAKE_BUILD_TYPE=Release \
		-DENABLE_TESTING=OFF \
		-DAUTORUN_UNIT_TESTS=OFF \
        -DBUILD_ONLY="rds" \
		../aws-sdk-cpp \
	&& make \
	&& make install \
	&& make clean \
	&& cd / \
	&& rm -rf /tmp/build \
	&& rm -rf /var/lib/apt/lists/* 
