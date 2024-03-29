FROM ubuntu:12.04
ENV DEBIAN_FRONTEND noninteractive

MAINTAINER Yuki Takei yuki@fio.jp



## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584
RUN dpkg-divert --local --rename --add /usr/bin/ischroot
RUN ln -sf /bin/true /usr/bin/ischroot

# Configure no init scripts to run on package updates.
ADD src/policy-rc.d /usr/sbin/policy-rc.d



ADD src/sources.list /etc/apt/
RUN apt-get update

RUN apt-get install -y apt-utils
RUN apt-get dist-upgrade -y

## install essential packages
RUN apt-get install -y --no-install-recommends dialog nano less sudo psmisc cron rsyslog language-pack-en 

## Fix locale.
RUN locale-gen en_US

## Fix timezone.
RUN echo "Asia/Tokyo" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

## sudoers Settings
RUN cp /etc/sudoers /tmp/sudoers.new && \
    sed -i -e "s/%sudo.*/%sudo ALL=(ALL) NOPASSWD: ALL/g" /tmp/sudoers.new && \
    cp /tmp/sudoers.new /etc/sudoers



# install utilities
RUN apt-get install -y git tmux openssh-server

## sshd Settings
#RUN sed -i -e "s/#UsePAM .*/UsePAM yes/g" /etc/ssh/sshd_config
#RUN sed -i -e "s/#PrintLastLog .*/PrintLastLog yes/g" /etc/ssh/sshd_config
#RUN sed -i -e "s/#TCPKeepAlive .*/TCPKeepAlive yes/g" /etc/ssh/sshd_config

## update-rc.d
RUN update-rc.d ssh defaults



## add user
RUN useradd -d /home/yuki -m -s /bin/bash yuki && \
    adduser yuki sudo && \
    mkdir /home/yuki/.ssh && \
    chmod 700 /home/yuki/.ssh
ADD src/authorized_keys /home/yuki/.ssh/
RUN chown -R yuki: /home/yuki



# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



ENV DEBIAN_FRONTEND dialog


# Expose the container's port 22
EXPOSE 22

# Execute /sbin/init directly (without shell)
CMD ["/sbin/init","3"]

