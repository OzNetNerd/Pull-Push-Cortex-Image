#!/bin/bash

check_inputs() {
    if [[ -z "$1" ]]; then
        echo "Error: No YAML file path provided"
        echo "Usage: check_inputs <path_to_yaml_file>"
        echo
        exit 1
    elif [[ ! -f "$1" ]]; then
        if [[ "$1" != /* ]]; then
            abs_path=$(realpath "$1")
        else
            abs_path="$1"
        fi
        echo "Error: File '$abs_path' does not exist"
        echo
        exit 1
    fi
}

download_image() {
    echo "Reading YAML file: $manifest_file"
    # Extract the dockerconfigjson value from the YAML
    docker_config_value=$(grep dockerconfigjson: "$manifest_file" | awk '{print $2}')

    # Decode base64
    echo "Decoded config value"
    decoded_docker_config=$(echo "$docker_config_value" | base64 -d)

    # Extract repo and trim the https prefix
    echo "Extracting repo name"
    repo=$(echo "$decoded_docker_config" | jq -r '.auths | keys[0]' | sed 's/https:\/\///')

    # Extract the password entry
    docker_password=$(echo "$decoded_docker_config" | jq -r '.auths[].password')

    # Docker login
    echo "Logging into Palo Alto Docker registry: $repo"
    echo "$docker_password" | docker login "$repo" -u "_json_key" --password-stdin

    # Extract the image URL from the Kubernetes manifest
    image=$(grep -A 2 "containers:" "$manifest_file" | grep "image:" | awk '{print $2}')
    echo "Downloading Cortex image: $image"

    # Pull image locally
    docker pull "$image"

    echo "Successfully pulled Cortex image"
}

push_image_to_ecr() {
    echo "Preparing to push image to AWS ECR registry"

    # Extract AWS account ID and region
    echo "Retrieving AWS account ID"
    aws_account_id=$(aws sts get-caller-identity --query "Account" --output text)

    aws_region=$(aws configure get region)
    echo "Retrieving AWS region"

    if [[ -z "$aws_account_id" || -z "$aws_region" ]]; then
        echo "Error: Could not retrieve AWS account ID and/or region"
        exit 1
    fi

    # Define the ECR repository URL
    echo "Constructing ECR registry URL"
    ecr_repo_url="$aws_account_id.dkr.ecr.$aws_region.amazonaws.com"

    # Extract image name and tag
    echo "Constructing ECR repo name"
    repo_name=$(basename "$image" | cut -d':' -f1) # Get the image name without tag
    image_tag=$(basename "$image" | cut -d':' -f2) # Extract the tag from the image

    # Check if the ECR repository exists
    echo "Checking if ECR repo already exists"
    repo_exists=$(aws ecr describe-repositories --repository-names "$repo_name" --region "$aws_region" 2>/dev/null)

    if [[ -z "$repo_exists" ]]; then
        # Create the ECR repository if it does not exist
        echo "ECR repository '$repo_name' does not exist. Creating repository"
        aws ecr create-repository --repository-name "$repo_name" --region "$aws_region"
    else
        echo "ECR repository '$repo_name' already exists"
    fi

    # Tag the image for ECR with the original tag
    echo "Tagging image with the original tag"
    docker tag "$image" "$ecr_repo_url/$repo_name:$image_tag"

    # Tag the image with the 'latest' tag
    echo "Tagging image with the 'latest' tag"
    docker tag "$image" "$ecr_repo_url/$repo_name:latest"

    # Authenticate Docker to the ECR registry
    echo "Logging into ECR Registry: $ecr_repo_url"
    aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "$ecr_repo_url"

    # Push the image to ECR with the original tag
    echo "Pushing image to: $ecr_repo_url/$repo_name:$image_tag"
    docker push "$ecr_repo_url/$repo_name:$image_tag"

    # Push the image to ECR with the 'latest' tag
    echo "Pushing image to: $ecr_repo_url/$repo_name:latest"
    docker push "$ecr_repo_url/$repo_name:latest"

    echo "Image successfully pushed to ECR: $ecr_repo_url/$repo_name (tags: $image_tag, latest)"
}

manifest_file="$1"
check_inputs "$manifest_file"
download_image
push_image_to_ecr
