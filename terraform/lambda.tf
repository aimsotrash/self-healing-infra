resource "aws_lambda_function" "healer" {
  function_name = "self-healing-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "heal_instance.lambda_handler"
  runtime       = "python3.10"

  filename         = "../lambda/heal_instance.zip"
  source_code_hash = filebase64sha256("../lambda/heal_instance.zip")

  environment {
    variables = {
      INSTANCE_ID = aws_instance.web.id
    }
  }
}
