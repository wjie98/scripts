FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash \
      bash-completion \
      ca-certificates \
      curl \
      gcc \
      git \
      htop \
      net-tools \
      vim \
      less \
      tmux \
      sudo \
      procps \
      psmisc \
      iproute2 \
      iputils-ping \
      openssh-server \
      python3 \
      python3-pip \
      supervisor \
      tini && \
    rm -rf /var/lib/apt/lists/*

# Prepare runtime directories
RUN mkdir -p /var/run/sshd /workspace /etc/devbox && \
    chmod 755 /workspace

# Configure ssh server
RUN sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    grep -q '^UsePAM ' /etc/ssh/sshd_config || echo 'UsePAM yes' >> /etc/ssh/sshd_config

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY devbox-init.sh /usr/local/bin/devbox-init.sh

RUN chmod +x /usr/local/bin/devbox-init.sh

WORKDIR /workspace

EXPOSE 22

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/devbox-init.sh"]
CMD []
