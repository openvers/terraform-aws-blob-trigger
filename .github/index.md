# Github Action Workflows

[Github Actions](https://docs.github.com/en/actions) to automate, customize, and execute your software development workflows coupled with the repository.

## Local Actions

Validate Github Workflows locally with [Nekto's Act](https://nektosact.com/introduction.html). More info found in the Github Repo [https://github.com/nektos/act](https://github.com/nektos/act).

### Prerequisits

Store the identical Secrets in Github Organization/Repository to local workstation

```
cat <<EOF > ~/creds/aws.secrets
# Terraform.io Token
TF_API_TOKEN=[COPY/PASTE MANUALLY]

# Github PAT
GITHUB_TOKEN=$(git auth token)

# AWS
AWS_REGION=$(aws configure get region)
AWS_OIDC_PROVIDER_ARN=[COPY/PASTE MANUALLY]
AWS_CLIENT_ID=[COPY/PASTE MANUALLY]
AWS_CLIENT_SECRET=[COPY/PASTE MANUALLY]
AWS_ROLE_TO_ASSUME=[COPY/PASTE MANUALLY]
AWS_ROLE_EXTERNAL_ID=[COPY/PASTE MANUALLY]
EOF
```

### Manual Dispatch Testing

```
# Try the Terraform Read job first
act -j terraform-dispatch-plan \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show)

act -j terraform-dispatch-apply \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show)

act -j terraform-dispatch-destroy \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show)
```

### Integration Testing

```
# Create an artifact location to upload/download between steps locally
mkdir /tmp/artifacts

# Run the full Integration test with
act -j terraform-integration-destroy \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show) \
    --artifact-server-path /tmp/artifacts
```

### Unit Testing

```
act -j terraform-unit-tests \
    -e .github/local.json \
    --secret-file ~/creds/aws.secrets \
    --remote-name $(git remote show)
```