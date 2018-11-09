variable "es_log_domain" {
  default = "logs-applicatif"
}

data "aws_iam_policy_document" "elasticsearch_access_policy" {
  statement {
    actions = ["es:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    effect    = "Allow"
    resources = ["arn:aws:es:${var.region}:${var.account_id}:domain/${var.es_log_domain}/*"]

    // condition {
    //   test     = "StringEquals"
    //   variable = "aws:SourceVpc"

    //   values = [
    //     "${aws_vpc.demo_vpc.id}",
    //   ]
    // }
  }
}

resource "aws_cloudwatch_log_group" "es_logs" {
  name = "es_logs"
}

resource "aws_security_group" "allow_es_connexion" {
  name        = "allow_es_connexion"
  description = "Allow ES traffic"
  vpc_id      = "${aws_vpc.demo_vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags {
    Name = "sg_for_elasticsearch"
  }
}

resource "aws_elasticsearch_domain" "es-log" {
  domain_name           = "${var.es_log_domain}"
  elasticsearch_version = "6.3"

  cluster_config {
    instance_type  = "i3.large.elasticsearch"
    instance_count = 1
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = "${data.aws_iam_policy_document.elasticsearch_access_policy.json}"

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  log_publishing_options {
    enabled                  = false
    log_type                 = "ES_APPLICATION_LOGS"
    cloudwatch_log_group_arn = "${aws_cloudwatch_log_group.es_logs.arn}"
  }

  vpc_options {
    security_group_ids = [
      "${aws_security_group.allow_es_connexion.id}",
    ]

    subnet_ids = [
      "${aws_subnet.demo_sn_private_a.id}",
    ]
  }

  tags {
    Utility = "logs"
  }
}

resource "aws_route53_record" "es-dns" {
  zone_id = "${aws_route53_zone.demo_private_zone.zone_id}"
  name    = "es.${var.private_dns_zone}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_elasticsearch_domain.es-log.endpoint}"]
}


