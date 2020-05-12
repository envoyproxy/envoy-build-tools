resource "aws_sns_topic" "lifecycle_updates" {
  name              = "azp-lifecycle-updates-topic"
  kms_master_key_id = "alias/aws/sns"
}