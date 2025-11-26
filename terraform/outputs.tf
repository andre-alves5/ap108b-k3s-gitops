output "trust_anchor_arn" {
  value = aws_rolesanywhere_trust_anchor.homelab.arn
}

output "profile_arn" {
  value = aws_rolesanywhere_profile.homelab.arn
}

output "role_arn" {
  value = aws_iam_role.ai_processor.arn
}

output "s3_bucket" {
  value = aws_s3_bucket.images.id
}

output "sqs_queue" {
  value = aws_sqs_queue.jobs.url
}