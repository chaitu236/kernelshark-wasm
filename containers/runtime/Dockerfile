ARG NGINX_IMAGE=nginxinc/nginx-unprivileged:stable-alpine@sha256:4714e0b1b2577eaa1a6131d07c958b67f0eb68e6d0521e90c6e5287db8cf0bc5

FROM ${NGINX_IMAGE}

COPY --chown=101:101 containers/runtime/nginx.conf /etc/nginx/conf.d/default.conf
COPY --chown=101:101 out/wasm-release/dist/ /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --spider http://127.0.0.1:8080/healthz || exit 1