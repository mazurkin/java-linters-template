FROM eclipse-temurin:21.0.6_7-jdk-jammy

# All the setting files will be probably overriden by the container
COPY src/docker/ /

# We split the libraries and the application to keep the most of the libraries in the stable Docker layer
ADD target/java-linters-template-bundle-lib.tar.gz /opt/linters/
ADD target/java-linters-template-bundle-app.tar.gz /opt/linters/

ENV JMX_HOST=127.0.0.1
ENV JMX_PORT=8680

ENV JAVA_OPTIONS=""
ENV JAVA_CLASSPATH=""

VOLUME ["/var/log/linters"]
VOLUME ["/var/lib/linters"]

VOLUME ["/tmp"]

ENTRYPOINT ["/opt/linters/bin/run.sh"]
CMD []
