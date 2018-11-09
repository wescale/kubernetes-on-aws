resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = "${aws_vpc.demo_vpc.id}"

  tags {
    Name = "main"
  }
}

// resource "aws_customer_gateway" "customer_gateway" {
//   bgp_asn    = 65000
//   ip_address = "172.0.0.1"
//   type       = "ipsec.1"
// }


// resource "aws_vpn_connection" "main" {
//   vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.id}"
//   customer_gateway_id = "${aws_customer_gateway.customer_gateway.id}"
//   type                = "ipsec.1"
//   static_routes_only  = true
// }

