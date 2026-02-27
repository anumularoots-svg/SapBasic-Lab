# Production — 40 Students
environment           = "prod"
student_count         = 40
student_instance_type = "m5.xlarge"
golden_ami_id         = "ami-PLACEHOLDER"
workspace_bundle_id   = "wsb-PLACEHOLDER"
nfs_gateway_ami_id    = "ami-PLACEHOLDER"
key_name              = "sap-training-key"
eod_stop_cron         = "cron(30 14 ? * MON-FRI *)"
morning_start_cron    = "cron(0 4 ? * MON-FRI *)"
enable_morning_start  = true
idle_timeout_minutes  = 30
idle_cpu_threshold    = 5
alert_email           = "anil@lanciere.com"
