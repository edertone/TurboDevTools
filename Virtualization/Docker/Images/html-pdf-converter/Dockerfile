FROM alpine:3.20

RUN apk add --no-cache \
    chromium \
    nss \
    ca-certificates \
    ttf-freefont \
    && adduser -D converter

USER converter
WORKDIR /data

COPY --chown=converter:converter entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]