java -jar avro-tools-1.11.1.jar \
  fromjson \
  --schema-file \
  output_domain.avsc \
  output_domain.json > output_domain.avro
# 22/08/17 02:10:13 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
# ./test.sh  1.79s user 0.14s system 226% cpu 0.852 total

java -jar LocalTestingTool_0.3.0.jar \
  --input_data_avro_file output_debug_reports.avro \
  --domain_avro_file output_domain.avro \
  --no_noising \
  --output_directory .
# WARNING: An illegal reflective access operation has occurred
# WARNING: Illegal reflective access by com.google.inject.internal.cglib.core.$ReflectUtils$1 (file:/Users/jxck/develop/trusted-execution-aggregation-service/sampledata/LocalTestingTool_0.3.0.jar) to method java.lang.ClassLoader.defineClass(java.lang.String,byte[],int,int,java.security.ProtectionDomain)
# WARNING: Please consider reporting this to the maintainers of com.google.inject.internal.cglib.core.$ReflectUtils$1
# WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
# WARNING: All illegal access operations will be denied in a future release
# 2022-08-17 02:10:57:497 +0900 [WorkerPullWorkService] INFO com.google.aggregate.adtech.worker.WorkerPullWorkService - Aggregation worker started
# 2022-08-17 02:10:57:510 +0900 [WorkerPullWorkService] INFO com.google.aggregate.adtech.worker.WorkerPullWorkService - Item pulled
# 2022-08-17 02:10:57:522 +0900 [WorkerPullWorkService] INFO com.google.aggregate.adtech.worker.aggregation.concurrent.ConcurrentAggregationProcessor - Shards detected by blob storage client: [output_debug_reports.avro]
# 2022-08-17 02:10:57:558 +0900 [WorkerPullWorkService] INFO com.google.aggregate.adtech.worker.aggregation.concurrent.ConcurrentAggregationProcessor - Shards to be used: [DataLocation{blobStoreDataLocation=BlobStoreDataLocation{bucket=/Users/jxck/develop/trusted-execution-aggregation-service/sampledata, key=output_debug_reports.avro}}]
# 2022-08-17 02:10:57:722 +0900 [WorkerPullWorkService] INFO com.google.aggregate.adtech.worker.WorkerPullWorkService - No job pulled.
# ./test.sh  2.36s user 0.23s system 225% cpu 1.144 total

java -jar avro-tools-1.11.1.jar tojson output.avro
# 22/08/17 02:11:40 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
# Exception in thread "main" org.apache.avro.AvroRuntimeException: java.io.IOException: Invalid sync!
#         at org.apache.avro.file.DataFileStream.hasNext(DataFileStream.java:236)
#         at org.apache.avro.tool.DataFileReadTool.run(DataFileReadTool.java:97)
#         at org.apache.avro.tool.Main.run(Main.java:67)
#         at org.apache.avro.tool.Main.main(Main.java:56)
# Caused by: java.io.IOException: Invalid sync!
#         at org.apache.avro.file.DataFileStream.nextRawBlock(DataFileStream.java:331)
#         at org.apache.avro.file.DataFileStream.hasNext(DataFileStream.java:225)
#         ... 3 more
# ./test.sh  1.70s user 0.14s system 190% cpu 0.964 total