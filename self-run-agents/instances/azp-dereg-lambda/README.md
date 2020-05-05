# AZP Deregistration Lambda

A lambda function that listens for instances being destroyed, and properly
deregisters them from Azure Pipelines, so they don't clutter up the UI, or
potentially try to schedule on nodes that are no longer running.

This uses ASG Lifecycle Hooks, published to an SNS Queue in order to know
when an instance has been destroyed.
