output "vpc_id"            { value = module.vpc.vpc_id }
output "directory_id"      { value = module.directory.directory_id }
output "registration_code" { value = module.directory.registration_code }
output "student_ec2_ips"   { value = module.student_ec2.student_ip_map }
output "student_ec2_ids"   { value = module.student_ec2.student_id_map }
output "nfs_gateway_ip"    { value = module.nfs_gateway.private_ip }
output "self_service_api_url" { value = module.self_service.api_url }

output "connection_info" {
  value = <<-EOT
  ══════════════════════════════════════
   SAP Training Lab — Connection Info
  ══════════════════════════════════════
   Client:     https://clients.amazonworkspaces.com/
   Reg Code:   ${module.directory.registration_code}
   Login:      student01..${format("student%02d", var.student_count)}
   SAP User:   sapuser / SapLab@2026
   API:        ${module.self_service.api_url}
   NFS GW:     ${module.nfs_gateway.private_ip}
  ══════════════════════════════════════
  EOT
}
