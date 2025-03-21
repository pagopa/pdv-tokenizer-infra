moved {
  from = aws_api_gateway_api_key.main["INTEROP-DEV"]
  to   = aws_api_gateway_api_key.additional["INTEROP-DEV"]
}

moved {
  from = aws_api_gateway_api_key.main["INTEROP-UAT"]
  to   = aws_api_gateway_api_key.additional["INTEROP-UAT"]
}

moved {
  from = aws_api_gateway_api_key.main["INTEROP"]
  to   = aws_api_gateway_api_key.additional["INTEROP"]
}

moved {
  from = module.dynamodb_table_token.aws_dynamodb_table.autoscaled[0]
  to   = module.dynamodb_table_token.aws_dynamodb_table.this[0]
}

moved {
  from = aws_cloutwatch_dashboard.main
  to   = aws_cloutwatch_dashboard.ms_tokenizer
}