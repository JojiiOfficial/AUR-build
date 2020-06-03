FROM jojii/archdevel:v1.8

WORKDIR /app

COPY ./build.sh /app
RUN chmod u+x /app/build.sh
CMD [ "/app/build.sh" ]
