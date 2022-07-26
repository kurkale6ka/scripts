FROM debian:stable-slim
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install \
    ca-certificates \
    openssl \
    perl
WORKDIR /usr/local/src
COPY cert.pl mkconfig.pl ./
ENTRYPOINT [ "perl" ]
CMD [ "-e", "print 'Perl script expected\n'" ]
