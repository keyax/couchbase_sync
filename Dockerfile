FROM keyax/ubuntu_lts

# MAINTAINER Couchbase Docker Team <docker@couchbase.com>
LABEL maintainer "yones.lebady AT gmail.com"
LABEL keyax.os "ubuntu core"
LABEL keyax.os.ver "14.04 trusty"
LABEL keyax.vendor "Keyax"
LABEL keyax.app "Sync Gateway 1.3.1 for Couchbase 4.5.0"
LABEL keyax.app.ver "2.1"

RUN apt-get update && \
    apt-get install -yq \
       runit \
#       wget \
#       python-httplib2 \
       chrpath \
       lsof lshw \
# disable transparent hugepages databases couchbase in Ubuntu
       sysfsutils \
       sysstat net-tools \
       numactl \
    && apt-get autoremove && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create Couchbase user with UID 1000 (necessary to match default boot2docker UID)
RUN groupadd -g 1000 couchbase && useradd couchbase -u 1000 -g couchbase -M

ENV CB_VERSION="4.5.0" \
    CB_RELEASE_URL="http://packages.couchbase.com/releases" \
    CB_PACKAGE="couchbase-server-community_4.5.0-ubuntu14.04_amd64.deb" \
    CB_SHA256="7682b2c90717ba790b729341e32ce5a43f7eacb5279f48f47aae165c0ec3a633" \
    PATH=$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install \
    LD_LIBRARY_PATH=":/opt/couchbase/lib"

# Install couchbase
RUN wget -N $CB_RELEASE_URL/$CB_VERSION/$CB_PACKAGE && \
    echo "$CB_SHA256  $CB_PACKAGE" | sha256sum -c - && \
    dpkg -i ./$CB_PACKAGE && rm -f ./$CB_PACKAGE

#    sync_gateway: unrecognized service
#    dpkg: error processing package couchbase-sync-gateway (--install):
# RUN cd /var/lib/dpkg \
# && wget http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.1/couchbase-sync-gateway-community_1.3.1-16_x86_64.deb \
RUN touch /var/cache/apt/archives/available
# RUN touch /var/lib/dpkg/available
COPY ./couchbase-sync-gateway-community_1.3.1-16_x86_64.deb  /var/cache/apt/archives/
# RUN for i in /var/lib/apt/lists/*_Packages; do dpkg --merge-avail "$i"; done
RUN apt-get couchbase-sync-gateway-community_1.3.1-16_x86_64.deb
# && dpkg --triggers-only couchbase-sync-gateway \
# && service sync_gateway start \
# && dpkg --configure couchbase-sync-gateway \
# && rm /couchbase-sync-gateway-community_1.3.1-16_x86_64.deb
# Create directory where the default config stores memory snapshots to disk
RUN mkdir -p /opt/couchbase-sync-gateway/data

# configure
ENV PATH /opt/couchbase-sync-gateway/bin:$PATH
## RUN ls

# copy the default config into the container
COPY sync_gateway_config.json /etc/sync_gateway/config.json


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
# remove packages installed by other packages and no longer needed purge configs
      && apt-get autoremove --purge --assume-yes \
#   remove the aptitude cache in /var/cache/apt/archives frees 0MB
      && apt-get clean \
# delete 27MB all the apt list files since they're big and get stale quickly
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# this forces "apt-get update" in dependent images, which is also good

# forward request and error logs to docker log collector
RUN mkdir -p /var/log/nginx && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
	  ln -sf /dev/stderr /var/log/nginx/error.log
COPY ./sites_available /etc/nginx/

## EXPOSE 80 443
## RUN nginx -g daemon off
## CMD ["nginx", "-g", "daemon off;"]



# Invoke the sync_gateway executable by default
ENTRYPOINT ["sync_gateway"]

# If user doesn't specify any args, use the default config
CMD ["/etc/sync_gateway/config.json"]

# Expose ports
#  port 4984: public port
EXPOSE 80 443 4984 4985
