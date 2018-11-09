resource "aws_api_gateway_account" "demo_account_settings" {
  cloudwatch_role_arn = "${aws_iam_role.demo_role_cloudwatch_for_apigateway.arn}"
}
