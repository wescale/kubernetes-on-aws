
data "aws_iam_policy_document" "aws-service-operator_policy" {
  statement {
    actions = [
      "sqs:*",
      "sns:*",
      "cloudformation:*",
      "ecr:*",
      "dynamodb:*",
      "s3:*"
    ]

    effect = "Allow"

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "aws-service-operator_policy" {
  name = "aws-service-operator_policy"
  role = "${aws_iam_role.aws-service-operator.id}"

  policy = "${data.aws_iam_policy_document.aws-service-operator_policy.json}"
}


resource "aws_iam_role" "aws-service-operator" {
  name = "aws-service-operator"

  assume_role_policy = "${data.aws_iam_policy_document.pods_assume_role_policy.json}"
}
