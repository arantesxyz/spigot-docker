FROM java:8

# Gustavo (me) is not the original creator of the image
# I just made some changes and that's why i added myself as a maintainer of THIS image
# If you need help with the original image please follow the forked from directory
MAINTAINER Gustavo Arantes gustavo@arantes.xyz

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && apt-get update && apt-get install -y curl rsync tmux && rm -rf /var/lib/apt/lists/* \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

RUN groupadd -g 1000 minecraft && \
    useradd -g minecraft -u 1000 -r -M minecraft && \
    touch /run/first_time && \
    mkdir -p /opt/minecraft /var/lib/minecraft /usr/src/minecraft && \
    echo "set -g status off" > /root/.tmux.conf

COPY spigot /usr/local/bin/
ONBUILD COPY . /usr/src/minecraft

EXPOSE 25565

VOLUME ["/opt/minecraft", "/var/lib/minecraft"]

ENTRYPOINT ["/usr/local/bin/spigot"]
CMD ["run"]
