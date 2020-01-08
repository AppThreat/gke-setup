output "connection_name" {
  value = google_sql_database_instance.cloudsql-db-master.connection_name
}

output "service_account" {
  value = google_sql_database_instance.cloudsql-db-master.service_account_email_address
}

output "cloudsql_ip" {
  value = google_sql_database_instance.cloudsql-db-master.ip_address.0.ip_address
}

output "cloudsql_key" {
  value = google_sql_ssl_cert.client_cert.private_key
}

output "cloudsql_server_cert" {
  value = google_sql_ssl_cert.client_cert.server_ca_cert
}

output "cloudsql_client_cert" {
  value = google_sql_ssl_cert.client_cert.cert
}

output "common_name" {
  value = google_sql_database_instance.cloudsql-db-master.server_ca_cert.0.common_name
}

output "sha1_fingerprint" {
  value = google_sql_database_instance.cloudsql-db-master.server_ca_cert.0.sha1_fingerprint
}

output "k8s_endpoint" {
  value = google_container_cluster.dtrack_prod_cluster.endpoint
}

output "k8s_master_version" {
  value = google_container_cluster.dtrack_prod_cluster.master_version
}

output "environment" {
  value = var.environment
}
