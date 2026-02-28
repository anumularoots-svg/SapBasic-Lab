# POC — 5 Students
environment           = "poc"
student_count         = 2
student_instance_type = "m5.xlarge"
golden_ami_id         = "ami-019987df9e7343ce4"
workspace_bundle_id   = "wsb-gk1wpk43z"
nfs_gateway_ami_id    = "ami-08cd2167bcac2f8a2"
key_name              = "sap-training-key"
eod_stop_cron         = "cron(30 14 ? * MON-FRI *)"
morning_start_cron    = "cron(0 4 ? * MON-FRI *)"
enable_morning_start  = true
idle_timeout_minutes  = 30
idle_cpu_threshold    = 5
alert_email           = "anil@lanciere.com"
