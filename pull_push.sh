#!/bin/bash

check_inputs() {
    if [[ -z "$1" ]]; then
        echo "Error: No YAML file path provided."
        echo "Usage: check_inputs <path_to_yaml_file>"
        echo
        exit 1
    elif [[ ! -f "$1" ]]; then
        if [[ "$1" != /* ]]; then
            abs_path=$(realpath "$1")
        else
            abs_path="$1"
        fi
        echo "Error: File '$abs_path' does not exist."
        echo
        exit 1
    fi
}

download_image() {
    # Extract the dockerconfigjson value from the YAML
    docker_config_value=$(grep dockerconfigjson: "$manifest_file" | awk '{print $2}')
    # Decode base64
    decoded_docker_config=$(echo "$docker_config_value" | base64 -d)

    # Extract repo and trim the https prefix
    repo=$(echo "$decoded_docker_config" | jq -r '.auths | keys[0]' | sed 's/https:\/\///')

    # Extract the password entry
    docker_password=$(echo "$decoded_docker_config" | jq -r '.auths[].password')

    # Docker login
    echo "Docker login to $repo"
    echo "$docker_password" | docker login "$repo" -u "_json_key" --password-stdin

    # Extract the image URL from the Kubernetes manifest
    image=$(grep -A 2 "containers:" "$manifest_file" | grep "image:" | awk '{print $2}')
    echo "Downloading image: $image"

    # Pull image locally
    docker pull "$image"
}

push_image_to_ecr() {
    # Extract AWS account ID and region
    aws_account_id=$(aws sts get-caller-identity --query "Account" --output text)
    aws_region=$(aws configure get region)

    if [[ -z "$aws_account_id" || -z "$aws_region" ]]; then
        echo "Error: Could not retrieve AWS account ID or region."
        exit 1
    fi

    # Extract the image URL from the Kubernetes manifest
    image=$(grep -A 2 "containers:" "$manifest_file" | grep "image:" | awk '{print $2}')

    # Define the ECR repository URL
    ecr_repo_url="$aws_account_id.dkr.ecr.$aws_region.amazonaws.com"
    repo_name=$(basename "$image" | cut -d':' -f1) # Get the image name without tag

    # Check if the ECR repository exists
    repo_exists=$(aws ecr describe-repositories --repository-names "$repo_name" --region "$aws_region" 2>/dev/null)

    if [[ -z "$repo_exists" ]]; then
        # Create the ECR repository if it does not exist
        echo "ECR repository '$repo_name' does not exist. Creating repository."
        aws ecr create-repository --repository-name "$repo_name" --region "$aws_region"
    else
        echo "ECR repository '$repo_name' already exists."
    fi

    # Tag the image for ECR
    docker tag "$image" "$ecr_repo_url/$repo_name"

    # Authenticate Docker to the ECR registry
    aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "$ecr_repo_url"

    # Push the image to ECR
    echo "Pushing image to $ecr_repo_url/$repo_name"
    docker push "$ecr_repo_url/$repo_name"
    echo "Image successfully pushed to ECR: $ecr_repo_url/$repo_name"

}

manifest_file="$1"
check_inputs "$manifest_file"
download_image
push_image_to_ecr
