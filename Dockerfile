FROM keyax/ubuntu_lts

# MAINTAINER Couchbase Docker Team <docker@couchbase.com>
LABEL maintainer "yones.lebady AT gmail.com"
LABEL keyax.os "ubuntu core"
LABEL keyax.os.ver "14.04 trusty"
LABEL keyax.vendor "Keyax"
LABEL keyax.app "Sync Gateway 1.3.1 for Couchbase 4.5.0"
LABEL keyax.app.ver "2.1"

## RUN apt-get update && apt-get install --assume-yes --no-install-recommends nginx && \
# remove packages installed by other packages and no longer needed purge configs
##     apt-get autoremove --purge --assume-yes && \
#   remove the aptitude cache in /var/cache/apt/archives frees 0MB
##     apt-get clean && \
# delete 27MB all the apt list files since they're big and get stale quickly
##     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# this forces "apt-get update" in dependent images, which is also good

# RUN groupadd -r nodejs && useradd -r -g nodejs nodejs --create-home nodejs
# RUN groupadd --gid 1000 node \
#  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node


ENV NGINX_VERSION 1.10.3-1~trusty

# gpg: requesting key 7BD9BF62 from hkp server pgp.mit.edu : gpg: no writable keyring found: eof
#RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
RUN ["/bin/bash", "-c",  "set -ex; \
  gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62"] \
RUN echo "deb http://nginx.org/packages/ubuntu/ trusty nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
            apt-transport-https \
            ca-certificates \
						nginx=${NGINX_VERSION} \
						nginx-module-xslt \
						nginx-module-geoip \
						nginx-module-image-filter \
						nginx-module-perl \
						nginx-module-njs \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN mkdir -p /var/log/nginx && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
	  ln -sf /dev/stderr /var/log/nginx/error.log
COPY ./sites_available /etc/nginx/

## EXPOSE 80 443
## RUN nginx -g daemon off
## CMD ["nginx", "-g", "daemon off;"]

ADD ./scripto  /home/repo/
# RUN cd /home/repo
WORKDIR /home/repo

ENV GOPATH /home/repo
ENV GOROOT /usr/local/go
ENV PATH ${GOPATH}/bin:${GOROOT}/bin:$PATH
# RUN echo -e '#!/bin/sh\nexit 101' | install -m 755 /dev/stdin /usr/sbin/policy-rc.d && apt-get install **Package** && rm -f /usr/sbin/policy-rc.d
RUN echo -e '#!/bin/sh\nexit 101' | install -m 755 /dev/stdin /usr/sbin/policy-rc.d && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
              build-essential make cmake scons git \
              ruby autoconf automake autoconf-archive \
              gettext libtool flex bison \
              libbz2-dev libcurl4-openssl-dev \
#              libexpat-dev libncurses-dev && \
          &&  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
              PATH="$HOME/.linuxbrew/bin:$PATH"
              echo 'export PATH="$HOME/.linuxbrew/bin:$PATH"' >>~/.bash_profile
              wget https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz && \
              tar -xvf go1.8.linux-amd64.tar.gz && \
              mv ./go /usr/local/ && \
              echo export GOROOT=/usr/local/go >> ~/.profile && \
              echo export GOPATH=/home/repo >> ~/.profile && \
              echo PATH=$GOROOT/bin:$GOPATH/bin:$PATH >> ~/.profile && cat ~/.profile && \
              go version && go env
              rm -f /usr/sbin/policy-rc.d
#              git clone init && \
#              go get -u -t git@github.com:couchbase/sync-gateway.git && ls
# Building from Source

# RUN useradd --system -s /sbin/nologin syncuser
# USER syncuser
# RUN su node && cd /home/repo

RUN brew install repo && \
    mkdir ~/sync_gateway; cd ~/sync_gateway && \
    wget https://raw.githubusercontent.com/couchbase/sync_gateway/master/bootstrap.sh && \
    chmod +x bootstrap.sh && \
    ./bootstrap.sh && \
    ./build.sh && \
    ./test.sh

#     git init && \
#     git add && git commit -m "first commit" && \
#     git clone origin git@github.com:couchbase/sync-gateway.git && \
##    apt-get autoremove build-essential --assume-yes && \
#   remove dependent packages
##    apt-get purge build-essential && \
#   remove packages installed by other packages and no longer needed purge configs
##    apt-get autoremove --purge --assume-yes && \
    #   remove the aptitude cache in /var/cache/apt/archives frees 0MB
##    apt-get clean && \
    # delete 27MB all the apt list files since they're big and get stale quickly
##    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
##    rm tar -xvf go1.8.linux-amd64.tar.gz && \
##    rm -r /usr/local/go


#  91msync_gateway:    unrecognized service
#dpkg: error processing package couchbase-sync-gateway (--install):
#      subprocess installed post-installation script returned error exit status 1
# Install Sync Gateway set -x &&   \
## RUN set -x && \
##     mkdir -p /opt/couchbase-sync-gateway/bin && \
##     wget -N -O package.deb http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.0/couchbase-sync-gateway-community_1.3.0-274_x86_64.deb && \
##     dpkg -i package.deb && \
##     rm package.deb
# RUN apt-get update && \
# RUN wget https://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.1/couchbase-sync-gateway-community_1.3.1-16_x86_64.deb
# RUN dpkg -i couchbase-sync-gateway-community_1.3.1-16_x86_64.deb
# RUN service sync_gateway start
#    wget -q http://packages.couchbase.com/releases/couchbase-sync-gateway/1.2.1/couchbase-sync-gateway-community_1.2.1-4_x86_64.deb -O package.deb && \
#    dpkg -i package.deb && \
#    sudo apt-get install -f && \
#    service sync_gateway start && \
#    rm package.deb && \
#    rm -rf /var/lib/apt/lists/*


# Create directory where the default config stores memory snapshots to disk
# RUN mkdir -p /opt/couchbase-sync-gateway/data

# configure
ENV PATH /opt/couchbase-sync-gateway/bin:$PATH
## RUN ls

# copy the default config into the container
COPY sync_gateway_config.json /etc/sync_gateway/config.json

# Invoke the sync_gateway executable by default
ENTRYPOINT ["sync_gateway"]

# If user doesn't specify any args, use the default config
CMD ["/etc/sync_gateway/config.json"]

# Expose ports
#  port 4984: public port
EXPOSE 80 443 4984 4985
