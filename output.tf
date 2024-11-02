output "private_key" {
  value     = tls_private_key.my-private-key.private_key_pem
  sensitive = true
}