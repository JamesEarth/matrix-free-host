
FROM matrixdotorg/synapse:latest

USER root

COPY start.sh /start.sh
RUN chmod +x /start.sh

USER synapse

CMD ["/start.sh"]
