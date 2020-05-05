const axios = require('axios');
const AWS = require('aws-sdk');
const as = new AWS.AutoScaling();
const ec2 = new AWS.EC2();

const AZP_USER = process.env['AZP_USER'];
const AZP_TOKEN = process.env['AZP_TOKEN'];

function completeAsLifecycleAction(lifecycleParams, callback) {
  as.completeLifecycleAction(lifecycleParams, function (err, data) {
    if (err) {
      console.log('ERROR: AS lifecycle completion failed.\nDetails:\n', err);
      callback(err);
    } else {
      console.log(
        'INFO: CompleteLifecycleAction Successful.\nReported:\n',
        data,
      );
      callback(null);
    }
  });
}

function terminate(asgName, hookName, token, success, cb) {
  completeAsLifecycleAction(
    {
      AutoScalingGroupName: asgName,
      LifecycleHookName: hookName,
      LifecycleActionToken: token,
      LifecycleActionResult: success ? 'CONTINUE' : 'ABANDON',
    },
    cb,
  );
}

exports.handler = async function (notification, context) {
  const message = JSON.parse(notification.Records[0].Sns.Message);

  const asgName = message.AutoScalingGroupName;
  const lifecycleHookName = message.LifecycleHookName;
  const lifecycleToken = message.LifecycleActionToken;
  const instanceId = message.EC2InstanceId;

  try {
    // Extract the Azure Pool Name from the Instances Tags.
    const data = await new Promise((resolve, reject) => {
      ec2.describeInstances({ InstanceIds: [instanceId] }, function (
        err,
        data,
      ) {
        if (err != null) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
    const instance = data['Reservations'][0]['Instances'][0];
    const azpPoolName = instance['Tags'].filter((value) => {
      return value['Key'] == 'PoolName';
    })[0]['Value'];

    // Next turn the Azure Pool Name into an Azure Pool ID.
    const azpPoolId = await axios.get(
      `https://dev.azure.com/cncf/_apis/distributedtask/pools?poolName=${azpPoolName}&api-version=5.1`,
      {
        auth: {
          username: AZP_USER,
          password: AZP_TOKEN,
        },
      },
    )['data']['value'][0]['id'];

    // Finally turn the AZP Agent Name to an ID.
    const azpAgentId = await axios.get(
      `https://dev.azure.com/cncf/_apis/distributedtask/pools/${azpPoolId}/agents?agentName=${instanceId}&api-version=5.1`,
      {
        auth: {
          username: AZP_USER,
          password: AZP_TOKEN,
        },
      },
    )['data']['value'][0]['id'];

    // Deregister the instance from the pool for Azure.
    await axios.delete(
      `https://dev.azure.com/cncf/_apis/distributedtask/pools/${azpPoolId}/agents/${azpAgentId}?api-version=5.1`,
      {
        auth: {
          username: AZP_USER,
          password: AZP_TOKEN,
        },
      },
    );

    // Allow the instance to terminate.
    terminate(asgName, lifecycleHookName, lifecycleToken, true, (err) => {
      if (err != null) {
        console.log('Failed to update termination lifecycle hook: ', err);
        context.fail();
      } else {
        context.succeed();
      }
    });
  } catch (error) {
    console.log('Caught Error: ', error);
    terminate(asgName, lifecycleHookName, lifecycleToken, false, (err) => {
      if (err != null) {
        console.log('Failed to update termination lifecycle hook: ', err);
        context.fail();
      } else {
        context.succeed();
      }
    });
  }
};
