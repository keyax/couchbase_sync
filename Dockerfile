FROM keyax/ubuntu_lts

# MAINTAINER Couchbase Docker Team <docker@couchbase.com>
LABEL maintainer "yones.lebady AT gmail.com"
LABEL keyax.os "ubuntu core"
LABEL keyax.os.ver "14.04 trusty"
LABEL keyax.vendor "Keyax"
LABEL keyax.app "Sync Gateway 1.3.1 for Couchbase 4.5.0"
LABEL keyax.app.ver "2.1"

# ENV PATH $PATH:/opt/couchbase-sync-gateway/bin   Centos

# RUN mkdir /opt/couchbase-sync-gateway/bin
# Create directory where the default config stores memory snapshots to disk
RUN mkdir /opt/couchbase-sync-gateway/data


# Install dependencies:
#  wget: for downloading Sync Gateway package installer
# RUN yum -y update && \
#    yum install -y \
#    wget && \
#    yum clean all

# Install Sync Gateway
# RUN set -x && \
#     wget -q http://packages.couchbase.com/releases/couchbase-sync-gateway/1.3.1/couchbase-sync-gateway-community_1.3.1-16_x86_64.deb && \
#    dpkg -i couchbase-sync-gateway-community_1.3.1-16_x86_64.deb && \
#    rm couchbase-sync-gateway-community_1.3.1-16_x86_64.deb
RUN wget -q http://packages.couchbase.com/releases/couchbase-sync-gateway/1.1.1/couchbase-sync-gateway-community_1.1.1-10_x86_64.deb -O package.deb && \
    dpkg -i package.deb && \
    rm package.deb

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
EXPOSE 4984 4985
