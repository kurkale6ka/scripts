FROM alpine:latest
RUN apk update
RUN apk upgrade
RUN apk add perl
RUN apk add openssl
RUN apk add ca-certificates
WORKDIR /usr/local/src
COPY cert.pl .
ENTRYPOINT [ "perl" ]
