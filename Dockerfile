# Base image with Java 8
FROM openjdk:8-jdk-slim

# Set environment variables
ENV SPARK_VERSION=3.2.4
ENV HADOOP_VERSION=3.2
ENV ZEPPELIN_VERSION=0.10.1

# Install necessary tools and Python
RUN apt-get update && apt-get install -y wget curl procps net-tools python3 python3-pip python3-venv && rm -rf /var/lib/apt/lists/*

# Create a symlink for python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Download and install Spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    tar -xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark && \
    rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz

# Set Spark environment variables
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin

# Download and install Zeppelin
RUN wget https://dlcdn.apache.org/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz && \
    tar -xzf zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz && \
    mv zeppelin-${ZEPPELIN_VERSION}-bin-all /opt/zeppelin && \
    rm zeppelin-${ZEPPELIN_VERSION}-bin-all.tgz

# Set Zeppelin environment variables
ENV ZEPPELIN_HOME=/opt/zeppelin
ENV PATH=$PATH:$ZEPPELIN_HOME/bin
ENV ZEPPELIN_ADDR=0.0.0.0
ENV ZEPPELIN_PORT=8080

# Create necessary directories and set permissions
RUN mkdir -p /opt/zeppelin/logs /opt/zeppelin/run && \
    chown -R root:root /opt/zeppelin/logs /opt/zeppelin/run

# Download additional JARs for Azure Storage, Hadoop Azure support, and WildFly OpenSSL
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure/3.2.0/hadoop-azure-3.2.0.jar -P /opt/spark/jars/ && \
    wget https://repo1.maven.org/maven2/com/microsoft/azure/azure-storage/8.6.6/azure-storage-8.6.6.jar -P /opt/spark/jars/ && \
    wget https://repo1.maven.org/maven2/org/wildfly/openssl/wildfly-openssl/1.0.7.Final/wildfly-openssl-1.0.7.Final.jar -P /opt/spark/jars/

# Locate and update Zeppelin configuration
RUN echo "Locating Zeppelin configuration file..." && \
    ZEPPELIN_CONF_FILE=$(find /opt/zeppelin -name "zeppelin-site.xml") && \
    if [ -z "$ZEPPELIN_CONF_FILE" ]; then \
        echo "zeppelin-site.xml not found. Creating a new one." && \
        echo '<?xml version="1.0"?>\n<configuration>\n</configuration>' > /opt/zeppelin/conf/zeppelin-site.xml && \
        ZEPPELIN_CONF_FILE="/opt/zeppelin/conf/zeppelin-site.xml"; \
    else \
        echo "Found Zeppelin configuration file at: $ZEPPELIN_CONF_FILE"; \
    fi && \
    sed -i 's#<value>8080</value>#<value>8080</value>#g' $ZEPPELIN_CONF_FILE && \
    sed -i 's#<value>127.0.0.1</value>#<value>0.0.0.0</value>#g' $ZEPPELIN_CONF_FILE && \
    sed -i 's#<name>zeppelin.python</name>#<name>zeppelin.python</name>\n    <value>/usr/bin/python</value>#g' $ZEPPELIN_CONF_FILE && \
    echo "Configuration file contents:" && \
    cat $ZEPPELIN_CONF_FILE

# Expose necessary ports
EXPOSE 8080 4040 6789

# Create a startup script
RUN echo '#!/bin/bash\n\
echo "Starting Zeppelin..."\n\
echo "Java version:"\n\
java -version\n\
echo "Python version:"\n\
python --version\n\
echo "Python3 version:"\n\
python3 --version\n\
echo "Python symlink:"\n\
ls -l /usr/bin/python\n\
echo "Zeppelin home: $ZEPPELIN_HOME"\n\
echo "Spark home: $SPARK_HOME"\n\
echo "Environment variables:"\n\
env\n\
echo "export ZEPPELIN_PORT=8080" >> $ZEPPELIN_HOME/conf/zeppelin-env.sh\n\
echo "export ZEPPELIN_ADDR=0.0.0.0" >> $ZEPPELIN_HOME/conf/zeppelin-env.sh\n\
echo "export PYSPARK_PYTHON=/usr/bin/python" >> $ZEPPELIN_HOME/conf/zeppelin-env.sh\n\
echo "Starting Zeppelin daemon..."\n\
$ZEPPELIN_HOME/bin/zeppelin-daemon.sh start\n\
echo "Zeppelin daemon started, checking status:"\n\
$ZEPPELIN_HOME/bin/zeppelin-daemon.sh status\n\
echo "Checking if Zeppelin process is running:"\n\
ps aux | grep zeppelin\n\
echo "Checking listening ports:"\n\
netstat -tuln\n\
echo "Zeppelin logs:"\n\
tail -f $ZEPPELIN_HOME/logs/*' > /start-zeppelin.sh && \
    chmod +x /start-zeppelin.sh

# Set the startup script as the entry point
ENTRYPOINT ["/start-zeppelin.sh"]
