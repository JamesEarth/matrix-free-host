FROM matrixdotorg/synapse:latest

USER root

COPY start.sh /start.sh
RUN chmod 755 /start.sh

CMD ["/bin/bash", "-x", "/start.sh"]
