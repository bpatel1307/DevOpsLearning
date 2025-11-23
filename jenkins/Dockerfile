FROM jenkins/jenkins:lts-jdk11

USER root

# install docker client and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      docker.io \
      ca-certificates \
      curl \
      gnupg2 \
      lsb-release \
      unzip && \
    rm -rf /var/lib/apt/lists/*

# install docker-compose standalone (adjust version as desired)
ENV DOCKER_COMPOSE_VERSION=2.20.2
RUN curl -Lo /usr/local/bin/docker-compose \
      "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" && \
    chmod +x /usr/local/bin/docker-compose

# make sure jenkins owns its home directory
RUN chown -R jenkins:jenkins /var/jenkins_home

USER jenkins
