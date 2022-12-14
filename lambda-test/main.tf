terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  
  backend "s3" {
    bucket = "aws-lambda-tf-test"
    key    = "state.tfstate"
    region = "us-west-1"
  }
}


provider "aws" {
  region  = "us-west-1"
}

### Cloud Function
data "archive_file" "source_code" {
  type        = "zip"
  output_path = "${path.module}/lambda_function_payload.zip"
  source_dir  = "${path.module}/source_code"
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function_url" "test_latest" {
  function_name      = aws_lambda_function.test_lambda.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a 
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "hello_world"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "main.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256(data.archive_file.source_code.output_path)

  runtime = "python3.9"

}


output "lambda_url" {
  value = aws_lambda_function_url.test_latest.function_url
}