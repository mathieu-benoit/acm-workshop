FROM alpine:3.16.1 as build
ARG HUGO_VERSION=0.101.0
ENV HUGO_BINARY hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
RUN apk add --update wget ca-certificates && \
    cd /tmp/ && \
    wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} && \
    tar xzf ${HUGO_BINARY} && \
    rm -r ${HUGO_BINARY} && \
    mv hugo /usr/bin/hugo && \
    apk del wget ca-certificates && \
    rm /var/cache/apk/*
WORKDIR /site
COPY . .
RUN hugo -v -s /site -d /site/public

FROM nginxinc/nginx-unprivileged:1.23.0-alpine as nginx-unprivileged-without-curl
USER root
RUN apk del curl

FROM nginx-unprivileged-without-curl
USER 1000
COPY config/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /site/public /usr/share/nginx/html
