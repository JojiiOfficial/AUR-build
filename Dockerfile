FROM jojii/archdevel:v2.7

WORKDIR /app

COPY ./build.sh /app
RUN chmod u+x /app/build.sh
CMD [ "/app/build.sh" ]
