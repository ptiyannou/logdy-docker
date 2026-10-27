# Logdy Docker

A small, general-purpose, multi-architecture container image for
[Logdy](https://github.com/logdyhq/logdy-core), a live log viewer with a web UI.

The image is not tied to Homey. Any application, appliance or script able to
send newline-delimited text over TCP can use it. Homey is documented below only
as one possible example.

Images are published for `linux/amd64` and `linux/arm64`:

```text
ghcr.io/ptiyannou/logdy-docker:latest
```

## What is included

- Logdy built from the pinned upstream commit
  `3d870d951f968d45fd5d4e373a2c98db0a2a8d8b`
- TCP line receiver on container port `1514`
- web interface on container port `8080`
- optional raw append to a persistent file
- non-root user (`65532:65532`)
- no database or cloud dependency

## Quick start with Docker Compose

```sh
cp .env.example .env
# Set LOGDY_UI_PASS and, if needed, BIND_ADDRESS.
mkdir -p data
docker compose up -d
```

Open `http://<docker-host>:8086`. Send newline-delimited text to TCP port
`1514`, for example:

```sh
printf 'hello from my application\n' | nc <docker-host> 1514
```

## Docker run

```sh
docker run -d \
  --name logdy \
  --restart unless-stopped \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --tmpfs /tmp:rw,noexec,nosuid,nodev,size=16m \
  -u 65532:65532 \
  -p 1514:1514/tcp \
  -p 8086:8080/tcp \
  -e LOGDY_UI_PASS='change-me' \
  -e LOGDY_APPEND_TO_FILE=/data/logdy.log \
  -e LOGDY_ROTATE_FILE_SIZE=25M \
  -v "$PWD/data:/data" \
  ghcr.io/ptiyannou/logdy-docker:latest \
  socket 1514 --append-to-file-raw --max-message-count 10000 \
  --no-analytics --no-updates
```

## Configuration

The bundled Compose example exposes these settings:

| Variable | Default | Purpose |
|---|---:|---|
| `LOGDY_IMAGE` | `ghcr.io/ptiyannou/logdy-docker:latest` | Container image |
| `BIND_ADDRESS` | `127.0.0.1` | Host address used for both published ports |
| `SYSLOG_PORT` | `1514` | Host TCP input port |
| `WEB_PORT` | `8086` | Host web UI port |
| `DATA_DIR` | `./data` | Persistent host directory |
| `LOGDY_UI_PASS` | required | Password protecting the web UI |
| `LOGDY_LOG_FILE` | `/data/logdy.log` | File receiving the raw lines |
| `LOGDY_ROTATE_FILE_SIZE` | `25M` | File rotation threshold |
| `LOGDY_MAX_MESSAGES` | `10000` | Live in-memory message limit |

The image also accepts Logdy's normal command-line flags and environment
variables. See the [upstream Logdy documentation](https://github.com/logdyhq/logdy-core).

## Example: Homey

With the Homey **Simple (Sys) Log** app, create a Syslog client that uses TCP
and points to the Docker host on port `1514`. Nothing in the image is specific
to this integration; other TCP log producers work the same way.

## Security

- Bind the ports only to a trusted interface.
- Restrict the TCP input to known senders with the host firewall.
- Do not expose the web interface directly to the internet.
- Use a long web UI password and keep `.env` out of version control.
- The Compose example runs the container read-only, without Linux capabilities.
- Analytics and update checks are disabled in the Compose example.

## Build locally

```sh
docker build -t logdy-docker:local .
```

The build pins the upstream Logdy source commit for reproducibility. To test a
different revision explicitly:

```sh
docker build --build-arg LOGDY_REF=<full-commit-sha> -t logdy-docker:test .
```

## License

The Docker packaging in this repository is MIT licensed. Logdy itself is
licensed under Apache-2.0; its upstream license is copied into the image.
