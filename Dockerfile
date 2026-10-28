FROM alpine:3.22@sha256:2e0b81d60597f449baa56dc25d355367869d2dca4cd57e866f1e2b52af3eb55f

# Versions are pinned for reproducibility. Alpine drops superseded package versions from the 3.22
# repositories, so a build fails once one is replaced: bump these (see README) rather than unpin.
RUN apk add --no-cache \
      fetchmail=6.5.2-r0 \
      ca-certificates=20261020-r0 \
      tini=0.19.0-r3 \
 && adduser -D -u 1002 -h /tmp fetchmail

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Numeric UID so Kubernetes can verify runAsNonRoot.
USER 1002:1002
ENV HOME=/tmp
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
