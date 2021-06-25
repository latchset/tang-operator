FROM fedora:35
RUN dnf install -y tang curl socat
RUN /usr/libexec/tangd-keygen /var/db/tang

COPY ["tangd-entrypoint", "/usr/bin/tangd-entrypoint"]
RUN chmod 755 /usr/bin/tangd-entrypoint
ENTRYPOINT ["/usr/bin/tangd-entrypoint"]
