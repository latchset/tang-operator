FROM fedora:35
RUN dnf install -y tang curl socat meson ninja-build git gcc-c++\
 cmake libjose-devel asciidoc http-parser-devel bash
RUN /usr/libexec/tangd-keygen /var/db/tang

RUN chmod 755 /usr/libexec/tangd
RUN ln -s /usr/libexec/tangd /usr/bin/tangd
RUN git clone https://github.com/latchset/tang /root/tang
ENTRYPOINT ["/usr/bin/bash", "-c", "cd /root/tang && mkdir -p build && cd build && meson .. && ninja && meson test"]
