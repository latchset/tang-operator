FROM scratch

WORKDIR /
COPY manager /tang-operator-manager

USER "root"

ENTRYPOINT ["/tang-operator-manager"]
