provider "aws" {
  region                  = "us-east-1"
  profile                 = "linuxacademy"
}
data "aws_region" "current" {}
locals {
    filename          = "function/lambda_fuction.zip"
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "function/"
  output_path = "function/lambda_fuction.zip"
}
###Create Lambda function #########
resource "aws_lambda_function" "default" {
  function_name            =  "python-lambda-function"
  description              = "Lambda function in VPC to auto rotate RDS credentials"
  filename                 = local.filename
  source_code_hash = "${data.archive_file.source.output_base64sha256}"
  #source_code_hash         = filebase64sha256("${local.filename}")
  handler                  = "lambda_function.lambda_handler"
  runtime                  = "python3.7"
  timeout                  = 30
  role                     = aws_iam_role.default.arn
  #}
  #https://docs.aws.amazon.com/general/latest/gr/rande.html#asm_region
  #environment {
  #  variables = { 
  #    SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
  #  }
  #}
}

resource "aws_iam_role" "default" {
  name                     =   "lambdaFunc-iamRole"
  assume_role_policy       = data.aws_iam_policy_document.service.json
}
resource "aws_iam_role_policy_attachment" "lambda-basic" { 
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ec2access" {
  name   = "ec2aceess"
  role   = aws_iam_role.default.name
  policy = data.aws_iam_policy_document.ec2access.json
}

data "aws_iam_policy_document" "service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2access" {
  statement {
    actions = [
      "ec2:*",
    ]
    resources = [
      "*",
    ]
  }
}
