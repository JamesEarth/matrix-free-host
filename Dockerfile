FROM matrixdotorg/synapse:latest

USER root

RUN apt-get update \
    && apt-get install -y python3-pip \
    && rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

USER synapse

CMD ["/start.sh"]
