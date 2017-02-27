FROM keyax/ubuntu_lts

# MAINTAINER Couchbase Docker Team <docker@couchbase.com>
LABEL maintainer "yones.lebady AT gmail.com"
LABEL keyax.os "ubuntu core"
LABEL keyax.os.ver "14.04 trusty"
LABEL keyax.vendor "Keyax"
LABEL keyax.app "Sync Gateway 1.3.1 for Couchbase 4.5.0"
LABEL keyax.app.ver "2.1"

RUN apt-get update && apt-get install --assume-yes --no-install-recommends nginx && \
# remove packages installed by other packages and no longer needed purge configs
    apt-get autoremove --purge --assume-yes && \
#   remove the aptitude cache in /var/cache/apt/archives frees 0MB
    apt-get clean && \
# delete 27MB all the apt list files since they're big and get stale quickly
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# this forces "apt-get update" in dependent images, which is also good

COPY sites_available /etc/nginx/

# Install Sync Gateway
# RUN set -x && \
#     wget -q http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.1/couchbase-sync-gateway-community_1.3.1-16_x86_64.deb && \
#    dpkg -i couchbase-sync-gateway-community_1.3.1-16_x86_64.deb && \
#    rm couchbase-sync-gateway-community_1.3.1-16_x86_64.deb
RUN wget -q http://packages.couchbase.com/releases/couchbase-sync-gateway/1.1.1/couchbase-sync-gateway-community_1.1.1-10_x86_64.deb -O package.deb && \
    dpkg -i package.deb && \
    rm package.deb

# Create directory where the default config stores memory snapshots to disk
RUN mkdir /opt/couchbase-sync-gateway/data

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
