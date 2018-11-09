resource "aws_sns_topic" "alertmanager-sns" {
  name = "alertmanager-sns"
}

resource "aws_iam_policy_attachment" "sns-attach" {
  name       = "sns-attachment"
  roles      = ["${aws_iam_role.alertmanager_sns_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_iam_role" "alertmanager_sns_role" {
  name = "alertmanager_sns_role"

  assume_role_policy = "${data.aws_iam_policy_document.pods_assume_role_policy.json}"
}

resource "aws_sqs_queue" "test-alert-manager" {
  name = "test-alert-manager"
}

resource "aws_sns_topic_subscription" "sns-to-sqs" {
  topic_arn = "${aws_sns_topic.alertmanager-sns.arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.test-alert-manager.arn}"
}
