ARG CONTRAIL_VERSION=4.0.1.0-32
ARG CONTRAIL_REGISTRY=localhost:5000
FROM ${CONTRAIL_REGISTRY}/contrail-base:${CONTRAIL_VERSION}

RUN yum install -y contrail-vrouter-agent contrail-vrouter contrail-vrouter-init && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    ldconfig

COPY 10-core-pattern.conf /etc/sysctl.d/
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-vrouter-agent"]

LABEL net.juniper.nodemgr.filter.name=contrail-vrouter-agent
LABEL net.juniper.contrail=agent
LABEL net.juniper.node=agent
