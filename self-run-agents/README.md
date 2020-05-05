# Self Run AZP Agents #

This contains all the code necessary for creating our Self Hosted AZP Agents.
Right now this is done by creating AMI's with [Packer](https://www.packer.io/),
and then standing up all of the Infrastructure with
[Terraform](https://www.terraform.io/).

The general idea is:

  - AMIs are built with all necessary tooling (for linux this is just docker).
  - AMIs are referenced by a launch template for an ASG.

  - The ASG stands up a "minimum" number of instances to always be online to
    work builds.
  - A Target Tracking Policy watches the CPU Usage, and increases the size of
    the ASG when machines are working (indicated by the rise in CPU).

  - While a build is working the build should setup Instance Protection to
    ensure it doesn't get terminated while working. The instances have a role
    that allows them to do this.

  - When the ASG wants to scale down it fires off a lifecycle hook to an SNS
    topic. (Assuming Instance Protection hasn't been setup).
  - A Lambda watches the SNS Topic, and properly deregisters the agent from
    AZP, then lets the instance terminate.