const axios = require('axios');
const AWS = require('aws-sdk');
const as = new AWS.AutoScaling();
const ec2 = new AWS.EC2();

const AZP_USER = process.env['AZP_USER'];
const AZP_TOKEN = process.env['AZP_TOKEN'];

async function completeAsLifecycleAction(lifecycleParams) {
  await new Promise((resolve, reject) => {
    as.completeLifecycleAction(lifecycleParams, function (err, data) {
      if (err) {
        console.log('ERROR: AS lifecycle completion failed.\nDetails:\n', err);
        reject(err);
      } else {
        console.log(
          'INFO: CompleteLifecycleAction Successful.\nReported:\n',
          data,
        );
        resolve(data);
      }
    });
  });
}

async function terminate(asgName, hookName, token, success) {
  await completeAsLifecycleAction({
    AutoScalingGroupName: asgName,
    LifecycleHookName: hookName,
    LifecycleActionToken: token,
    LifecycleActionResult: success ? 'CONTINUE' : 'ABANDON',
  });
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
    const azpPoolResp = await axios.get(
      `https://dev.azure.com/cncf/_apis/distributedtask/pools?poolName=${azpPoolName}&api-version=5.1`,
      {
        auth: {
          username: AZP_USER,
          password: AZP_TOKEN,
        },
      },
    );
    if (azpPoolResp['data'] == null) {
      console.log('Failed to call AZP Resp: ', azpPoolResp);
    }
    const azpPoolId = azpPoolResp['data']['value'][0]['id'];

    // Finally turn the AZP Agent Name to an ID.
    const azpAgentPool = await axios.get(
      `https://dev.azure.com/cncf/_apis/distributedtask/pools/${azpPoolId}/agents?agentName=${instanceId}&api-version=5.1`,
      {
        auth: {
          username: AZP_USER,
          password: AZP_TOKEN,
        },
      },
    );
    if (azpAgentPool['data'] == null) {
      console.log('Failed to call AZP Agent Pool: ', azpAgentPool);
    }
    const azpAgentId = azpAgentPool['data']['value'][0]['id'];

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
    try {
      await terminate(asgName, lifecycleHookName, lifecycleToken, true);
    } catch (error) {
      console.log('Failed to update termination lifecycle hook: ', error);
      context.fail();
    }
    context.succeed();
  } catch (error) {
    console.log('Caught Error: ', error);
    try {
      await terminate(asgName, lifecycleHookName, lifecycleToken, false);
      context.succeed();
    } catch (new_error) {
      console.log('Failed to update termination lifecycle hook: ', new_error);
      context.fail();
    }
  }
};
