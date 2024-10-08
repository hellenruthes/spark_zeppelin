# spark_zeppelin
Hability to run Spark Zeppelin locally
You need to have Docker installed
Afer run:

`docker build -t zeppelin-spark:latest .`

`docker run -p 8080:8080 -p 4040:4040 -p 6789:6789 zeppelin-spark:latest`

Zeppelin will be available on localhost:8080
