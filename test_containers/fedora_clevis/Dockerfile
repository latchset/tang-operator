FROM fedora:35
RUN dnf install -y clevis clevis-dracut clevis-systemd clevis-luks bash

ENTRYPOINT ["tail"]
CMD ["-f","/dev/null"]
