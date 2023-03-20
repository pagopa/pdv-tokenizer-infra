locals {
  api_key_list = { for k in var.tokenizer_plans : k.key_name => k }

  additional_keys = flatten([for k in var.tokenizer_plans :
    [for a in k.additional_keys :
      {
        "key" : a
        "plan" : k.key_name
    }]
  ])

}

resource "aws_api_gateway_api_key" "main" {
  for_each = local.api_key_list
  name     = each.key
}

# Temporary change to allow interop to share selfcare namespace.
resource "aws_api_gateway_api_key" "additional" {
  for_each = { for k in local.additional_keys : k.key => k }
  name     = each.key
}