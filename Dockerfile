FROM ubuntu:latest
EXPOSE 22

# System update
RUN apt update

# Get dependencies
RUN apt --assume-yes install dialog openssh-server sqlite3 make gcc

# Necessary for sshd to run
RUN mkdir /run/sshd && chmod 755 /run/sshd

# Create user
RUN useradd -d /lowlife -ms /lowlife/shell.sh lowlife && chown -R lowlife /lowlife
RUN echo "lowlife:hightech" | chpasswd

# Get files
COPY ./src /lowlife
RUN chown -R lowlife:lowlife /lowlife && chmod +x /lowlife/shell.sh

# Set up utils
USER lowlife
WORKDIR /lowlife/utils
RUN make all

# Set configuration files
USER root
WORKDIR /
COPY ./sshd_banner /etc/ssh/sshd_banner
COPY ./sshd_config /etc/ssh/sshd_config

# Ready to go
ENTRYPOINT ["/usr/sbin/sshd", "-D"]
