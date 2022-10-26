FROM alpine:latest

RUN apk add --update-cache bash openresolv iptables curl wget  iputils sed augeas \
    && rm -rf /var/cache/apk/* \
    && true

COPY app-router /app-router
RUN chmod a+x /app-router/docker-entrypoint.sh
WORKDIR /app-router

ENV DEBUG=false
ENV DEF_IF_GATEWAY=
ENV DNS_ADDRESS=
ENV DEF_IF_ALLOW_ROUTING=false
ENV DEFAULT_ROUTES=
ENV PORT_FORWARD_HOST=
ENV PORT_FORWARD_PORTS=

ENTRYPOINT ["/app-router/docker-entrypoint.sh"]
