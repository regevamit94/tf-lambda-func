output "private_key" {
  value     = tls_private_key.my-private-key.private_key_pem
  sensitive = true
  description = "The private key the related to the public key created inside the instance"
}

output my_api_url {
  value       = aws_apigatewayv2_api.my_http_api.api_endpoint
  sensitive   = false
  description = "This is the url that should be used to invoke the API"
}
