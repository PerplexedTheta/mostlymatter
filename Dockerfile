FROM ubuntu:noble

# Setting bash as our shell, and enabling pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Some ENV variables
ENV PATH="/mattermost/bin:${PATH}"

# Build Arguments
ARG TARGETARCH ## set by buildx
ARG VERSION="11.7.0"
ARG PUID=2000
ARG PGID=2000
# MM_PACKAGE build arguments controls which version of mattermost to install, defaults to latest stable enterprise
# i.e. https://releases.mattermost.com/10.12.4/mattermost-10.12.4-linux-amd64.tar.gz
ARG MM_PACKAGE="https://releases.mattermost.com/$VERSION/mattermost-$VERSION-linux-$TARGETARCH.tar.gz"
# MM_OVERLOAD build arguments controls which file to download, to replace the default mattermost server binary
# i.e. https://packages.framasoft.org/projects/mostlymatter/mostlymatter-amd64-v10.12.4
ARG MM_OVERLOAD="https://packages.framasoft.org/projects/mostlymatter/mostlymatter-$TARGETARCH-v$VERSION"

# # Install needed packages and indirect dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  coreutils \
  ca-certificates \
  curl \
  media-types \
  mailcap \
  unrtf \
  wv \
  poppler-utils \
  tidy \
  tzdata \
  && rm -rf /var/lib/apt/lists/*

# Set mattermost group/user and download Mattermost
RUN mkdir -p /mattermost/data /mattermost/plugins /mattermost/client/plugins \
  && groupadd --gid ${PGID} mattermost \
  && useradd --uid ${PUID} --gid ${PGID} --comment "" --home-dir /mattermost mattermost \
  && curl -L $MM_PACKAGE | tar -xvz \
  && mv mattermost/bin/mattermost mattermost/bin/mattermost.bak \
  && chmod a-x mattermost/bin/mattermost.bak \
  && curl -L $MM_OVERLOAD -o mattermost/bin/mattermost >/dev/null \
  && chmod a+x mattermost/bin/mattermost \
  && chown -R mattermost:mattermost /mattermost /mattermost/data /mattermost/plugins /mattermost/client/plugins

# We should refrain from running as privileged user
USER mattermost

# Healthcheck to make sure container is ready
HEALTHCHECK --interval=30s --timeout=10s \
  CMD ["/mattermost/bin/mmctl", "system", "status", "--local"]

# Configure entrypoint and command with proper permissions
COPY --chown=mattermost:mattermost --chmod=765 entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /mattermost
CMD ["mattermost"]

EXPOSE 8065 8067 8074 8075

# Declare volumes for mount point directories
VOLUME ["/mattermost/data", "/mattermost/logs", "/mattermost/config", "/mattermost/plugins", "/mattermost/client/plugins"]
