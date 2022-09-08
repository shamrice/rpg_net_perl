FROM perl:latest
RUN cpanm Carton 

COPY . /usr/src/rpg_server

WORKDIR /usr/src/rpg_server

RUN carton install

EXPOSE 3000/tcp

CMD [ "/bin/bash", "./start_server.sh"]
