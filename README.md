# Mostlymatter Docker images

This repo contains a modified Dockerfile, which will fetch Mattermost, and replace the binary with Mostlymatter's
To use in production, see https://github.com/mattermost/docker - but, replace the base Mattermost image with one found in our container registry

Recommended build command:
```
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ghcr.io/perplexedtheta/mostlymatter:11.7.1 \
    .
```
