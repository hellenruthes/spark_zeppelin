%pyspark
spark = SparkSession.builder.appName("AzureBlobExample") \
    .config("spark.jars.packages", "org.apache.hadoop:hadoop-azure:3.2.0,org.wildfly.openssl:wildfly-openssl:1.0.7.Final") \
    .config("spark.hadoop.fs.azure", "org.apache.hadoop.fs.azure.NativeAzureFileSystem") \
    .config("spark.hadoop.fs.azure.account.key.devtoudatabricksdatalake.dfs.core.windows.net", storage_account_key) \
    .config("spark.driver.memory", "8g") \
    .config("spark.executor.memory", "8g")  \
    .config("spark.driver.maxResultSize", "4g")  \
    .config("spark.executor.cores", "4") \
    .getOrCreate()


comment_path = "<path>"
comment = spark.read.format("parquet").load(comment_path)
comment.createOrReplaceTempView('comment')
