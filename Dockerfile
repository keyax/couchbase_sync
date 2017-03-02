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

COPY ./sites_available /etc/nginx/

ENV NGINX_VERSION 1.10.3-1~trusty

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
	&& echo "deb http://nginx.org/packages/ubuntu/ trusty nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
            git \
            build-essential \
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
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

## EXPOSE 80 443

## CMD ["nginx", "-g", "daemon off;"]

COPY ./sites_available /etc/nginx/

ADD ./scripto  /home/repo/
WORKDIR /home/repo
RUN wget https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz
RUN tar -xvf go1.8.linux-amd64.tar.gz
RUN mv go /usr/local
RUN echo export GOROOT=/usr/local/go > ~/.profile
RUN echo export GOPATH=/home/repo > ~/.profile
RUN export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
RUN go version
RUN go env
RUN go get -u -t github.com/couchbase/sync-gateway
RUN ls
RUN git init
RUN ./bootstrap.sh
RUN ./build.sh
RUN ./test.sh

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
RUN mkdir -p /opt/couchbase-sync-gateway/data

# configure
ENV PATH /opt/couchbase-sync-gateway/bin:$PATH

# copy the default config into the container
COPY sync_gateway_config.json /etc/sync_gateway/config.json

# Invoke the sync_gateway executable by default
ENTRYPOINT ["sync_gateway"]

# If user doesn't specify any args, use the default config
CMD ["/etc/sync_gateway/config.json"]

# Expose ports
#  port 4984: public port
EXPOSE 80 443 4984 4985
