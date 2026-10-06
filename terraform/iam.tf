resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2_ssm_role"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_iam_role_policy" "ec2_put_metric" {
  name = "put-nginx-metric"
  role = aws_iam_role.ec2_ssm_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "cloudwatch:PutMetricData"
      # PutMetricData has no resource-level permissions; the namespace condition scopes it
      Resource  = "*"
      Condition = { StringEquals = { "cloudwatch:namespace" = "Custom/Nginx" } }
    }]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-healer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

locals {
  lambda_log_group_arn = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.healer.function_name}"
}

resource "aws_iam_policy" "lambda_ssm_policy" {
  name = "lambda-ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = [
          aws_instance.web.arn,
          "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        # The function's own log group, and the log streams in it
        Resource = [local.lambda_log_group_arn, "${local.lambda_log_group_arn}:*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ssm_policy.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healer.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"

  source_account = data.aws_caller_identity.current.account_id
  source_arn     = aws_cloudwatch_metric_alarm.nginx_down_alarm.arn

  depends_on = [
    aws_lambda_function.healer
  ]
}
