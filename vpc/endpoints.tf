data "aws_region" "current" {}
resource "aws_security_group" "vpce" {
  name   = "vpce"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  tags = {
    Environment = "dev"
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private.*.id

  tags = {
    Name        = "s3-endpoint"
    Environment = "dev"
  }
}

resource "aws_vpc_endpoint" "dkr" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpce.id,
  ]
  subnet_ids = aws_subnet.private.*.id

  tags = {
    Name        = "dkr-endpoint"
    Environment = "dev"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpce.id,
  ]
#  count          = length(var.private_subnets)
#  subnet_id      = element(aws_subnet.private.*.id, count.index)
  subnet_ids = [for sub in aws_subnet.private : sub.id]

  tags = {
    Name        = "logs-endpoint"
    Environment = "dev"
  }
}


resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpce.id,
  ]
#  count          = length(var.private_subnets)
#  subnet_id      = element(aws_subnet.private.*.id, count.index)
  subnet_ids = [for sub in aws_subnet.private : sub.id]

  tags = {
    Name        = "ssm-endpoint"
    Environment = "dev"
  }
}


resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpce.id,
  ]
#  count          = length(var.private_subnets)
#  subnet_id      = element(aws_subnet.private.*.id, count.index)
  subnet_ids = [for sub in aws_subnet.private : sub.id]

  tags = {
    Name        = "ecr-api-endpoint"
    Environment = "dev"
  }
}


resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    aws_security_group.vpce.id,
  ]
#  count          = length(var.private_subnets)
#  subnet_id      = element(aws_subnet.private.*.id, count.index)
  subnet_ids = [for sub in aws_subnet.private : sub.id]

  tags = {
    Name        = "ssmmessages-endpoint"
    Environment = "dev"
  }
}
