#!/bin/bash

# We check all container parameters
VNC_PARAMS=""

# We prepare VNC
mkdir ~/.vnc

# We add a password to VNC
if [ "X${VNC_PASSWORD}" != "X" ] ; then
	echo "init password"
	x11vnc -storepasswd ${VNC_PASSWORD:-password} ~/.vnc/passwd && chmod 0600 ~/.vnc/passwd
	VNC_PARAMS=${VNC_PARAMS}" -passwd ${VNC_PASSWORD}"
fi
# We set the screen size
if [ "X${VNC_SIZE}" != "X" ] ; then
	VNC_PARAMS=${VNC_PARAMS}" -geometry "${VNC_SIZE}
fi

if [ $(which ratpoison 2>/dev/null | wc -l) -ne 0 ] ; then
	# We run firefox at ratpoison startup
	echo "exec firefox" > ~/.ratpoisonrc && chmod +x ~/.ratpoisonrc
	# We run ratpoison at VNC server startup
	echo "exec ratpoison" >> ~/.xinitrc
	# We start additionnal programs
	if [ "X${ADDITIONNAL_PROGRAMS}" != "X" ] ; then
		echo "exec ${ADDITIONNAL_PROGRAMS}" >> ~/.ratpoisonrc
	fi
elif [ $(which startxfce4 2>/dev/null | wc -l) -ne 0 ] ; then
	# We run xfce4 at VNC server startup
	echo "exec /usr/bin/startxfce4" >> ~/.xinitrc
fi
chmod +x ~/.xinitrc

# We read the command-line parameters
if [ $# -ne 0 ] ; then
	echo "Available variables:"
	echo "VNC_PASSWORD, ADDITIONNAL_PROGRAMS"
fi
# We start VNC server
DISPLAY=:0
x11vnc -create -forever ${VNC_PARAMS} &

# We start noVNC
websockify -D --web=/usr/share/novnc/ --cert=~/novnc.pem 6080 localhost:5900 &

if [ $# -ne 0 ] ; then
	$@
else 
	tail -f /dev/null 
fi
