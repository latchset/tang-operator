FROM fedora:35
RUN dnf install -y tang curl socat procps jq
RUN /usr/libexec/tangd-keygen /var/db/tang

ENV PORT=8080

COPY ["tangd-entrypoint", "/usr/bin/tangd-entrypoint"]
COPY ["tangd-health-check", "/usr/bin/tangd-health-check"]
RUN chmod 755 /usr/bin/tangd-entrypoint
RUN chmod 755 /usr/bin/tangd-health-check
ENTRYPOINT ["/usr/bin/tangd-entrypoint"]
