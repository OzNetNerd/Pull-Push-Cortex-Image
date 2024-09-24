# Pull Push Cortex Image

The script reads the Cortex YAML file, pulls the image locally, and then pushes it to another registry. This enables organisations to store the image in their own registries.

The script only supports ECR at this stage.

## Usage

```
./pull_push.sh <path_to_yaml_file>
./pull_push.sh csa_agent_openshift_standard.yaml
```

## Example Usage

```
./pull_push.sh csa_agent_openshift_standard.yaml
Reading YAML file: csa_agent_openshift_standard.yaml
Decoded config value
Extracting repo name
Logging into Palo Alto Docker registry: australia-southeast1-docker
Login Succeeded
Downloading Cortex image: australia-southeast1-docker/xdr-au-1234567890123/agent-docker/cortex-agent:8.5.0.125392
8.5.0.125392: Pulling from xdr-au-1234567890123/agent-docker/cortex-agent
7194e565e7c0: Pull complete
31fcb65a1fe6: Pull complete
023217d047fc: Pull complete
9d5071754f66: Pull complete
ea498bc5bad8: Pull complete
cea6af244043: Pull complete
59a0dfe115e6: Pull complete
b8e76181c4dc: Pull complete
b2ff9e427df5: Pull complete
35f91b193e5c: Pull complete
9be7c3a9e5b4: Pull complete
d34c9afa5873: Pull complete
b279fe36cd49: Pull complete
Digest: sha256:b5fd68358a2cb70ca9a9a272fda56b1f4fb87e359cde4bd787ed3dc6e20a981e
Status: Downloaded newer image for australia-southeast1-docker/xdr-au-1234567890123/agent-docker/cortex-agent:8.5.0.125392
australia-southeast1-docker/xdr-au-1234567890123/agent-docker/cortex-agent:8.5.0.125392
Successfully pulled Cortex image
Preparing to push image to AWS ECR registry
Retrieving AWS account ID
Retrieving AWS region
Constructing ECR registry URL
Constructing ECR repo name
Checking if ECR repo already exists
ECR repository 'cortex-agent' does not exist. Creating repository
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:ap-southeast-2:123456789012:repository/cortex-agent",
        "registryId": "123456789012",
        "repositoryName": "cortex-agent",
        "repositoryUri": "123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/cortex-agent",
        "createdAt": "2024-09-24T10:54:02.355000+10:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
Tagging image with the original tag
Tagging image with the 'latest' tag
Logging into ECR Registry: 123456789012.dkr.ecr.ap-southeast-2.amazonaws.com
Login Succeeded
Pushing image to: 123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/cortex-agent:8.5.0.125392
Using default tag: latest
The push refers to repository [123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/cortex-agent]
b279fe36cd49: Pushed
d34c9afa5873: Pushed
9be7c3a9e5b4: Pushed
35f91b193e5c: Pushed
b2ff9e427df5: Pushed
b8e76181c4dc: Pushed
59a0dfe115e6: Pushed
cea6af244043: Pushed
ea498bc5bad8: Pushed
9d5071754f66: Pushed
023217d047fc: Pushed
31fcb65a1fe6: Pushed
7194e565e7c0: Pushed
latest: digest: sha256:828f1af3d0dd8cf843a5027e2ba00dc046a7972b054a9b96a59c34e13c965930 size: 3023
Image successfully pushed to ECR: 123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/cortex-agent
Pushing image to: 123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/cortex-agent:latest
The push refers to repository [123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/cortex-agent]
b279fe36cd49: Layer already exists
d34c9afa5873: Layer already exists
9be7c3a9e5b4: Layer already exists
35f91b193e5c: Layer already exists
b2ff9e427df5: Layer already exists
b8e76181c4dc: Layer already exists
59a0dfe115e6: Layer already exists
cea6af244043: Layer already exists
ea498bc5bad8: Layer already exists
9d5071754f66: Layer already exists
023217d047fc: Layer already exists
31fcb65a1fe6: Layer already exists
7194e565e7c0: Layer already exists
latest: digest: sha256:828f1af3d0dd8cf843a5027e2ba00dc046a7972b054a9b96a59c34e13c965930 size: 3023
Image successfully pushed to ECR: 123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/cortex-agent (tags: 8.5.0.125392, latest)
```
## Supporting Additional Registries

Support for additional registries can be added by:

1. Copying the `push_image_to_ecr()` function
2. Rename it and update the code to work with the desired registry
3. Replace `push_image_to_ecr` at the bottom of the script with the name of your new function