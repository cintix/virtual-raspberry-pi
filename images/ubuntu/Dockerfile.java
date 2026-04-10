FROM ubuntu:22.04


ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash bash-completion ca-certificates tzdata sudo passwd openssh-server \
    vim curl wget procps net-tools iproute2 \
    php php-cli php-common locales default-jdk \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    if ! id -u pi >/dev/null 2>&1; then useradd -m -s /bin/bash pi; fi; \
    echo "pi:raspberry" | chpasswd; \
    usermod -aG sudo pi; \
    mkdir -p /var/run/sshd; \
    sed -i 's/^#\\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config; \
    sed -i 's/^#\\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config

EXPOSE 22 80 8080 3306
WORKDIR /home/pi
CMD ["/usr/sbin/sshd", "-D"]
