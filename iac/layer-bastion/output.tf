output "bastion_public_dns" {
  value = "${aws_instance.bastion.public_dns}"
}

output "sg_bastion" {
  value = "${aws_security_group.allow_ssh.id}"
}
