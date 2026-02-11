resource "aws_cloudwatch_metric_alarm" "nginx_down_alarm" {
  alarm_name          = "nginx-down"
  comparison_operator = "LessThanThreshold"

  metric_name = "NginxRunning"
  namespace   = "Custom/Nginx"

  statistic = "Minimum"
  period    = 60
  threshold = 1

  evaluation_periods  = 1
  datapoints_to_alarm = 1

  treat_missing_data = "breaching"

  alarm_actions = [aws_lambda_function.healer.arn]
}
