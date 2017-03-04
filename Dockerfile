FROM keyax/ubuntu_lts

# MAINTAINER Couchbase Docker Team <docker@couchbase.com>
LABEL maintainer "yones.lebady AT gmail.com"
LABEL keyax.os "ubuntu core"
LABEL keyax.os.ver "14.04 trusty"
LABEL keyax.vendor "Keyax"
LABEL keyax.app "Sync Gateway 1.3.1 for Couchbase 4.5.0"
LABEL keyax.app.ver "2.1"

#    sync_gateway: unrecognized service
#    dpkg: error processing package couchbase-sync-gateway (--install):
# RUN cd /var/lib/dpkg \
RUN wget http://packages.couchbase.com/releases/couchbase-sync-gateway/1.1.1/couchbase-sync-gateway-community_1.1.1-10_x86_64.deb \
 && dpkg -i couchbase-sync-gateway-community_1.1.1-10_x86_64.deb \
 && rm -f couchbase-sync-gateway-community_1.1.1-10_x86_64.deb
### RUN touch /var/cache/apt/archives/available
# RUN touch /var/lib/dpkg/available
### COPY ./couchbase-sync-gateway-community_1.3.1-16_x86_64.deb  /var/cache/apt/archives/
# RUN for i in /var/lib/apt/lists/*_Packages; do dpkg --merge-avail "$i"; done
### RUN apt-get couchbase-sync-gateway-community_1.3.1-16_x86_64.deb
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

# Invoke the sync_gateway executable by default
ENTRYPOINT ["sync_gateway"]

# If user doesn't specify any args, use the default config
CMD ["/etc/sync_gateway/config.json"]

# Expose ports
#  port 4984: public port
EXPOSE 4984 4985
