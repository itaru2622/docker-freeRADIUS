ARG base=python:3.14-trixie
FROM ${base}
ARG base=python:3.14-trixie

RUN apt update; \
    apt install -y freeradius freeradius-python3 systemd systemd-sysv  gettext-base   curl git make bash-completion vim ;

RUN pip install fastapi[standard] pyrad pydantic-extra-types pandas
RUN echo 'set mouse-=a' > /root/.vimrc

ARG rcDir=/etc/freeradius/3.0
ENV FREERADIUS_CONF_LOCAL=${rcDir}

EXPOSE 8000/tcp 1812/udp 1813/udp
