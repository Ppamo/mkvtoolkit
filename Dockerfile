FROM ubuntu:mantic
COPY mkvcli.sh /bin
COPY codes.txt /opt/iso_639-2_codes.txt
RUN apt update && apt -y upgrade
RUN printf "alias c='cd'\nalias l='ls -plh'\nalias la='ls -plah'\n" >> /root/.bashrc && chmod +x /bin/mkvcli.sh
RUN apt install -y mkvtoolnix
ENTRYPOINT [ "/bin/mkvcli.sh" ]
