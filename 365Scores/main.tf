# Create the VPC
resource "aws_vpc" "Main" {
  cidr_block       = var.main_vpc_cidr
  instance_tenancy = "default"
}

# Create Internet Gateway and attach it to VPC
resource "aws_internet_gateway" "IGW" {
   vpc_id =  aws_vpc.Main.id
}

# Create a Public Subnets.
resource "aws_subnet" "publicsubnets" {
  vpc_id =  aws_vpc.Main.id

  # CIDR block of public subnets
  cidr_block = var.public_subnets
}

#Create a Private Subnet
resource "aws_subnet" "privatesubnets" {
  vpc_id =  aws_vpc.Main.id

  # CIDR block of private subnets
  cidr_block = var.private_subnets
}

#Route table for Public Subnet's
resource "aws_route_table" "PublicRT" {
  vpc_id =  aws_vpc.Main.id
  route {
    cidr_block = "0.0.0.0/0"        # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
  }
}

#Route table for Private Subnet's
resource "aws_route_table" "PrivateRT" {
  vpc_id = aws_vpc.Main.id
  route {
  cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
  nat_gateway_id = aws_nat_gateway.NATgw.id
  }
}

# Route table Association with Public Subnet's
resource "aws_route_table_association" "PublicRTassociation" {
   subnet_id = aws_subnet.publicsubnets.id
   route_table_id = aws_route_table.PublicRT.id
}

# Route table Association with Private Subnet's
resource "aws_route_table_association" "PrivateRTassociation" {
   subnet_id = aws_subnet.privatesubnets.id
   route_table_id = aws_route_table.PrivateRT.id
}

resource "aws_eip" "nateIP" {
  vpc   = true
}

# Creating the NAT Gateway using subnet_id and allocation_id
resource "aws_nat_gateway" "NATgw" {
  allocation_id = aws_eip.nateIP.id
  subnet_id = aws_subnet.publicsubnets.id
}

# Create security group
resource "aws_security_group" "allow_http_https" {
  name        = "allow_http_https"
  description = "Allow HTTP and HTTPS inbound traffic"
  vpc_id      = aws_vpc.Main.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.Main.cidr_block]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.Main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http_https"
  }
}

## Starting create certificate to HTTPS listener
# Create private key
resource "tls_private_key" "example" {
  algorithm = "RSA"
}

# Create self signed certificate
resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "365scorestest.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 10000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Create certificate
resource "aws_acm_certificate" "cert2" {
  private_key      = tls_private_key.example.private_key_pem
  certificate_body = tls_self_signed_cert.example.cert_pem
}

# Create new load balancer
resource "aws_elb" "elb" {

  name = "httpelb"

  # Attach our subnets and our security group to the ELB
  subnets = [
    aws_subnet.publicsubnets.id,
    aws_subnet.privatesubnets.id
  ]
  security_groups = [
    aws_security_group.allow_http_https.id
  ]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  # Create listeners to 80 and 443 ports
  listener {
   instance_port = 443
   instance_protocol = "https"
   lb_port = 443
   lb_protocol = "https"
   ssl_certificate_id = aws_acm_certificate.cert2.arn
  }

  health_check {
    healthy_threshold = 2
    interval = 30
    target = "HTTP:80/"
    timeout = 5
    unhealthy_threshold = 2
  }

  idle_timeout = 40
  tags = {
    Name = "elb"
  }
}

resource "aws_route53_zone" "primary" {
  name = "interview365test.com"
}


resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www"
  type    = "CNAME"

  alias {
    name                   = aws_elb.elb.dns_name
    zone_id                = aws_elb.elb.zone_id
    evaluate_target_health = true
  }

}
output "bla" {
  value = aws_elb.elb.dns_name
}