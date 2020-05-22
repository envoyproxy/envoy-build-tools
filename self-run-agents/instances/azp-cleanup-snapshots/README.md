# AZP Cleanup Snapshots #

By default our AMI Building Tool "Packer", leaves around snapshots indefinitely
along with the AMIs it builds. The goal of this lambda is to run every day,
find any AMIs that aren't used, as well as snapshots, and delete them.

This is just a cost savings measure even though snapshots are relatively cheap
there is no reason to be paying for them.