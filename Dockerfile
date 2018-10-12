FROM ubuntu:18.04

# Prevent Qt from complaining about display, even in headless mode
# https://github.com/ariya/phantomjs/issues/14376
ENV QT_QPA_PLATFORM=offscreen

# Prevent tzdata from hanging during apt-get
# https://serverfault.com/a/683651
ENV TZ=America/Los_Angeles
RUN \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    # Use bash instead of sh
    # https://stackoverflow.com/a/25423366
    rm /bin/sh && ln -s /bin/bash /bin/sh && \
    # Need to make qt build properly  
    echo 'export QT_DEBUG_PLUGINS=1' >> ~/.bashrc && \
    echo 'export PATH=/V-REP_PRO_EDU_V3_5_0_Linux/:$PATH' >> ~/.bashrc

# Install pip properly 
# https://askubuntu.com/a/1034113
RUN hash -d pip

COPY requirements.txt /requirements.txt
RUN apt-get update && \ 
    apt-get install --no-install-recommends -y \
        x11vnc xvfb \
        tmux vim \
        gfortran python python-pip python-tk \
        mesa-common-dev libglu1-mesa-dev libglib2.0-0 libgl1-mesa-glx xcb \
        lua5.1 lua5.1-doc lua5.1-lgi lua5.1-lgi-dev lua5.1-policy \
        lua5.1-policy-dev liblua5.1-0 liblua5.1-0-dbg liblua5.1-0-dev \
        libdbus-1-dev libfontconfig1 libxi-dev libxrender-dev libdbus-1-3 \
        libx11-xcb-dev libxi6 \
        build-essential \
        liblua5.1-dev libboost-all-dev "^libxcb.*" && \
    # Install python dependencies
    python -m pip install --upgrade pip && \
    pip install --no-cache-dir setuptools wheel && \
    # Prevent SSL library problems in python 2
    # https://stackoverflow.com/a/29099439
    pip install --no-cache-dir 'requests[security]' && \
    # Have to install numpy first or GPy and DIRECT bug out
    pip install --no-cache-dir numpy && \
    pip install --no-cache-dir -r requirements.txt && \
    apt-get remove -y python-pip && \
    rm -rf /var/lib/apt/lists/*

# Install vrep files
WORKDIR /vrep_files
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y wget && \
    wget http://coppeliarobotics.com/files/V-REP_PRO_EDU_V3_5_0_Linux.tar.gz &&\
    tar -xvf V-REP_PRO_EDU_V3_5_0_Linux.tar.gz && \
    rm -f V-REP_PRO_EDU_V3_5_0_Linux.tar.gz && \
    apt-get remove -y wget && \
    rm -rf /var/lib/apt/lists/*

# Pull source code 
WORKDIR /vrep_files/V-REP_PRO_EDU_V3_5_0_Linux
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y git && \
    git clone https://github.com/CoppeliaRobotics/v_rep.git && \
    # Update programmming libraries 
    rm -rf \
        programming/include \
        programming/common \
        programming/v_repMath && \
    git clone https://github.com/CoppeliaRobotics/include.git \
        programming/include && \
    git clone https://github.com/CoppeliaRobotics/common.git \
        programming/common && \
    git clone https://github.com/CoppeliaRobotics/v_repMath.git \
        programming/v_repMath && \
    apt-get remove -y git && \
    rm -rf /var/lib/apt/lists/*

# Transfer qt files
WORKDIR /
# Script from https://stackoverflow.com/a/34032216
# Patched with https://stackoverflow.com/a/47820171
COPY files/qt-installer-noninteractive.qs /
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y wget && \
    wget \
        http://mirrors.ocf.berkeley.edu/qt/archive/online_installers/3.0/qt-unified-linux-x64-3.0.5-online.run && \
    chmod +x qt-unified-linux-x64-3.0.5-online.run && \
    ./qt-unified-linux-x64-3.0.5-online.run --verbose \
        --platform minimal \
        --script qt-installer-noninteractive.qs && \
    rm -f qt-unified-linux-x64-3.0.5-online.run \
          qt-installer-noninteractive.qs && \
    apt-get remove -y wget && \
    rm -rf /var/lib/apt/lists/*

# wget lua libraries 
WORKDIR /lua
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y wget && \
    wget \
        http://files.luaforge.net/releases/luabinaries/bLua5.1.4/Libraries/lua5_1_4_Linux26g4_64_lib.tar.gz && \
    tar -xvf lua5_1_4_Linux26g4_64_lib.tar.gz && \
    apt-get remove -y wget && \
    rm -rf lua5_1_4_Linux26g4_64_lib.tar.gz \
          /var/lib/apt/lists/*

WORKDIR /
# Somehow they didn't ```#include <algorithm>``` 
# http://www.forum.coppeliarobotics.com/viewtopic.php?f=5&t=7427
 RUN sed -i '1i#include <algorithm>' \
     /vrep_files/V-REP_PRO_EDU_V3_5_0_Linux/v_rep/sourceCode/interfaces/v_rep_internal.cpp

# Copy over correct file paths
COPY config.pri /vrep_files/V-REP_PRO_EDU_V3_5_0_Linux/v_rep
COPY makefile /vrep_files/V-REP_PRO_EDU_V3_5_0_Linux/v_rep

WORKDIR /vrep_files/V-REP_PRO_EDU_V3_5_0_Linux/v_rep

WORKDIR /vrep_files/V-REP_PRO_EDU_V3_5_0_Linux/
