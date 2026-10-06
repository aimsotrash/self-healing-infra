data "archive_file" "healer" {
  type        = "zip"
  source_file = "${path.module}/../lambda/heal_instance.py"
  output_path = "${path.module}/build/heal_instance.zip"
  # Fixed mode so the zip, and its hash, don't vary with the checkout's umask
  output_file_mode = "0644"
}

resource "aws_lambda_function" "healer" {
  function_name = "self-healing-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "heal_instance.lambda_handler"
  runtime       = "python3.10"

  filename         = data.archive_file.healer.output_path
  source_code_hash = data.archive_file.healer.output_base64sha256

  environment {
    variables = {
      INSTANCE_ID = aws_instance.web.id
    }
  }
}
