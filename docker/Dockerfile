FROM debian:buster-slim

ADD https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py \
  /usr/bin/systemctl

RUN apt-get update \
  && apt-get install -y \
    openssh-server \
    sudo \
    python \
    unzip \
    lsb-release \
    ca-certificates \
    iproute2 \
    gpg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && sed -i '/ swap / s/^/#/' /etc/fstab \
  && chmod +x /usr/bin/systemctl \
  && test -L /bin/systemctl || ln -sf /usr/bin/systemctl /bin/systemctl

STOPSIGNAL SIGRTMIN+3

RUN mkdir /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed -ri \
  's/session\s*required\s*pam_loginuid.so/session optional pam_loginuid.so/g' \
  /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Pretend we're a Raspberry Pi
RUN echo "[all]" >> /boot/config.txt \
  && echo "something rootwait" >> /boot/cmdline.txt \
  && cp /etc/hosts /etc/fake-hosts

# Create pi user with access similar to Raspbian
RUN addgroup \
    --gid 1000 \
    pi \
  && useradd \
    --home /home/pi \
    --shell /bin/bash \
    --password raspberry \
    --gid pi \
    --groups adm,sudo,users \
    --uid 1000 \
    pi \
  && echo \
    '%sudo ALL=(ALL) NOPASSWD:ALL' \
    >> /etc/sudoers \
  && mkdir -p /home/pi/.ssh \
  && chown -R pi:pi /home/pi/ \
  && chmod 700 /home/pi/.ssh

COPY \
  --chown=pi:pi \
  ssh/id_rsa.pub \
  /home/pi/.ssh/authorized_keys

EXPOSE 22
CMD [ "/usr/sbin/sshd", "-D" ]
