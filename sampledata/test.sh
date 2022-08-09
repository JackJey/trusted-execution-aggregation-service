# java -jar avro-tools-1.11.1.jar \
#   fromjson \
#   --schema-file \
#   output_domain.avsc \
#   output_domain.json > output_domain.avro

java -jar LocalTestingTool_0.3.0.jar \
  --input_data_avro_file output_debug_reports.avro \
  --domain_avro_file output_domain.avro \
  --json_output \
  --no_noising \
  --output_directory .
