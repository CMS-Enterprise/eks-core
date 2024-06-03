module "secrets" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.1.2"

  for_each = { for k, v in var.secrets : k => v }

  create = true
  create_policy = true
  description = "Secret for ${each.key}"
  enable_rotation = false
  kms_key_id = module.secretsmanager_kms.key_id
  name = each.key
  random_password_length = 30
  recovery_window_in_days = 7
  secret_string = each.value

  tags = {
    Name = each.key
  }
}