FROM matrixdotorg/synapse:latest

USER root

COPY start.sh /start.sh
RUN chmod 755 /start.sh

ENTRYPOINT ["/bin/bash"]
CMD ["/start.sh"]
