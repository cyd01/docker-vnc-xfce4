#
# Building Machine
#
ARG     UBUNTU_VERSION=${UBUNTU_VERSION:-jammy}

FROM    ubuntu:${UBUNTU_VERSION}

LABEL   maintainer="cyd@9bis.com"

# https://github.com/tianon/gosu/releases
ARG     GOSU_VERSION=${GOSU_VERSION:-1.16}

# Make Options
ARG     TZ=${TZ:-Etc/UTC}
ARG     DEBIAN_FRONTEND=noninteractive

#
# Manage special certificates
#
RUN     apt-get update                                                                           \
        && apt-get install --yes --no-install-recommends apt-utils                               \
        && apt-get install --yes --no-install-recommends ca-certificates
ARG     CA_CERTS=${CA_CERTS:-""}
RUN     test -z "${CA_CERTS}" || echo "${CA_CERTS}" | tee /usr/local/share/ca-certificates/ca.crt >&2
RUN     update-ca-certificates >&2 && rm --force /usr/local/share/ca-certificates/AC*.crt || echo

# We prepare environment
RUN     \
        echo "Timezone and locale" >&2                     \
        && apt-get install --yes                           \
          apt-utils                                        \
          language-pack-fr                                 \
          software-properties-common                       \
          tzdata                                           \
        && echo "Timezone and locale OK" >&2

# Second we install VNC, noVNC and websockify
RUN     \
        echo "install VNC, noVNC and websockify" >&2       \
        && apt-get install --yes --no-install-recommends   \
          libpulse0                                        \
          x11vnc                                           \
          xvfb                                             \
          novnc                                            \
          websockify                                       \
        && echo "install VNC, noVNC and websockify OK" >&2

# And finally xfce4 and ratpoison desktop environments
RUN     \
        echo "Install xfce4 and ratpoison" >&2             \
        && apt-get install --yes --no-install-recommends   \
          dbus-x11                                         \
        && apt-get install --yes                           \
          ratpoison                                        \
          xfce4 xfce4-terminal xfce4-eyes-plugin           \
          xfce4-systemload-plugin xfce4-weather-plugin     \
          xfce4-whiskermenu-plugin xfce4-clipman-plugin    \
          xserver-xorg-video-dummy                         \
          autocutsel                                       \
          numlockx                                         \
        && echo "Install xfce4 and ratpoison OK" >&2

# We add some tools
RUN     \
        echo "Install some tools" >&2                      \
        && apt-get install --yes --no-install-recommends   \
          curl                                             \
          dumb-init                                        \
          figlet                                           \
          jq                                               \
          libnss3-tools                                    \
          plocate                                          \
          net-tools                                        \
          sudo                                             \
          vim                                              \
          vlc                                              \
          xz-utils                                         \
          zip                                              \
        && apt-get install --yes thunar-archive-plugin     \
        && echo "Install some tools OK" >&2

# We install firefox, directly from Mozilla (not from snap)
RUN     \
        echo "Install Firefox from Mozilla" >&2                  \
        && add-apt-repository ppa:mozillateam/ppa                \
        && printf '\nPackage: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/mozilla-firefox                     \
        && printf 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' > /etc/apt/apt.conf.d/51unattended-upgrades-firefox \
        && apt-get update                                        \
        && apt-get install --yes firefox --no-install-recommends \
        && echo "Install Firefox from Mozilla OK" >&2

# We can add additional GUI programs
RUN     \
        echo "Install additional GUI programs" >&2         \
        && apt-get install -y --no-install-recommends      \
          notepadqq                                        \
        && echo "Install additional GUI programs OK" >&2

# We install and configure a SSH server
RUN     \
        echo "Install SSH server" >&2                                                               \
        && apt install --yes openssh-client openssh-server                                          \
        && sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
        && echo "SSH server installation and configuration Ok" >&2

# Some other tools
#
RUN     \
        wget --quiet --no-check-certificate https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -O /usr/local/bin/gosu && chmod +x /usr/local/bin/gosu \
        && echo "Some other tools: OK" >&2

# We set localtime
RUN      if [ "X${TZ}" != "X" ] ; then if [ -f /usr/share/zoneinfo/${TZ} ] ; then rm -f /etc/localtime ; ln -s /usr/share/zoneinfo/${TZ} /etc/localtime ; fi ; fi

COPY    bgimage.jpg /usr/share/backgrounds/xfce/bgimage.jpg

# And here is the statup script, everything else is in there
COPY    entrypoint.sh /entrypoint.sh
RUN     chmod 755 /entrypoint.sh

#
# Cleaning
#
RUN     \
        updatedb                                     \
        && apt-get autoremove --yes                  \
        && apt-get clean                             \
        && rm -Rf /usr/share/doc                     \
        && rm -Rf /usr/share/man                     \
        && rm -rf /var/lib/apt/lists/*               \
        && rm --recursive --force /tmp/* /var/tmp/*  \
        && touch -d "2 hours ago" /var/lib/apt/lists \
        && echo "Cleaning Ok" >&2

COPY    Dockerfile /etc/Dockerfile
RUN     touch /etc/Dockerfile

# Thres ports are availables: 22 for ssh, 5900 for VNC client, and 6080 for browser access via websockify
EXPOSE  22 5900 6080

ENTRYPOINT [ "/usr/bin/dumb-init", "--", "/entrypoint.sh" ]
#ENTRYPOINT [ "/entrypoint.sh" ]
