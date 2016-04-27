FROM library/java:8-jre

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get install -y \
  xvfb \
  libgconf-2-4 \
  libexif12 \
  chromium \
#  npm \
  supervisor \
  netcat-traditional

# install ffmpeg
RUN curl http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.3.7_all.deb \
  -o /tmp/deb-multimedia-keyring_2016.3.7_all.deb && \
  dpkg -i /tmp/deb-multimedia-keyring_2016.3.7_all.deb && \
  rm /tmp/deb-multimedia-keyring_2016.3.7_all.deb

RUN echo "deb http://www.deb-multimedia.org jessie main non-free" >> /etc/apt/sources.list && \
  echo "deb http://www.deb-multimedia.org jessie-backports main" >> /etc/apt/sources.list

RUN apt-get update

RUN apt-get install -y \
  ffmpeg

RUN curl https://raw.githubusercontent.com/nodesource/distributions/master/deb/setup_4.x -o /tmp/setup_4.x && bash /tmp/setup_4.x && \
  apt-get install -y nodejs

#Installing Firefox instead of iceweasel
RUN apt-get purge iceweasel icedove && echo "deb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main" > /etc/apt/sources.list.d/mozilla.list && \
  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C1289A29 && \
  apt-get update && \
  apt-get install -y firefox-mozilla-build libgtk-3-0

# remove packages & listings to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g protractor http-backend-proxy

# Install Selenium and Chrome driver
RUN webdriver-manager update

# Add a non-privileged user for running Protrator
RUN adduser --home /project --uid 1100 \
  --disabled-login --disabled-password --gecos node node

# Add service defintions for Xvfb, Selenium and Protractor runner
ADD supervisord/*.conf /etc/supervisor/conf.d/

# By default, tests in /data directory will be executed once and then the container
# will quit. When MANUAL envorinment variable is set when starting the container,
# tests will NOT be executed and Xvfb and Selenium will keep running.
ADD bin/run-protractor /usr/local/bin/run-protractor

RUN chmod +x /usr/local/bin/run-protractor

ENV DISPLAY_SIZE 1280x2200
RUN apt-get update && apt-get install -y x11vnc
RUN npm install lodash moment jasmine-reporters
RUN mkdir ~/.vnc
# Setup a password
RUN x11vnc -storepasswd 1234 ~/.vnc/passwd

# Container's entry point, executing supervisord in the foreground
CMD ["/usr/bin/supervisord", "-n"]

# Protractor test project needs to be mounted at /project
VOLUME ["/project"]
