resource "aws_iam_role" "demo_role" {
  name               = "demo_role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.demo_assume_role_policy.json}"
}

data "aws_iam_policy_document" "demo_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "demo_role_policy" {
  name = "demo_role_policy"
  role = "${aws_iam_role.demo_role.id}"

  policy = "${data.aws_iam_policy_document.demo_role_policy.json}"
}

data "aws_iam_policy_document" "demo_role_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "apigateway:Get",
    ]

    effect = "Allow"

    resources = ["*"]
  }

  statement {
    actions = ["lambda:InvokeFunction"]
    effect  = "Allow"

    resources = ["*"]
  }
}

resource "aws_iam_role" "demo_role_cloudwatch_for_apigateway" {
  name = "demo_role_cloudwatch_for_apigateway"

  assume_role_policy = "${data.aws_iam_policy_document.demo_assume_role_policy.json}"
}

resource "aws_iam_role_policy" "demo_role_cloudwatch_for_apigateway_policy" {
  name = "demo_role_cloudwatch_for_apigateway_policy"
  role = "${aws_iam_role.demo_role_cloudwatch_for_apigateway.id}"

  policy = "${data.aws_iam_policy_document.demo_role_cloudwatch_for_apigateway_policy_document.json}"
}

data "aws_iam_policy_document" "demo_role_cloudwatch_for_apigateway_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    effect = "Allow"

    resources = ["*"]
  }
}

output "iam_lambda_role" {
  value = "${aws_iam_role.demo_role.arn}"
}
