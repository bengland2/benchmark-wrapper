FROM registry.access.redhat.com/ubi8:latest
# based on github.com/jharriga/ccb/blob/master/Dockerfile
RUN dnf install -y --nodocs git python3-pip
RUN dnf install -y --nodocs procps-ng iproute net-tools ethtool nmap iputils
RUN ln -s /usr/bin/python3 /usr/bin/python

ENV TOP="/opt/snafu/"
ENV COSVERSION="0.4.2.c4"
ENV COSPKGNAME="${COSVERSION}.zip"
ENV COSWGET="https://github.com/intel-cloud/cosbench/releases/download/v${COSVERSION}/${COSPKGNAME}"

RUN dnf install -y wget unzip which nmap-ncat java && \
    dnf clean all

ADD ${COSWGET} ${TOP}

RUN unzip /${COSPKGNAME} -d ${TOP} \
    && mv /${COSVERSION} ${TOP}/cosbench \
    && rm -f /${COSPKGNAME} \
    && rm -f /bin/sh && ln -s /bin/bash /bin/sh

FROM centos:7
MAINTAINER John Harrigan <jharriga@redhat.com>

ENV COSVERSION="0.4.2.c4"
ENV COSPKGNAME="${COSVERSION}.zip"
ENV COSWGET="https://github.com/intel-cloud/cosbench/releases/download/v${COSVERSION}/${COSPKGNAME}"

RUN yum install -y wget unzip which nmap-ncat java && \
    yum clean all

ADD ${COSWGET} /

RUN unzip /${COSPKGNAME} -d / \
    && mv /${COSVERSION} ${TOP}/cosbench \
    && rm -f /${COSPKGNAME} \
    && rm -f /bin/sh && ln -s /bin/bash /bin/sh

ADD start-cosbench.sh ${TOP}/cosbench/

RUN chmod a+x ${TOP}/cosbench/*.sh

CMD ["${TOP}/cosbench/start-cosbench.sh"]

COPY . /opt/snafu/
RUN pip3 install -e /opt/snafu/
