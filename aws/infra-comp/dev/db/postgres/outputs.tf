output "database-address" {
  value = aws_db_instance.pg-database.address
}

output "database-port" {
  value = aws_db_instance.pg-database.port
}
