# Collecting and Batching Aggregatable Reports

Attribution Reporting API の Aggregatable Reports を収集、変換、バッチする方法

Attribution Reporting API は、 OT の間に 4 種類の可能なレポートを生成し、登録されたドメインの well-known に POST で送られる。

1. Event-level report:        `/.well-known/attribution-reporting/report-event-attribution`
1. Event-level debug report:  `/.well-known/attribution-reporting/debug/report-event-attribution`
1. Aggregatable report:       `/.well-known/attribution-reporting/report-aggregate-attribution`
1. Aggregatable debug report: `/.well-known/attribution-reporting/debug/report-aggregate-attribution`

## Aggregatable report sample

Attribution Reporting API Demo の Aggregatable Debug レポートのサンプルです。

```json
{
  "aggregation_service_payloads": [
    {
      "debug_cleartext_payload": "omRkYXRhgaJldmFsdWVEAACAAGZidWNrZXRQAAAAAAAAAAAAAAAAAAAFWWlvcGVyYXRpb25paGlzdG9ncmFt",
      "key_id": "e101cca5-3dec-4d4f-9823-9c7984b0bafe",
      "payload": "26/oZSjHABFqsIxR4Gyh/DpmJLNA/fcp43Wdc1/sblss3eAkAPsqJLphnKjAC2eLFR2bQolMTOneOU5sMWuCfag2tmFlQKLjTkNv85Wq6HAmLg+Zq+YU0gxF573yzK38Cj2pWtb65lhnq9dl4Yiz"
    }
  ],
  "attribution_destination": "http://shoes.localhost",
  "shared_info": "{
    \"debug_mode\": \"enabled\",
    \"privacy_budget_key\": \"OtLi6K1k0yNpebFbh92gUh/Cf8HgVBVXLo/BU50SRag=\",
    \"report_id\": \"00cf2236-a4fa-40e5-a7aa-d2ceb33a4d9d\",
    \"reporting_origin\": \"http://adtech.localhost:3000\",
    \"scheduled_report_time\": \"1649652363\",
    \"version\": \"\"
  }",
  "source_debug_key": "531933890459023",
  "source_registration_time": "1649635200",
  "source_site": "http://news.localhost",
  "trigger_debug_key": "531933890459023"
}
```

The `debug_cleartext_payload` field contains the base64 encoded [CBOR](https://cbor.io/) payload. The above CBOR payload decodes into the following data in JSON format (Decoded with [CBOR Playground](https://cbor.me)). The bucket value is encoded as a sequence of 'characters' representing the underlying bytes. While some bytes may be represented as ASCII characters, others are unicode escaped.

`debug_cleartext_payload` フィールドには、base64 エンコードされた以下の JSON の CBOR ペイロードが格納される。
Bucket 値は、元のバイトを「char」にエンコードしたもの。なので、 Unicode エスケープされるか、 ASCII 範囲なら文字として表現される。

```json
{
  "data": [
    {
      "value": "\u0000\u0000\x80\u0000",
      "bucket": "\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0000\u0005Y"
    }
  ],
  "operation": "histogram"
}
```

## Convert the aggregatable report into Avro binary representation

サンプルレポートは、暗号化されていない `debug_cleartext_payload` のリストで、 LocalTestingTool_0.3.0.jar で処理することが可能。

ローカルおよび AWS の Nitro Enclaves でアグリゲーションサービスをテストする場合、次のレコードスキーマを持つ Avro バッチが期待される。

### `reports.avsc`

```avro
{
  "type": "record",
  "name": "AggregatableReport",
  "fields": [
    {
      "name": "payload",
      "type": "bytes"
    },
    {
      "name": "key_id",
      "type": "string"
    },
    {
      "name": "shared_info",
      "type": "string"
    }
  ]
}
```

avro の `payload` フィールドは以下

- ローカルテストでは `debug_cleartext_payload` フィールドのバイト配列 (`base64` でエンコード)
- Nitro Enclaves では `aggregation_service_payloads` オブジェクトの `payload` フィールドの暗号化バイナリ

## Collect, transform and batch reports

### Listen on predefined endpoints

Attribution Reporting API のデバッグを有効にすると、レポートに追加のフィールドが存在し、デバッグレポートの複製が直ちに送信される。

以下の 2 つの定義済みエンドポイントを使用

1. `.well-known/attribution-reporting/report-aggregate-attribution` は、暗号化されたペイロードを持つ、遅延レポート用です。デバッグが有効な場合、平文のペイロードも含まれます。
1. `.well-known/attribution-reporting/debug/report-aggregate-attribution` は、通常のレポートと重複するデバッグレポートですが、生成時に即座に送信されるものです。


まず、これから扱うすべての型を定義します。


```go
// ブラウザが生成する Attribution Reporting API
type AggregatableReport struct {
  SourceSite             string `json:"source_site"`
  AttributionDestination string `json:"attribution_destination"`
  // SharedInfo は JSON 文字列で、復号化のための認証データとして使用されるため、そのまま Aggregation に転送される必要がある。
  // Reporting Origin は、文字列を解析してエンコードされたフィールドにアクセスすることができます。
  // https://github.com/WICG/conversion-measurement-api/blob/main/AGGREGATE.md#aggregatable-reports
  SharedInfo                 string                       `json:"shared_info"`
  AggregationServicePayloads []*AggregationServicePayload `json:"aggregation_service_payloads"`

  SourceDebugKey  uint64 `json:"source_debug_key,string"`
  TriggerDebugKey uint64 `json:"trigger_debug_key,string"`
}

// AggregationServicePayload contains the payload for the aggregation server.
type AggregationServicePayload struct {
  // Payload is a encrypted CBOR serialized instance of struct Payload, which is base64 encoded.
  Payload               string `json:"payload"`
  KeyID                 string `json:"key_id"`
  DebugCleartextPayload string `json:"debug_cleartext_payload,omitempty"`
}
```

Aggregatable report in Avro format, as expected by the aggregation service (you'll need to import [gopkg.in/avro.v0](https://pkg.go.dev/gopkg.in/avro.v0))

アグリゲーションサービスが期待する Avro 形式の Aggregatable レポート(インポートする必要があります [gopkg.in/avro.v0](https://pkg.go.dev/gopkg.in/avro.v0))

```go
// AvroAggregatableReport format expected by aggregation service and local testing tool
type AvroAggregatableReport struct {
  Payload    []byte `avro:"payload"`
  KeyID      string `avro:"key_id"`
  SharedInfo string `avro:"shared_info"`
}
```

では、リクエストハンドラを登録し、http サーバを起動してみましょう。

```go
func main() {
  http.HandleFunc("/.well-known/attribution-reporting/report-aggregate-attribution", collectEndpoint)
  http.HandleFunc("/.well-known/attribution-reporting/debug/report-aggregate-attribution", collectEndpoint)
  var address = ":3001"
  log.Printf("Starting Collector on address %v", address)
  log.Fatal(http.ListenAndServe(address, nil))
}
```

そして、`HandlerFunc` の実装で、受信したレポートをどのように処理するかを説明します。

```go
func collectEndpoint(w http.ResponseWriter, r *http.Request) {
 var timeStr = time.Now().Format(time.RFC3339)
 if r.Method == "POST" {
  var endpoint = "regular"
  if strings.Contains(r.URL.Path, ".well-known/attribution-reporting/debug/report-aggregate-attribution") {
   endpoint = "debug"
  }

  // 受信したレポートの JSON でシリアライズ
  log.Printf("Received Aggregatable Report on %s endpoint", endpoint)
  report := &AggregatableReport{}
  buf := new(bytes.Buffer)
  buf.ReadFrom(r.Body)
  log.Print(buf.String())
  if err := json.Unmarshal(buf.Bytes(), report); err != nil {
   errMsg := "Failed in decoding aggregation report"
   http.Error(w, errMsg, http.StatusBadRequest)
   log.Printf(errMsg+" %v", err)
   return
  }


  // Avro のスキーマ準備
  schema, err := avro.ParseSchema(reports_avsc)
  check(err)

  // ファイル作成 (output_reports.avro)
  f, err := os.Create(fmt.Sprintf("output_%s_reports_%s.avro", endpoint, timeStr))
  check(err)
  defer f.Close()
  w := bufio.NewWriter(f)

  // Avro の writer 用意
  writer, err := avro.NewDataFileWriter(w, schema, avro.NewSpecificDatumWriter())
  check(err)
  var dwriter *avro.DataFileWriter
  var dw *bufio.Writer

  if (len(report.AggregationServicePayloads) > 0 && len(report.AggregationServicePayloads[0].DebugCleartextPayload) > 0) {
   // Debug が有効で平文があったら 

   // ファイル作成(output_clear_text_reports.avro)
   df, err := os.Create(fmt.Sprintf("output_%s_clear_text_reports_%s.avro", endpoint, timeStr))
   check(err)
   defer df.Close()

   // 保存
   dw = bufio.NewWriter(df)
   dwriter, err = avro.NewDataFileWriter(dw, schema, avro.NewSpecificDatumWriter())
   check(err)
  }

  for _, payload := range report.AggregationServicePayloads {
   var payload_cbor []byte
   var err error

   // payload を b64 decode
   payload_cbor, err = b64.StdEncoding.DecodeString(payload.Payload)
   check(err)

   // Aggregatable Report を準備
   avroReport := &AvroAggregatableReport{
    Payload:    []byte(payload_cbor),
    KeyID:      payload.KeyID,
    SharedInfo: report.SharedInfo,
   }

   // output_reports に書き出し
   if err := writer.Write(avroReport); err != nil {
    log.Fatal(err)
   }

   if len(payload.DebugCleartextPayload) > 0 {
    // Debug が有効だったら
    payload_debug_cbor, err := b64.StdEncoding.DecodeString(payload.DebugCleartextPayload)
    check(err)

    // Aggregatable Report を準備
    avroDReport := &AvroAggregatableReport{
     Payload:    []byte(payload_debug_cbor),
     KeyID:      payload.KeyID,
     SharedInfo: report.SharedInfo,
    }
    if err := dwriter.Write(avroDReport); err != nil {
     log.Fatal(err)
    }
   }
  }
  writer.Flush()
  w.Flush()
  if dwriter != nil {
   dwriter.Flush()
   dw.Flush()
  }

 } else {
  http.Error(w, "Invalid request method.", http.StatusMethodNotAllowed)
  log.Print("Invalid request received.")
 }
```

Once an aggregatable report has been collected, they'll be stored in the file below.

集計可能なレポートが収集されると、それらは以下のファイルに保存されます。

- `output_regular_reports.avro`
- `output_debug_reports.avro`
- `output_regular_clear_text_reports.avro`
- `output_debug_clear_text_reports.avro`

## Process Avro batch files

保存した Avro ファイルを処理するためには、以下の Avro スキーマを持つドメインファイル `output_domain.avro` に、期待されるバケットキーを指定する必要があります。

### `output_domain.avsc`

```avro
{
  "type": "record",
  "name": "AggregationBucket",
  "fields": [
    {
      "name": "bucket",
      "type": "bytes",
      "doc": "A single bucket that appears in the aggregation service output. 128-bit integer encoded as a 16-byte big-endian bytestring."
    }
  ]
}
```

### Generate a output domain Avro file

avro-tools-1.11.1.jar を使って、 JSON 入力ファイル `output_domain.json` から `output_domain.avro` を生成することができます。

- http://archive.apache.org/dist/avro/avro-1.11.1/java/avro-tools-1.11.1.jar

上記の aggregatable report sample のバケットを使用しています。

```json
{
  "aggregation_service_payloads": [
    {
      "debug_cleartext_payload": "omRkYXRhgaJldmFsdWVEAACAAGZidWNrZXRQAAAAAAAAAAAAAAAAAAAFWWlvcGVyYXRpb25paGlzdG9ncmFt",
      "key_id": "e101cca5-3dec-4d4f-9823-9c7984b0bafe",
      "payload": "26/oZSjHABFqsIxR4Gyh/DpmJLNA/fcp43Wdc1/sblss3eAkAPsqJLphnKjAC2eLFR2bQolMTOneOU5sMWuCfag2tmFlQKLjTkNv85Wq6HAmLg+Zq+YU0gxF573yzK38Cj2pWtb65lhnq9dl4Yiz"
    }
  ],
  "attribution_destination": "http://shoes.localhost",
  "shared_info": "{
    \"debug_mode\": \"enabled\",
    \"privacy_budget_key\": \"OtLi6K1k0yNpebFbh92gUh/Cf8HgVBVXLo/BU50SRag=\",
    \"report_id\": \"00cf2236-a4fa-40e5-a7aa-d2ceb33a4d9d\",
    \"reporting_origin\": \"http://adtech.localhost:3000\",
    \"scheduled_report_time\": \"1649652363\",
    \"version\": \"\"
  }",
  "source_debug_key": "531933890459023",
  "source_registration_time": "1649635200",
  "source_site": "http://news.localhost",
  "trigger_debug_key": "531933890459023"
}
```


以下のサンプルでは、バイト配列のバケット値をエンコードするために、ユニコードでエスケープされた「characters」を使用しています。

### output_domain.json

```json
{
  "bucket": "\u0005Y"
}
```

To generate the `output_domain.avro` file use the above JSON file and domain schema file:

上記の JSON ファイルとドメインスキーマファイルを使用して、`output_domain.avro` ファイルを生成します。

```sh
java -jar avro-tools-1.11.1.jar \
  fromjson \
  --schema-file \
  output_domain.avsc \
  output_domain.json > output_domain.avro
```

### Produce a summary report locally

LocalTestingTool_0.3.0.jar を使って、サマリーレポートを作成できます。


We will run the tool, without adding noise to the summary report, to receive the expected value of `32768` from the [sample aggregatable report](#aggregatable-report-sample).

[集計可能なレポートのサンプル](#aggregatable-report-sample)　から `32768` を受け取るために、集計レポートにノイズを加えずに、ツールを実行することにします。


```sh
java -jar LocalTestingTool_0.3.0.jar \
  --input_data_avro_file output_debug_reports.avro \
  --domain_avro_file output_domain.avro \
  --json_output \
  --no_noising \
  --output_directory .
```


```sh
# ara-setup-demo/summry-reports/tools/magic.js 1:12:08
$ node magic.js
SourceKey: COUNT, CampaignID=12, GeoID=7, TriggerKey: ProductCategory=25
Hashed-Hex: 3cf867903fbb73ecf9e491fe37e55a0c
JSON unicode escaped: \u003c\u00f8\u0067\u0090\u003f\u00bb\u0073\u00ec\u00f9\u00e4\u0091\u00fe\u0037\u00e5\u005a\u000c
String: <øgsìùäþ7åZ

SourceKey: VALUE, CampaignID=12, GeoID=7, TriggerKey: ProductCategory=25
Hashed-Hex: 245265f432f16e73f9e491fe37e55a0c
JSON unicode escaped: \u0024\u0052\u0065\u00f4\u0032\u00f1\u006e\u0073\u00f9\u00e4\u0091\u00fe\u0037\u00e5\u005a\u000c
String: $Reô2ñnsùäþ7åZ

output_domain.json: 
{"bucket":"\u003c\u00f8\u0067\u0090\u003f\u00bb\u0073\u00ec\u00f9\u00e4\u0091\u00fe\u0037\u00e5\u005a\u000c"}
{"bucket":"\u0024\u0052\u0065\u00f4\u0032\u00f1\u006e\u0073\u00f9\u00e4\u0091\u00fe\u0037\u00e5\u005a\u000c"}
```

これを `output_domain.json` に保存する

```sh
java -jar avro-tools-1.11.1.jar \
  fromjson \
  --schema-file \
  output_domain.avsc \
  output_domain.json > output_domain.avro
```



これがバケットになる

```sh
# video: 1:16:18
$ java -jar LocalTestingTool_0.3.0.jar \
  --input_data_avro_file output_debug_clear_text_reports.avro \
  --domain_avro_file output_domain.avro \
  --no_noising \
  --output_directory .
$ file output.avro # summary report
$ java -jar avro-tools-1.11.1.jar tojson output.avro
{"bucket": "$Reô2ñnsùäþ7åZ", "metric": 8800}
{"bucket": "<øgsìùäþ7åZ", "metric": 65536}
```





The output of above tool execution will be in `output.json` with the following content

上記ツールの実行結果は、以下の内容で `output.json` に出力されます。

```json
[
  {
    "bucket": "\u0005Y",
    "value": 32768
  }
]
```
