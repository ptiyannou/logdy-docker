# syntax=docker/dockerfile:1.7

ARG GO_IMAGE=golang:1.23.2-alpine
ARG ALPINE_IMAGE=alpine:3.21

FROM ${GO_IMAGE} AS builder

ARG LOGDY_REF=3d870d951f968d45fd5d4e373a2c98db0a2a8d8b

RUN apk add --no-cache ca-certificates git

WORKDIR /src

RUN git clone https://github.com/logdyhq/logdy-core.git . \
    && git checkout --detach "${LOGDY_REF}" \
    && test "$(git rev-parse HEAD)" = "${LOGDY_REF}"

RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    CGO_ENABLED=0 go build \
      -trimpath \
      -ldflags="-s -w -X main.Version=${LOGDY_REF}" \
      -o /out/logdy .

FROM ${ALPINE_IMAGE}

ARG LOGDY_REF=3d870d951f968d45fd5d4e373a2c98db0a2a8d8b

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S -g 65532 logdy \
    && adduser -S -D -H -u 65532 -G logdy logdy

COPY --from=builder /out/logdy /usr/local/bin/logdy
COPY --from=builder /src/LICENSE /usr/share/licenses/logdy/LICENSE

LABEL org.opencontainers.image.title="Logdy Docker" \
      org.opencontainers.image.description="Small multi-architecture container image for Logdy" \
      org.opencontainers.image.source="https://github.com/ptiyannou/logdy-docker" \
      org.opencontainers.image.url="https://github.com/ptiyannou/logdy-docker" \
      org.opencontainers.image.documentation="https://github.com/ptiyannou/logdy-docker#readme" \
      org.opencontainers.image.licenses="MIT AND Apache-2.0" \
      org.opencontainers.image.revision="${LOGDY_REF}"

USER 65532:65532

EXPOSE 1514/tcp 8080/tcp

ENTRYPOINT ["/usr/local/bin/logdy", "--ui-ip", "0.0.0.0"]
CMD ["socket", "1514"]
