provider "aws" {
  region = "us-west-2"
}

data "aws_route53_zone" "selected" {
  name = "example.com"
}

module "ses" {
  source          = "../../"
  domain_name     = "mail.example.com"
  route53_zone_id = data.aws_route53_zone.selected.zone_id
}

output "ses_domain_identity_arn" {
  value = module.ses.domain_identity_arn
}
