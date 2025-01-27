FROM python:3.7-slim-buster
# switched to 3.7-slim-buster from 3.7-slim (bullseye)

RUN set -ex \
    && apt clean \
    && apt -y update
    
RUN set -ex \
    && apt -y install nginx \
                      python3-dev \
                      build-essential \
                      default-libmysqlclient-dev \
                      openssh-server \
                      python3-dbus=1.2.8-3 # specify version compatible with buster 


RUN set -ex \
    && rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key \
    && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key \
    && adduser --disabled-password --gecos "" qtc \
    && mkdir /home/qtc/.ssh \
    && chown -R qtc:qtc /home/qtc/.ssh \
    && chmod -R 700 /home/qtc/.ssh \
    && chsh -s /bin/bash qtc

RUN mkdir /code/
WORKDIR /code/
ADD . /code/

COPY authorized_keys /home/qtc/.ssh/authorized_keys
RUN chown qtc:qtc /home/qtc/.ssh/authorized_keys
RUN chmod 400 /home/qtc/.ssh/authorized_keys
COPY nginx.conf /etc/nginx

RUN set -ex \
    && pip install -r requirements.txt --src /usr/local/src

RUN chmod +x ./start.sh
CMD ["./start.sh"]
