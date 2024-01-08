#!/bin/bash

test -n "${DEBUG}" && { printenv ; echo "$@" ; }

# Preparing environment ...
ls -lart /usr/local/share/ca-certificates
update-ca-certificates > /dev/null 2>&1

# Pre-startup
test -f /prestartup.sh && { chmod +x /prestartup.sh ; . /prestartup.sh ; }

# Preparing user
export USR=${USR:-user}
id ${USR} > /dev/null 2>&1 || {
  export USR_PASS=${USR_PASS:-${USR}01}
  export USR_UID=${USR_UID:-6000}
  export USR_GID=${USR_GID:-${USR_UID}}
  groupadd --gid ${USR_GID} ${USR}
  useradd --uid ${USR_UID} --gid ${USR} --groups sudo --create-home --shell /bin/bash ${USR}
  echo "${USR}:${USR_PASS}" | chpasswd
  echo "${USR} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-user && chmod 440 /etc/sudoers.d/10-user
  {
    echo 'export PATH=.:${PATH}'
    echo "export PS1='\u@\h:\w\$ '"
  } >> /home/${USR}/.bashrc
  {
    echo "alias ll='ls -lart'"
    echo "alias psx='ps -fu $USER'"
    echo "alias g='which gcc g++ i686-w64-mingw32-gcc i686-w64-mingw32-g++ x86_64-w64-mingw32-gcc x86_64-w64-mingw32-g++ make i686-w64-mingw32-windres x86_64-w64-mingw32-windres wine wine64 java javac groovy rcedit.exe upx go lua luac node npm | sort -u 2> /dev/null'"
    echo "alias rcedit='wine /usr/bin/rcedit.exe'"
  } >> /home/${USR}/.bash_aliases && chmod +x /home/${USR}/.bash_aliases
  touch /home/${USR}/.sudo_as_admin_successful
}
export DEFAULT_USER=${USR}

# Preparing timezone
TZ=${TZ:-UTC}
test -f /usr/share/zoneinfo/${TZ} && { test -f /etc/localtime && rm --force /etc/localtime ; ln --symbolic --force /usr/share/zoneinfo/${TZ} /etc/localtime ; }

# We check all container parameters
DESKTOP_VNC_PARAMS=""

# We prepare VNC
mkdir /home/${USR}/.vnc

DESKTOP_SIZE=${DESKTOP_SIZE:-1280x1024}
DESKTOP_ENV=${DESKTOP_ENV:-xfce4}

# We add a password to VNC
if [ "X${DESKTOP_VNC_PASSWORD}" != "X" ] ; then
  echo "init password"
  x11vnc -storepasswd ${DESKTOP_VNC_PASSWORD:-password} /home/${USR}/.vnc/passwd && chmod 0600 /home/${USR}/.vnc/passwd
  DESKTOP_VNC_PARAMS=${DESKTOP_VNC_PARAMS}" -passwd ${DESKTOP_VNC_PASSWORD}"
fi
# We set the screen size
if [ "X${DESKTOP_SIZE}" != "X" ] ; then
  echo "set screen size"
  sed -i -E 's/XVFBARGS="-screen 0 [0-9]+x[0-9]+x[0-9]+"/XVFBARGS="-screen 0 '${DESKTOP_SIZE}'x24"/' /bin/xvfb-run
  grep "^XVFBARGS" /bin/xvfb-run
fi

# Init .xinitrc
#printf 'autocutsel -fork -selection CLIPBOARD\nautocutsel -fork -selection PRIMARY\nnumlockx &\n' > /home/${USR}/.xinitrc

# We install additionnal programs
if [ "X${INSTALL_ADDITIONAL_PROGRAMS}" != "X" ] ; then
  echo "Installing ${INSTALL_ADDITIONAL_PROGRAMS}..."
  apt-get update > /dev/null
  apt-get install --yes ${INSTALL_ADDITIONAL_PROGRAMS}
fi

if [ "X${DESKTOP_ENV}" = "Xratpoison" ] ; then
  echo "configure ratpoison"
  # We run ratpoison at VNC server startup
  echo "exec ratpoison >/dev/null 2>&1" >> /home/${USR}/.xinitrc
  # We start additinnal programs
  if [ "X${DESKTOP_ADDITIONAL_PROGRAMS}" != "X" ] ; then
    echo "exec ${DESKTOP_ADDITIONAL_PROGRAMS}" >> /home/${USR}/.ratpoisonrc
  else
    # We run firefox at ratpoison startup
    echo "exec firefox" > /home/${USR}/.ratpoisonrc && chmod +x /home/${USR}/.ratpoisonrc
  fi
elif  [ "X${DESKTOP_ENV}" = "Xxfce4" ] ; then
  echo "configure Xfce4"
  # We run xfce4 at VNC server startup
  echo "exec /usr/bin/startxfce4 >/dev/null 2>&1" >> /home/${USR}/.xinitrc
  # We set keyboard
  if [ "X${DESKTOP_KEYBOARD_LAYOUT}" != "X" ] ; then
    test -d /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml || mkdir -p /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml
    layout=$(echo ${DESKTOP_KEYBOARD_LAYOUT}|sed 's#/.*$##')
    variant=$(echo ${DESKTOP_KEYBOARD_LAYOUT}|sed 's#^.*/##')
    echo "set ${layout}-${variant} keyboard"
    printf '<?xml version="1.0" encoding="UTF-8"?>

<channel name="keyboard-layout" version="1.0">
  <property name="Default" type="empty">
    <property name="XkbDisable" type="bool" value="false"/>
    <property name="XkbLayout" type="string" value="'${layout}'"/>
    <property name="XkbVariant" type="string" value="'${variant}'"/>
  </property>
</channel>' > /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml
  fi
  # We set numlock
  echo '<?xml version="1.0" encoding="UTF-8"?>

<channel name="keyboards" version="1.0">
  <property name="Default" type="empty">
    <property name="Numlock" type="bool" value="true"/>
    <property name="RestoreNumlock" type="bool" value="true"/>
  </property>
</channel>' > /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml/keyboards.xml
  # We set theme
  if [ "X${DESKTOP_THEME}" != "X" ] ; then
  test -d /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml || mkdir -p /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml
  printf '<?xml version="1.0" encoding="UTF-8"?>

<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="'${DESKTOP_THEME}'"/>
    <property name="IconThemeName" type="empty"/>
    <property name="DoubleClickTime" type="empty"/>
    <property name="DoubleClickDistance" type="empty"/>
    <property name="DndDragThreshold" type="empty"/>
    <property name="CursorBlink" type="empty"/>
    <property name="CursorBlinkTime" type="empty"/>
    <property name="SoundThemeName" type="empty"/>
    <property name="EnableEventSounds" type="empty"/>
    <property name="EnableInputFeedbackSounds" type="empty"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI" type="empty"/>
    <property name="Antialias" type="empty"/>
    <property name="Hinting" type="empty"/>
    <property name="HintStyle" type="empty"/>
    <property name="RGBA" type="empty"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="CanChangeAccels" type="empty"/>
    <property name="ColorPalette" type="empty"/>
    <property name="FontName" type="empty"/>
    <property name="MonospaceFontName" type="empty"/>
    <property name="IconSizes" type="empty"/>
    <property name="KeyThemeName" type="empty"/>
    <property name="ToolbarStyle" type="empty"/>
    <property name="ToolbarIconSize" type="empty"/>
    <property name="MenuImages" type="empty"/>
    <property name="ButtonImages" type="empty"/>
    <property name="MenuBarAccel" type="empty"/>
    <property name="CursorThemeName" type="empty"/>
    <property name="CursorThemeSize" type="empty"/>
    <property name="DecorationLayout" type="empty"/>
  </property>
  <property name="Gdk" type="empty">
    <property name="WindowScalingFactor" type="empty"/>
  </property>
</channel>' > /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
  fi
  # We set background image
  if [ "X${DESKTOP_BACKGROUND_IMAGE}" != "X" ] ; then
    if [ $(echo "${DESKTOP_BACKGROUND_IMAGE}" | grep -E "^https?:\/\/" | wc -l) -eq 1 ] ; then
      wget "${DESKTOP_BACKGROUND_IMAGE}" -O "/home/${USR}/bgimage.jpg"
      DESKTOP_BACKGROUND_IMAGE="/home/${USR}/bgimage.jpg"
    fi
    test -d /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml || mkdir -p /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml
    test -f "${DESKTOP_BACKGROUND_IMAGE}" && printf '<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorscreen" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="'${DESKTOP_BACKGROUND_IMAGE}'"/>
        </property>
        <property name="workspace1" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="'${DESKTOP_BACKGROUND_IMAGE}'"/>
        </property>
        <property name="workspace2" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="'${DESKTOP_BACKGROUND_IMAGE}'"/>
        </property>
        <property name="workspace3" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="'${DESKTOP_BACKGROUND_IMAGE}'"/>
        </property>
      </property>
    </property>
  </property>
</channel>' > /home/${USR}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
  fi
  sed -i 's/^Exec=.*$/Exec=bash -c "cd $HOME ; exo-open --launch TerminalEmulator"/' /usr/share/applications/xfce4-terminal-emulator.desktop
else 
  echo "Unknown desktop environment" >&2
  exit 1
fi

chmod +x /home/${USR}/.xinitrc

# We set repeat is on
sed -i 's/tcp/tcp -ardelay 200 -arinterval 20/' /etc/X11/xinit/xserverrc

# We read the command-line parameters
if [ $# -ne 0 ] ; then
  if [ "${1}" = "help" ] ; then
    echo "Available variables:"
    echo "DESKTOP_ENV, DESKTOP_VNC_PASSWORD, DESKTOP_SIZE, DESKTOP_THEME, DESKTOP_ADDITIONAL_PROGRAMS"
    exit 0
  fi
fi

# We set sound
export PULSE_SERVER=unix:/run/user/$(id -u ${USR})/pulse/native
printf 'default-server = '${PULSE_SERVER}'\nautospawn = no\ndaemon-binary = /bin/true\nenable-shm = false' > /etc/pulse/client.conf


# We start VNC server
export FD_GEOM=${DESKTOP_SIZE}		# To init a screen display when using Xvfb
{
  while [ 1 ] ; do
    figlet "x11vnc"
    gosu $(id -u ${USR}) x11vnc -create -forever -repeat ${DESKTOP_VNC_PARAMS}
    sleep 1
  done
} &

# We set clipboard
test -d /home/${USR}/.config/autostart || mkdir -p /home/${USR}/.config/autostart
cp /etc/xdg/autostart/xfce4-clipman-plugin-autostart.desktop /home/${USR}/.config/autostart/xfce4-clipman-plugin-autostart.desktop

# We start noVNC
figlet websockify
gosu $(id -u ${USR}) websockify -D --web=/usr/share/novnc/ --cert=/home/${USR}/novnc.pem 6080 localhost:5900 &
WEBSOCKIFY_PID=$!

# We start ssh server
/etc/init.d/ssh start > /dev/null

# Prepare addons
echo "wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt update && sudo apt install codium" > /home/${USR}/codium_install

chown -R ${USR}:${USR} /home/${USR}
cd /home/${USR}

# Post-startup
test -f /poststartup.sh && { chmod +x /poststartup.sh ; . /poststartup.sh ; }

# We finally start
if [ -f /startup.sh ] ; then
  chmod +x /startup.sh
  gosu $(id -u ${USR}) /startup.sh "$@"
elif [ $# -ne 0 ] ; then
  exec gosu $(id -u ${USR}) /bin/bash -c "$@"
else 
  tail -f /dev/null
fi

kill $WEBSOCKIFY_PID
wait
