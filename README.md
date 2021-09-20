# docker-vnc-xfce4

## Description

How to run a GUI application inside a docker container, and to access the application within a browser.  
The easiest combo is to run 
- [Xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml) a virtual X server that can run on machines with no display hardware and no physical input devices. It emulates a dumb framebuffer using virtual memory
- a [VNC server](https://github.com/LibVNC/x11vnc) to be able to access from everywhere
- [noVNC](https://github.com/novnc/noVNC) + [websockify](https://github.com/novnc/websockify) that allow to do VNC through a browser
- a Window manager
into an Ubuntu base image.

It is possible to choose a any windows manager, but some are lighter than others. Below, there will be two simple examples with light ones:
- [ratpoison](http://www.nongnu.org/ratpoison/), it produce a 1.1Gb final image
- [Xfce](https://www.xfce.org/), it produces a 1.9Gb final image

## Build images

When building the image it possible to pass a specific timezone

### Build docker-vnc-ratpoison

    docker build . -f Dockerfile_ratpoison -t docker-vnc-ratpoison --build-arg TZ=Europe/Paris

### Build docker-vnc-xfce4

    docker build . -f Dockerfile_xfce4 -t docker-vnc-xfce4 --build-arg TZ=Europe/Paris

## Usage

The built images use standard ports:
- 5900 for VNC access
- 6080 for noVNC website

So that for browser access the full address is [http://localhost:6080/vnc.html](http://localhost:6080/vnc.html).  
Applications starts with a simple user: `user`, but this user has `sudo` priviledges.  

### Start docker-vnc-ratpoison

    docker run -it --rm -p 6080:6080 -p 5900:5900 --name docker-vnc-ratpoison docker-vnc-ratpoison

### Start docker+vnc+xfce4

    docker run -it --rm -p 6080:6080 -p 5900:5900 --name docker-vnc-xfce4 -e LANG=fr_FR.UTF-8 docker-vnc-xfce4

In the `ratpoison` example a `firefox` browser is started in the image. To use another application it is necessary 

- to install it in [Dockerfile_ratpoison](Dockerfile_ratpoison) at line 15: `RUN	apt-get install -y --no-install-recommends firefox notepadqq`
- to run it in [startup.sh](startup.sh) script file. See example lien 22: `echo "exec firefox" > ~/.ratpoisonrc && chmod +x ~/.ratpoisonrc`

For `Xfce` example, just install the applciation in [Dockerfile_xfce4](Dockerfile_xfce4). It should be accessible in Xfce menu.