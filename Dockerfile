FROM blacklabelops/centos
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG LETSENCRYPT_VERSION=latest
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

# Property permissions
ENV CONTAINER_USER=letsencrypt \
    CONTAINER_GROUP=letsencrypt


# install dev tools
RUN yum install -y epel-release && \
    yum install -y \
    golang \
    make \
    git \
    sudo \
    python-pip \
    python-tools \
    python-virtualenv \
    python-devel \
    augeas-libs \
    dialog \
    libffi-devel \
    openssl \
    openssl-devel \
    redhat-rpm-config \
    ca-certificates \
    mercurial && \
    pip install --upgrade pip && \
    yum clean all && rm -rf /var/cache/yum/* && \
    /usr/sbin/groupadd --gid $CONTAINER_GID $CONTAINER_GROUP && \
    /usr/sbin/useradd --uid $CONTAINER_UID --gid $CONTAINER_GID --create-home --shell /bin/bash $CONTAINER_GROUP

# install Jobber
ENV JOBBER_HOME=/opt/jobber
ENV JOBBER_LIB=$JOBBER_HOME/lib
ENV GOPATH=$JOBBER_LIB
ENV LETSENCRYPT_HOME=/opt/letsencrypt

RUN mkdir -p $JOBBER_HOME && \
    mkdir -p $JOBBER_LIB && \
    mkdir -p $LETSENCRYPT_HOME && \
    chown -R $CONTAINER_UID:$CONTAINER_GID $JOBBER_HOME $LETSENCRYPT_HOME && \
    cd $JOBBER_LIB && \
    go get github.com/dshearer/jobber;true && \
    make -C src/github.com/dshearer/jobber install DESTDIR=$JOBBER_HOME && \
    cp $JOBBER_LIB/bin/* /usr/bin && \
    cd $LETSENCRYPT_HOME && \
    git clone https://github.com/letsencrypt/letsencrypt && \
    if  [ "${LETSENCRYPT_VERSION}" != "latest" ]; \
      then cd letsencrypt && git checkout tags/v${LETSENCRYPT_VERSION} ; \
    fi && \
    /opt/letsencrypt/letsencrypt/letsencrypt-auto --no-self-upgrade --help

WORKDIR /opt/letsencrypt/letsencrypt
VOLUME ["/etc/letsencrypt"]
EXPOSE 443 80

COPY imagescripts/docker-entrypoint.sh /opt/jobber/docker-entrypoint.sh
ENTRYPOINT ["/opt/jobber/docker-entrypoint.sh"]
CMD ["jobberd"]
