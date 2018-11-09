
data "aws_security_group" "sg-master-kubernetes" {
  name   = "masters.${var.cluster_name}"
  vpc_id = "${data.terraform_remote_state.layer-base.vpc_id}"
}

data "aws_security_group" "sg-nodes-kubernetes" {
  name   = "nodes.${var.cluster_name}"
  vpc_id = "${data.terraform_remote_state.layer-base.vpc_id}"
}

resource "aws_security_group_rule" "allow_ssh_bastion_master" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${data.terraform_remote_state.layer-bastion.sg_bastion}"

  security_group_id = "${data.aws_security_group.sg-master-kubernetes.id}"
}

resource "aws_security_group_rule" "allow_ssh_bastion_nodes" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = "${data.terraform_remote_state.layer-bastion.sg_bastion}"

  security_group_id = "${data.aws_security_group.sg-nodes-kubernetes.id}"
}