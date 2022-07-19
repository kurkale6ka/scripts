FROM debian:stable-slim
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install \
    zsh \
    ipcalc
ENV PROMPT='%n@zsh:%~%# '
ENV RPROMPT='%m'
WORKDIR /usr/local/src
CMD [ "zsh" ]
