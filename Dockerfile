# Using the appropriate Python version as base for the simulator
FROM ubuntu:18.04

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

RUN apt-get update

CMD echo "Finished updating repos"