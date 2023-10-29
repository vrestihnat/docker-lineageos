
FROM eclipse-temurin:8-focal


ARG LOS_USER="lineageos"
ARG LOS_UID=1000

###################
# This Dockerfile was based on the following Dockerfiles
# - docker-lineageos: existing unoptimized image
#    https://github.com/AnthoDingo/docker-lineageos/blob/autobuild/Dockerfile
#

# default user
ENV USER=${LOS_USER}

ENV \
    # base dir
    BASE_DIR=/home/$USER \
    # device configuration dir
    DEVICE_CONFIGS_DIR=/home/device-config

# install packages
RUN set -ex ;\
    apt-get update && apt-get install -y --no-install-recommends \
          # install sdk
          # https://wiki.lineageos.org/devices/klte/build#install-the-build-packages
          android-sdk-platform-tools-common \
          android-tools-adb \
          android-tools-fastboot \
          # install packages
          # https://wiki.lineageos.org/devices/klte/build#install-the-build-packages
          bc \
          bison \
          build-essential \
          ccache \
          curl \
          flex \
          g++-multilib \
          gcc-multilib \
          git \
          gnupg \
          gperf \
          imagemagick \
          lib32ncurses5-dev \
          lib32readline-dev \
          lib32z1-dev \
          libelf-dev \
          liblz4-tool \
          libncurses5 \
          libncurses5-dev \
          libsdl1.2-dev \
          libssl-dev \
          libxml2 \
          libxml2-utils \
          lzop \
          pngcrush \
          rsync \
          schedtool \
          squashfs-tools \
          xsltproc \
          zip \
          zlib1g-dev \
          # extra packages
          # for repo
          python2 \
          python3 \
          # for repo
          openssh-client \
          # for ps command
          procps \
          # no less on debian *gasp!*
          less \
          # so we have an editor inside the container
          vim \
          # has 'col' package needed for 'breakfast'
          bsdmainutils \
          # unzip is needed at least for Fairphone 4 build
          unzip \
          # we can't build kernel on root (like docker runs)
          # we add these so we have a non-root user
          fakeroot \
          sudo \
          ;\
    rm -rf /var/lib/apt/lists/*

# run config in a seperate layer so we cache it
RUN set -ex ;\
    # User setup
    # add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
    groupadd -r lineageos && useradd -r -g lineageos $LOS_USER && usermod -u $LOS_UID $USER ;\
    # allow non-root user to remount fs
    # adding ALL permissions so they can do other stuff in the future, like sudo vim
    echo "lineageos ALL=NOPASSWD: ALL" >> /etc/sudoers ;\
    # Android Setup
    # create paths: https://wiki.lineageos.org/devices/klte/build#create-the-directories
    curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/bin/repo ;\
    chmod a+x /usr/bin/repo ;\
    ln -s /usr/bin/python3 /usr/bin/python && \
    # config git coloring
    # check this link for things repo check:
    # https://gerrit.googlesource.com/git-repo/+/master/subcmds/init.py#328
    git config --global color.ui true ;\
    # source init when any bash is called (which includes the lineageos script)
    echo "source /etc/profile.d/init.sh" >> /etc/bash.bashrc ;

ARG PYTHON=3

RUN set -ex ;\
    if [ "x$PYTHON" = "x2" ]; then \
     sed -i 's/\/usr\/bin\/env\ python/\/usr\/bin\/env\ python3/' /usr/bin/repo ;\
     rm -f /usr/bin/python && ln -s /usr/bin/python2 /usr/bin/python ;\
    fi

RUN set -ex ;\
    sed -i 's/TLSv1,//g'   /opt/java/openjdk/jre/lib/security/java.security ;\
    sed -i 's/TLSv1.1,//g'   /opt/java/openjdk/jre/lib/security/java.security

# copy default configuration into container
COPY default.env init.sh /etc/profile.d/
# copy script and config vars
COPY lineageos /bin
# copy dir with several PRed device configurations
COPY device-config $DEVICE_CONFIGS_DIR

COPY fix /fix

# set volume and user home folder
RUN mkdir -p "$BASE_DIR" && chown "$USER:$USER" "$BASE_DIR"
USER $USER
WORKDIR $BASE_DIR

CMD /bin/bash
