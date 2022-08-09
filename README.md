# Set up Aggregation Service for Aggregatable Reports

**[NOTE] The latest aggregatable reports generated with Chrome version 104+ are only supported with version `0.3.0` and later. Please follow the [update instructions](#updating-the-system) for your environment.**

**【注意】Chrome バージョン 104+ で生成される最新の集計可能レポートは、バージョン `0.3.0` 以降でのみサポートされます。**

This repository contains instructions and scripts to set up and test the Aggregation Service for [Aggregatable Reports](https://github.com/WICG/conversion-measurement-api/blob/main/AGGREGATION_SERVICE_TEE.md#aggregatable-reports) locally and on Amazon Web Services [Nitro Enclaves](https://aws.amazon.com/ec2/nitro/nitro-enclaves/). If you want to learn more about the [Privacy Sandbox](https://privacysandbox.com/) Aggregation Service for the Attribution Reporting API, aggregatable, and summary reports click, read the [Aggregation Service proposal](https://github.com/WICG/conversion-measurement-api/blob/main/AGGREGATION_SERVICE_TEE.md#aggregatable-reports).

このリポジトリには、ローカルおよび Amazon Web Services Nitro Enclaves 上で Aggregatable Reports 用の Aggregation Service をセットアップしてテストするための手順とスクリプトが含まれています。アトリビューションレポート API、アグリゲータブル、およびサマリーレポートのクリックのためのプライバシーサンドボックス アグリゲーションサービスについてもっと知りたい場合は、アグリゲーションサービス提案書 をお読みください。

## Set up local testing

You can process [aggregatable debug reports](https://github.com/WICG/conversion-measurement-api/blob/main/AGGREGATE.md#aggregatable-reports) locally with the [LocalTestingTool.jar](https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/0.3.0/LocalTestingTool_0.3.0.jar) into summary reports.

ローカルで LocalTestingTool.jar を使って、 aggregatable debug reports をサマリーレポートに加工することが可能です。

Learn [how to setup debug reports](https://docs.google.com/document/d/1BXchEk-UMgcr2fpjfXrQ3D8VhTR-COGYS1cwK_nyLfg/edit#heading=h.fvp017tkgw79).

デバッグレポートの設定方法をご覧ください。

_Disclaimer: encrypted reports can **not** be processed with the local testing tool!_

免責事項:暗号化されたレポートは、ローカルのテストツールで処理することはできません。

### Using the local testing tool

[Download the local testing tool](https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/0.3.0/LocalTestingTool_0.3.0.jar).

ローカルテストツールのダウンロード。

You'll need [Java JRE](https://adoptium.net/) installed to use the tool.

本ツールを使用するには、Java JRE がインストールされている必要があります。

_The `SHA256` of the `LocalTestingTool_{version}.jar`is`f3da41b974341863b6d58de37b7eda34f0e9b85fe074ee829d41be2afea5d19a` obtained with`openssl sha256 <jar>`.\_

```
$ openssl sha256 LocalTestingTool_{version}.jar
f3da41b974341863b6d58de37b7eda34f0e9b85fe074ee829d41be2afea5d19a
```

Follow the instructions on how to [collect and batch aggregatable reports](#collect-and-batch-aggregatable-reports).

集計可能なレポートの収集とバッチ処理の方法について説明します。

Create an output domain file: `output_domain.avro`. For testing you can use our [sample debug batch](./sampledata/output_debug_reports.avro) with the corresponding [output domain avro](./sampledata/output_domain.avro).

出力ドメインファイル `output_domain.avro` を作成します。テスト用には、 `output_debug_reports.avro` と対応する `output_domain.avro` が使用できます。

To aggregate the resulting avro batch `output_debug_reports.avro` file into a summary report in the same directory where you run the tool, run the following command:

出力された avro バッチ `output_debug_reports.avro` ファイルを、ツールを実行したのと同じディレクトリにあるサマリーレポートに集約するには、以下のコマンドを実行します。

```sh
java -jar LocalTestingTool.jar \
--input_data_avro_file output_debug_reports.avro \
--domain_avro_file output_domain.avro \
--output_directory .
```

To see all supported flags for the local testing tool run `java -jar LocalTestingTool.jar --help`, e.g. you can adjust the noising epsilon with the `--epsilon` flag or disable noising all together with the `--no_noising` flag. [See all flags and descriptions](./API.md#local-testing-tool).

ローカルテストツールでサポートされているすべてのフラグを見るには、`java -jar LocalTestingTool.jar --help`を実行してください。例えば、`--epsilon` フラグでノイズのイプシロンを調整したり、 `--no_noise` フラグでノイズをすべて無効化したりすることができます。すべてのフラグと説明を見る。

## Test on AWS with support for encrypted reports

### General Notes

#### Privacy Budget Enforcement

The [no-duplicate](https://github.com/WICG/attribution-reporting-api/blob/main/AGGREGATION_SERVICE_TEE.md#no-duplicates-rule) rule is not enforced in the current test version but will be enforced in the future. We recommend users design their systems keeping the no-duplicate rule in consideration.

現在のテストバージョンでは、no-duplicate ルールは強制されていませんが、将来的に強制される予定です。ユーザは、重複禁止規則を考慮してシステムを設計することをお勧めします。

### Prerequisites

To test the aggregation service with support for encrypted reports, you need the following:

暗号化レポートをサポートしたアグリゲーションサービスをテストするためには、以下のものが必要です。

- Have an [AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) available to you.
- [Register](https://developer.chrome.com/origintrials/#/view_trial/771241436187197441) for the Privacy Sandbox Relevance and Measurement origin trial (OT)
- Complete the aggregation service [onboarding form](https://forms.gle/EHoecersGKhpcLPNA)

Once you've submitted the onboarding form, we will contact you to verify your information. Then, we'll send you the remaining instructions and information needed for this setup./br

オンボードフォームを送信していただいた後、お客様の情報を確認するため、弊社よりご連絡させていただきます。

_You won't be able to successfully setup your AWS system without registering for the origin trial and completing the onboarding process!_

_オリジントライアルに登録し、オンボーディングプロセスを完了しなければ、AWS システムのセットアップを成功させることはできません!_。

To set up aggregation service in AWS you'll use [Terraform](https://www.terraform.io/).

AWS にアグリゲーションサービスを設置するには、Terraform を利用することになります。

### Clone the repository

Clone the repository into a local folder `<repostory_root>`:

```sh
git clone https://github.com/google/trusted-execution-aggregation-service;
cd trusted-execution-aggregation-service
```

### Set up AWS client

Make sure you [install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [set up](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) the latest AWS client.

最新の AWS クライアントをインストール、セットアップしていることを確認してください。

### Set up Terraform

Change into the `<repository_root>/terraform/aws` folder.

`<repository_root>/terraform/aws` フォルダに移動します。

The setup scripts require terraform version `1.0.4`.

セットアップスクリプトは、terraform のバージョン `1.0.4` を必要とします。

You can download Terraform version 1.0.4 from https://releases.hashicorp.com/terraform/1.0.4/ or _at your own risk_, you can install and use [Terraform version manager](https://github.com/tfutils/tfenv) instead.

Terraform バージョン 1.0.4 は https://releases.hashicorp.com/terraform/1.0.4/ からダウンロードできますし、*自己責任*で、代わりに Terraform version manager をインストールして使用することも可能です。

If you have the Terraform version manager `tfenv` installed, run the following in your `<repository_root>` to set Terraform to version `1.0.4`.

Terraform のバージョン管理ツール `tfenv` をインストールしている場合は、`<repository_root>` で以下を実行して Terraform のバージョンを `1.0.4` に設定します。

```sh
tfenv install 1.0.4;
tfenv use 1.0.4
```

We recommend you store the [Terraform state](https://www.terraform.io/language/state) in a cloud bucket.

Terraform state は、クラウドバケットに保存することをお勧めします。

Create a S3 bucket via the console/cli, which we'll reference as `tf_state_bucket_name`.

コンソール/cli で S3 バケットを作成し、`tf_state_bucket_name`という名前で参照します。

### Download dependencies

The Terraform scripts depend on 5 packaged jars for Lambda functions deployment.

Terraform スクリプトは、Lambda ファンクションのデプロイ用に 5 つのパッケージ化された jar に依存しています。

These jars are hosted on Google Cloud Storage (https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/{version}/{jar_file}) and can be downloaded with the `<repository_root>/terraform/aws/download_dependencies.sh` script. The downloaded jars will be stored in `<repository_root>/terraform/aws/jars`.

これらの jar は Google Cloud Storage (https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/{version}/{jar_file}) でホストされており、 `<repository_root>/terraform/aws/download_dependencies.sh` スクリプトでダウンロードすることができます。ダウンロードされた jar は `<repository_root>/terraform/aws/jars` に格納されます。

License information of downloaded dependencies can be found in the [DEPENDENCIES.md](./DEPENDENCIES.md)

ダウンロードした依存関係のライセンス情報は、DEPENDENCIES.md に記載されています。

Run the following script in the `<repository_root>/terraform/aws` folder.

`<repository_root>/terraform/aws`フォルダーにある以下のスクリプトを実行します。

```sh
sh ./download_dependencies.sh
```

For manual download into the `<repository_root>/terraform/aws/jars` folder you can download them from the links below. The `sha256` was obtained with `openssl sha256 <jar>`.

手動で `<repository_root>/terraform/aws/jars` フォルダにダウンロードする場合は、以下のリンクからダウンロードすることができます。なお、`sha256`は `openssl sha256 <jar>` で取得したものである。

Caption: jar download link
| jar download link | sha256 |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| [AsgCapacityHandlerLambda_0.3.0.jar](https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/0.3.0/AsgCapacityHandlerLambda_0.3.0.jar) | `b06feee3fa4a8281d30b7c8f695a5ba6665da67276859a7305e2b2443e84af6b` |
| [AwsChangeHandlerLambda_0.3.0.jar](https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/0.3.0/AwsChangeHandlerLambda_0.3.0.jar) | `398496c30d80915ef1d1f7079f39670fdf57112f0f0528860959ebaf42bdf424` |
| [AwsFrontendCleanupLambda_0.3.0.jar](https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/0.3.0/AwsFrontendCleanupLambda_0.3.0.jar) | `1324679f3b56c40cb574311282e96c57d60878c89c607d09e6e2242fb914b47a` |
| [TerminatedInstanceHandlerLambda_0.3.0.jar](https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/0.3.0/TerminatedInstanceHandlerLambda_0.3.0.jar) | `491bdabc0c8a2249cc6a06d2fe4986c5580ed8466e9d26fd3791ca578e979565` |
| [aws_apigateway_frontend_0.3.0.jar](https://storage.googleapis.com/trusted-execution-aggregation-service-public-artifacts/0.3.0/aws_apigateway_frontend_0.3.0.jar) | `c619da0257f59fba3c3a0520ee8366643b4563ba049f820f621314fb0b516973` |

### Set up your deployment environment

We use the following folder structure `<repository_root>/terraform/aws/environments/<environment_name>` to separate deployment environments.

デプロイ環境を分けるために、以下のようなフォルダ構造 `<repository_root>/terraform/aws/environments/<environment_name>` を使用します。

To set up your first environment (e.g `dev`), copy the `demo` environment. Run the following commands from the `<repository_root>/terraform/aws/environments` folder:

最初の環境(例えば `dev`)をセットアップするために、`demo` 環境をコピーしてください。`<repository_root>/terraform/aws/environments`フォルダから、以下のコマンドを実行してください。

```sh
cp -R demo dev
cd dev
```

Make the following adjustments in the `<repository_root>/terraform/aws/environments/dev` folder:

`<repository_root>/terraform/aws/environments/dev`フォルダーで以下の調整を行います。

1. Add the `tf_state_bucket_name` to your `main.tf` by uncommenting and replacing the values using `<...>`:

1. `tf_state_bucket_name` を `main.tf` に追加します。コメントを解除して `<...>` で値を置き換えてください。

```sh
# backend "s3" {
#   bucket = "<tf_state_bucket_name>"
#   key    = "<environment_name>.tfstate"
#   region = "us-east-1"
# }
```

1. Rename `example.auto.tfvars` to `<environment>.auto.tfvars` and adjust the values with `<...>` using the information you received in the onboarding email. Leave all other values as-is for the initial deployment.

1. `example.auto.tfvars`を`<environment>.auto.tfvars`にリネームして、オンボーディングメールで受け取った情報をもとに`<...>` で値を調整します。その他の値は、最初のデプロイではそのままにしておきます。

```sh
environment = "<environment_name>"
...

assume_role_parameter = "<arn:aws:iam::example:role/example>"

...

alarm_notification_email = "<noreply@example.com>"
```

- environment: name of your environment
- assume_role_parameter: IAM role given by us in the onboarding email
- alarm_notification_email: Email to receive alarm notifications. Requires confirmation subscription through sign up email sent to this address.

1. Once you've adjusted the configuration, run the following in the `<repository_root>/terraform/aws/environments/dev` folder

1. 設定を調整したら、`<repository_root>/terraform/aws/environments/dev` フォルダで以下を実行します。

Install all Terraform modules:

Terraform の全モジュールをインストールします。

```sh
terraform init
```

Get an infrastructure setup plan:

インフラのセットアップ計画を立てる。

```sh
terraform plan
```

If you see the following output on a fresh project:

新しいプロジェクトで次のような出力が表示された場合。

```terraform
...
Plan: 128 to add, 0 to change, 0 to destroy.
```

you can continue to apply the changes (needs confirmation after the planning step)

変更を適用し続けることができます(計画ステップの後に確認が必要です)

```sh
terraform apply
```

If your see the following output, your setup was successful:

以下の出力が表示されれば、セットアップは成功です。

```terraform
...
Apply complete! Resources: 127 added, 0 changed, 0 destroyed.

Outputs:

create_job_endpoint = "POST https://xyz.execute-api.us-east-1.amazonaws.com/stage/v1alpha/createJob"
frontend_api_endpoint = "https://xyz.execute-api.us-east-1.amazonaws.com"
frontend_api_id = "xyz"
get_job_endpoint = "GET https://xyz.execute-api.us-east-1.amazonaws.com/stage/v1alpha/getJob"
```

The output has the links to the `createJob` and `getJob` API endpoints. These are authenticated endpoints, refer to the

出力には `createJob` と `getJob` の API エンドポイントへのリンクがあります。これらは認証されたエンドポイントです。

[Testing the System](#testing-the-system) section to learn how to use them.

システムのテストのセクションで、その使い方を学びます。

_If you run into any issues during deployment of your system, please consult the [Troubleshooting](#troubleshooting) and [Support](#support) sections._

_システムのデプロイ中に問題が発生した場合は、トラブルシューティングとサポートのセクションを参照してください_

### Testing the system

To test the system, you'll need encrypted aggregatable reports in avro batch format (follow the [collecting and batching instructions](#collect-and-batch-aggregatable-reports)) accessible by the aggregation service.

システムをテストするには、アグリゲーションサービスからアクセス可能な、avro バッチ形式の暗号化されたアグリゲーションレポート(収集とバッチの手順に従ってください)が必要となります。

1. Create an S3 bucket for your input and output data, we will refer to it as `data_bucket`. This bucket must be created in the same AWS account where you set up the aggregation service.

1. 入出力データ用の S3 バケットを作成します。ここでは、`data_bucket`と呼びます。このバケットは、アグリゲーションサービスをセットアップしたのと同じ AWS アカウントで作成する必要があります。

1. Copy your reports.avro with batched encrypted aggregatable reports to `<data_bucket>/input`. To experiment with sample data, you can use our [sample batch](./sampledata/output_reports.avro) with the corresponding [output domain avro](./sampledata/output_domain.avro).

1. バッチ化された暗号化された集計可能なレポートを含む reports.avro を `<data_bucket>/input` にコピーしてください。サンプルデータで実験するには、弊社の サンプルバッチ と対応する [出力ドメイン avro] (./sampledata/output_domain.avro) を使用することができます。

1. Create an aggregation job with the `createJob` API.

1. `createJob` API で集約ジョブを作成します。

`POST`

`https://<frontend_api_id>.execute-api.us-east-1.amazonaws.com/stage/v1alpha/createJob`

```json
{
  "input_data_blob_prefix": "input/reports.avro",
  "input_data_bucket_name": "<data_bucket>",
  "output_data_blob_prefix": "output/summary_report.avro",
  "output_data_bucket_name": "<data_bucket>",
  "job_parameters": {
    "attribution_report_to": "<your_attribution_domain>",
    "output_domain_blob_prefix": "domain/domain.avro",
    "output_domain_bucket_name": "<data_bucket>"
  },
  "job_request_id": "test01"
}
```

Note: This API requires authentication. Follow the [AWS instructions](https://aws.amazon.com/premiumsupport/knowledge-center/iam-authentication-api-gateway/) for sending an authenticated request.

注意:この API は認証が必要です。認証されたリクエストを送信するには、AWS instructions に従ってください。

1. Check the status of your job with the `getJob` API, replace values in `<...>`

1. `getJob` API でジョブの状態を確認し、`<...>`内の値を置き換えてください。

`GET` `https://<frontend_api_id>.execute-api.us-east-1.amazonaws.com/stage/v1alpha/getJob?job_request_id=test01`

Note: This API requires authentication. Follow the [AWS instructions](https://aws.amazon.com/premiumsupport/knowledge-center/iam-authentication-api-gateway/) for sending an authenticated request. [Detailed API spec](API.md#getjob-endpoint)

注意:この API は認証が必要です。認証されたリクエストを送信するには、AWS の説明書に従ってください。API 詳細仕様

### Updating the system

If the above setup was followed, you can update your system to the latest version by checking out the latest tagged version (currently `v0.3.0`) and running `terraform apply` in your environment folder (e.g. `<repository_root>/terraform/aws/environments/dev`).

上記の設定に従った場合、最新のタグ付きバージョン(現在 `v0.3.0`) をチェックアウトし、環境フォルダ (例: `<repository_root>/terraform/aws/environments/dev`) で `terraform apply` を実行すれば、システムを最新のバージョンに更新することが可能です。

Run the following in the `<repository_root>`.

`<repository_root>`で以下を実行します。

```sh
git fetch origin && git checkout -b dev-v0.3.0 v0.3.0
cd terraform/aws/environments/dev
terraform apply
```

If your see the following planning output for the update you can go ahead and apply.

アップデートの計画出力が以下のように表示されたら、そのまま応募してください。

```terraform
...

Plan: 0 to add, 14 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.
...
```

## Collect and batch aggregatable reports

Both the local testing tool and the aggregation service running on AWS Nitro Enclave expect aggregatable reports batched in the following [Avro](https://avro.apache.org/) format.

ローカルテストツールと AWS Nitro Enclave 上で動作するアグリゲーションサービスは、以下の Avro 形式でバッチされたアグリゲーションレポートを想定しています。

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

Additionally an output domain file is needed to declare all expected aggregation keys for aggregating the aggregatable reports (keys not listed in the domain file won't be aggregated)

さらに、集約可能なレポートを集約するために、期待されるすべての集約キーを宣言する出力ドメインファイルが必要です(ドメインファイルに記載されていないキーは集約されません)。

```avro
{
 "type": "record",
 "name": "AggregationBucket",
 "fields": [
   {
     "name": "bucket",
     "type": "bytes"
     /* A single bucket that appears in
     the aggregation service output.
     128-bit integer encoded as a
     16-byte big-endian byte string. */
   }
 ]
}
```

[Review code snippets](./COLLECTING.md) which demonstrate how to collect and batch aggregatable reports.

集計可能なレポートの収集とバッチ処理の方法を示す Review code snippets をご覧ください。

## Troubleshooting

The following error message points to a potential lack of instance availability.

次のエラーメッセージは、インスタンスの可用性が不足している可能性を指摘しています。

If you encounter this situation, run `terraform destroy` to remove your deployment and run `terraform apply` again.

このような状況になった場合は、`terraform destroy` を実行してデプロイメントを削除し、`terraform apply` を再度実行してください。

```txt
Error: Error creating Auto Scaling Group: ValidationError: You must use a valid
fully-formed launch template. Your requested instance type (m5.2xlarge) is not
supported in your requested Availability Zone (us-east-1e).
Please retry your request by not specifying an Availability Zone or choosing
us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1f.
```

## Support

You can reach out to us for support through creating issues on this repository or sending us an email at aggregation-service-support\<at>google.com.

このリポジトリで課題を作成するか、aggregation-service-supportatgoogle.com にメールを送ることでサポートに連絡することができます。

This address is monitored and only visible to selected support staff.

このアドレスは監視され、選ばれたサポートスタッフのみが見ることができます。

## General security notes

- The [VPC subnet property](./terraform/aws/services/worker/network.tf#L51) `map_public_ip_on_launch` is currently set to `true` which assigns a public IP address to all instances in the subnet. This allows for easier console access, yet is considered a risk and will be addressed in a future release.

- VPC subnet property](./terraform/aws/services/worker/network.tf#L51) `map_public_ip_on_launch` は現在 `true` に設定されており、サブネット内のすべてのインスタンスにパブリック IP アドレスを割り当てます。これはコンソールへのアクセスを容易にしますが、リスクがあると考えられるため、将来のリリースで対処される予定です。

- The worker [VPC security group](./terraform/aws/services/worker/network.tf#L99) currently allows for inbound connections on port 22 from any source IP. This is considered a risk and will be addressed in a future release.

- Worker VPC security group は現在、任意のソース IP からポート 22 でインバウンド接続を許可しています。これはリスクとみなされ、将来のリリースで対処される予定です。

## License

Apache 2.0 - See LICENSE for more information.

## FAQ

### Where should I post feedback/questions, this repo or the Attribution API repo?

This repo hosts an implementation of the [Attribution Reporting API](https://github.com/WICG/attribution-reporting-api). For feedback/questions encountered during using this particular aggregation service implementation, please use the support channels provided by this repo. For feedback/requests related to the APIs in general, please initiate discussions in the Attribution Reporting API repo.
