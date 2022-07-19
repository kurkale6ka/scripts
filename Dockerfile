FROM debian:stable-slim
RUN apt update && apt upgrade -y
RUN apt install -y \
    zsh \
    ipcalc \
WORKDIR /usr/local/src
CMD [ "zsh" ]
