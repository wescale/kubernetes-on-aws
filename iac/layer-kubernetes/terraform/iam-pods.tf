data "aws_iam_policy_document" "pods_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/nodes.${var.cluster_name}"]
    }
  }
}

data "aws_iam_policy_document" "externalDNS_role_policy" {
  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    effect = "Allow"

    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]

    effect = "Allow"

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "externalDNS_role_policy" {
  name = "externalDNS_role_policy"
  role = "${aws_iam_role.externalDNS_role.id}"

  policy = "${data.aws_iam_policy_document.externalDNS_role_policy.json}"
}

resource "aws_iam_role" "externalDNS_role" {
  name = "externalDNS_role"

  assume_role_policy = "${data.aws_iam_policy_document.pods_assume_role_policy.json}"
}
