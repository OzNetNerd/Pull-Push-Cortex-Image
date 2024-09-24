# Pull Push Cortex Image

The script reads the Cortex YAML file, pulls the image locally, and then pushes it to another registry. This enables organisations to store the image in their own registries.

The script only supports ECR at this stage.

## Usage

```
./pull_push.sh <path_to_yaml_file>
./pull_push.sh csa_agent_openshift_standard.yaml
```

## Supporting Additional Registries

Support for additional registries can be added by:

1. Copying the `push_image_to_ecr()` function
2. Rename it and update the code to work with the desired registry
3. Replace `push_image_to_ecr` at the bottom of the script with the name of your new function