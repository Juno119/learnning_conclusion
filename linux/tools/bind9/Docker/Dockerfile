FROM ubuntu:16.04
ARG package
COPY bind9_setup.sh /home/
RUN apt-get update && \
    apt-get install -y ${package} && \
    apt-get clean

CMD ["sh", "/home/bind9_setup.sh"]
