FROM archlinux:latest

WORKDIR /app

COPY ./build.sh /app
RUN chmod u+x /app/build.sh
CMD [ "/app/build.sh" ]