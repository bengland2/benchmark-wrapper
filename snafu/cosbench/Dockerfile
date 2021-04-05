FROM registry.access.redhat.com/ubi8:latest
# based on github.com/jharriga/ccb/blob/master/Dockerfile
RUN dnf install -y --nodocs git unzip 
RUN ln -s /usr/bin/python3 /usr/bin/python

ENV TOP="/opt/snafu/"
ENV COSVERSION="0.4.2.c4"
ENV COSPKGNAME="${COSVERSION}.zip"
ENV COSWGET="https://github.com/Nexenta/cosbench/archive/refs/tags/v${COSVERSION}.zip"

COPY . ${TOP}
WORKDIR ${TOP}
RUN git clone https://github.com/jharriga/ccb
ADD ${COSWGET} ${TOP}
RUN dnf install -y unzip

RUN unzip v${COSPKGNAME}
RUN mv cosbench-${COSVERSION} cosbench
RUN rm -f ${COSPKGNAME}
RUN rm -f /bin/sh && ln -s /bin/bash /bin/sh

RUN mv -v ccb/start-cosbench.sh ${TOP}/cosbench/

RUN chmod a+x ${TOP}/cosbench/*.sh

CMD ["${TOP}/cosbench/start-cosbench.sh"]


RUN dnf install -y procps-ng iproute net-tools ethtool nmap iputils java python3-pip
#RUN dnf clean all

RUN pip3 install -e /opt/snafu/
