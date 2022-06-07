variable "lambda_function_name" {
  default = "test-lambda-tf"
}


resource "aws_iam_policy" "lambda_logging_tf_policy" {
  name        = "lambda_logging_tf_policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_role_tf" {
  name = "lambda_role_tf"

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

resource "aws_iam_role_policy_attachment" "attach_lambda_logs" {
  role       = aws_iam_role.lambda_role_tf.name
  policy_arn = aws_iam_policy.lambda_logging_tf_policy.arn
}

resource "aws_cloudwatch_log_group" "cw_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

resource "aws_s3_bucket" "test_bucket_tf" {
  bucket = "my-tf-test-bucket-1167"
}

resource "aws_iam_policy" "s3_access_policy_tf" {
  name = "s3_access_policy_tf"
  description = "IAM policy for accessing S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.test_bucket_tf.arn}",
        "${aws_s3_bucket.test_bucket_tf.arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_lambda_s3" {
  role       = aws_iam_role.lambda_role_tf.name
  policy_arn = aws_iam_policy.s3_access_policy_tf.arn
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "index.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role_tf.arn
  handler       = "index.handler"
  runtime = "python3.9"
  depends_on = [
    aws_iam_role_policy_attachment.attach_lambda_logs,
    aws_cloudwatch_log_group.cw_logs,
  ]
  environment {
    variables = {
      bucket = aws_s3_bucket.test_bucket_tf.id
    }
  }
  source_code_hash = filebase64sha256("index.zip")
}
