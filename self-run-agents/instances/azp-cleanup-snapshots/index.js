const AWS = require('aws-sdk');
const ec2 = new AWS.EC2();

async function describeAmis() {
  return await new Promise((resolve, reject) => {
    ec2.describeImages(
      {
        Filters: [
          {
            Name: 'image-type',
            Values: ['machine'],
          },
          {
            Name: 'owner-id',
            Values: ['457956385456'],
          },
          {
            Name: 'state',
            Values: ['available'],
          },
        ],
      },
      (err, data) => {
        if (err != null) {
          reject(err);
        } else {
          resolve(data);
        }
      },
    );
  });
}

function extractLatestTemplateFromList(launchTemplates) {
  return launchTemplates
    .sort((comp, compTwo) => {
      if (comp.VersionNumber < compTwo.VersionNumber) {
        return -1;
      } else if (comp.VersionNumber > compTwo.VersionNumber) {
        return 1;
      } else {
        return 0;
      }
    })
    .slice(-1)[0];
}

async function latestLTVersionTailRec(launchTemplateId, nextToken = null) {
  const data = await new Promise((resolve, reject) => {
    ec2.describeLaunchTemplateVersions(
      {
        LaunchTemplateId: launchTemplateId,
        NextToken: nextToken == null ? undefined : nextToken,
      },
      (err, data) => {
        if (err != null) {
          reject(err);
        } else {
          resolve(data);
        }
      },
    );
  });

  if (data.NextToken != null && data.NextToken != '') {
    return await latestLTVersionTailRec(launchTemplateId, data.NextToken);
  } else {
    return extractLatestTemplateFromList(data.LaunchTemplateVersions);
  }
}

/**
 * Determine if an AMI is the latest in a launch template.
 *
 * @param {String} imageId
 *  The AMI ID to check on.
 */
async function amiIsUsedLatestTemplate(imageId) {
  const launchTemplates = await new Promise((resolve, reject) => {
    ec2.describeLaunchTemplates({}, (err, data) => {
      if (err != null) {
        reject(err);
      } else {
        resolve(data);
      }
    });
  });

  let isUsed = false;
  let seenTemplates = [];
  for (let template of launchTemplates.LaunchTemplates) {
    if (seenTemplates.indexOf(template.LaunchTemplateId) == -1) {
      let latestVersion = await latestLTVersionTailRec(
        template.LaunchTemplateId,
      );
      if (latestVersion['LaunchTemplateData']['ImageId'] == imageId) {
        isUsed = true;
        return isUsed;
      }
      seenTemplates.push(template.LaunchTemplateId);
    }
  }
  return isUsed;
}

/**
 * Determine if an AMI is being used by an EC2 instance actively.
 *
 * @param {String} imageId
 *  The AMI ID to check on.
 */
async function amiIsUsedInstance(imageId) {
  const instances = await new Promise((resolve, reject) => {
    ec2.describeInstances(
      {
        DryRun: false,
        Filters: [
          {
            Name: 'image-id',
            Values: [imageId],
          },
        ],
        // We only need to know if 1 is in used, but the minimum is 5.
        MaxResults: 5,
      },
      (err, data) => {
        if (err != null) {
          reject(err);
        } else {
          resolve(data);
        }
      },
    );
  });

  return instances['Reservations'] != null && instances.Reservations.length > 0;
}

exports.handler = async function (_, context) {
  try {
    const amiResp = await describeAmis();

    // Find all AZP AMIs.
    const azpAmis = amiResp.Images.filter((image) => {
      if (image['Tags'] == null) {
        return false;
      }

      let has_envoy_project_tag = false;
      image['Tags'].forEach((tagObj) => {
        if (tagObj['Key'] != 'Project') {
          return;
        }
        if (tagObj['Value'].indexOf('envoy-azp-') != 0) {
          return;
        }
        has_envoy_project_tag = true;
      });

      return has_envoy_project_tag;
    });

    // Find all unused AZP AMIs.
    let defunctAmis = [];
    for (let amiObj of azpAmis) {
      const amiID = amiObj.ImageId;

      const isUsedInstance = await amiIsUsedInstance(amiID);
      if (isUsedInstance) {
        console.log('Found AMI being used by instances:', amiID);
        continue;
      }
      const isUsedTemplates = await amiIsUsedLatestTemplate(amiID);
      if (isUsedTemplates) {
        console.log('Found AMI being used in the latest template:', amiID);
        continue;
      }

      defunctAmis.push(amiObj);
    }

    // Delete AMIs + Snapshots.
    for (let amiObj of defunctAmis) {
      console.log('Found Defunct AMI: ', amiObj.ImageId);
      const amiID = amiObj.ImageId;
      const snapshotIDs = amiObj.BlockDeviceMappings.filter(
        (bdm) => bdm['Ebs'] != null && bdm['Ebs']['SnapshotId'] != null,
      ).map((bdm) => bdm.Ebs.SnapshotId);
      console.log(
        'Deleting AMI: ',
        amiID,
        ' and associated snapshot IDs: ',
        snapshotIDs,
      );

      // Deregister the image.
      await new Promise((resolve, reject) => {
        ec2.deregisterImage(
          {
            ImageId: amiID,
          },
          (err) => {
            if (err != null) {
              reject(err);
            } else {
              resolve();
            }
          },
        );
      });

      for (let snapshotID of snapshotIDs) {
        await new Promise((resolve, reject) => {
          ec2.deleteSnapshot(
            {
              SnapshotId: snapshotID,
            },
            (err) => {
              if (err != null) {
                reject(err);
              } else {
                resolve();
              }
            },
          );
        });
      }
    }

    context.succeed();
  } catch (error) {
    console.log('Failed to Cleanup AMIs: ', error, error.stack);
    context.fail();
  }
};
