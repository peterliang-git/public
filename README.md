## start docker engine through docker desktop
download localstack and extract it to a folder(d:\localstack)
download terraform and extract it ot a folder(d:\terraform)
set path to those two folders
localstack start - this will start docker container and if it's not there, it will pull the image
## AWS CLI V2 and other Apps
download aws cli v2 and install the msi.
download python and install it.
download go and install.
## VSCode
open vscode and install docker extension
create a folder and create file with name docker-compose.yaml, copy content from localstack installation doc for docker compose
in vscode terminal run docker compose up - it used docker-compose.yaml
in docker desktop, the container should be up running
## Terraform
create terraform\localstack folder in vscode and create a main.tf file there.
update main.tf file provider "aws" section, use test/test and us-east-1 as awd, then define endpoint and resources.
in terminal, cd to that folder and run terraform init - create some other files.
then run terraform plan
if it looks good, run terraform apply - deploy to lackstack
## using aws cli to call some services
aws cli can use endpoint to call localstack
aws s3 cp go.mod s3://my-bucket/ --endpoint=http://localhost:4566 
aws s3 ls s3://my-bucket/ --endpoint=http://localhost:4566 
s3/main.go return go.mod file content
sqs/main.go send a message to sqs queue
aws sqs receive-message --queue-url http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/event-sqs-queue --endpoint=http://localhost:4566
## Other
awdcli_local is a localstack wrapper of aws cli that use localstack endpoint so you don't need to provided it.
to zip lambda file, use tar -a -c -f xyz.zip xyz.py
to unzip tar -xf xyz.zip
use terraform archive_file to zip lambda
