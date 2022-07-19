FROM debian:stable-slim
RUN apt update && apt upgrade -y
RUN apt install -y \
    zsh \
    ca-certificates \
    openssh \
    perl
WORKDIR /usr/local/src
COPY cert.pl mkconfig.pl .
CMD [ "zsh" ]
ENTRYPOINT [ "perl" ]
