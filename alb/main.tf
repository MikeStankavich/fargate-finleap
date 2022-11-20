resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  subject_alternative_names = ["${var.name}.${var.domain}"]
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#│ Error: creating ELBv2 Listener (arn:aws:elasticloadbalancing:us-west-2:252374924199:loadbalancer/app/ecs-private-no-nat-alb-test/5ea507fa7e38f4ef):
#  UnsupportedCertificate: The certificate 'arn:aws:acm:us-west-2:252374924199:certificate/627fa302-4000-453c-be68-d4f68d2b964d' must have 
#  a fully-qualified domain name, a supported signature, and a supported key size.
#│ 	status code: 400, request id: f8da4241-5a98-4124-9ce5-de8ed955594f
#│
#│   with module.alb.aws_alb_listener.https,
#│   on alb/main.tf line 57, in resource "aws_alb_listener" "https":
#│   57: resource "aws_alb_listener" "https" {


data "aws_route53_zone" "primary" {
  name         = var.domain
  private_zone = false
}

resource "aws_route53_record" "validation" {
  #    name            = aws_acm_certificate.cert.domain_validation_options[0]["name"]
  #    records         = [aws_acm_certificate.cert.domain_validation_options[0]["record"]]
  #    ttl             = 60
  #    type            = aws_acm_certificate.cert.domain_validation_options[0]["type"]
  for_each = {
  for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
  }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.zone_id
}

resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate_validation" "val" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_lb" "main" {
  name               = "${var.name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.alb_security_groups
  subnets            = var.subnets.*.id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.name}-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "main" {
  name        = "${var.name}-tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = var.health_check_path
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${var.name}-tg-${var.environment}"
    Environment = var.environment
  }
}

# Redirect to https listener
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Redirect traffic to target group
resource "aws_alb_listener" "https" {
    load_balancer_arn = aws_lb.main.id
    port              = 443
    protocol          = "HTTPS"

    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = aws_acm_certificate.cert.arn
    
    default_action {
        target_group_arn = aws_alb_target_group.main.id
        type             = "forward"
    }
}

output "aws_alb_target_group_arn" {
  value = aws_alb_target_group.main.arn
}
