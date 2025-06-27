<p float="left">
  <img id="b-0" src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white" height="25px"/>
  <img id="b-1" src="https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white" height="25px"/>
  <img id="b-2" src="https://img.shields.io/github/actions/workflow/status/sim-parables/terraform-aws-blob-trigger/tf-integration-test.yml?style=flat&logo=github&label=CD%20(June%202025)" height="25px"/>
</p>
---

# Terraform AWS Blob Trigger

This module provisions AWS infrastructure to enable a blob trigger source-to-target data transfer using AWS Lambda. It is designed to automate the movement of files (blobs) from a source S3 bucket to a target S3 bucket whenever new objects are created or updated in the source bucket.

## Features
- **Automated S3 Event Trigger:** Deploys an AWS Lambda function that is triggered by S3 events (e.g., object creation) in the source bucket.
- **Source-to-Target Transfer:** The Lambda function copies or processes blobs from the source bucket to the target bucket.
- **Customizable:** Easily configure source/target buckets, Lambda runtime, and permissions via Terraform variables.
- **Reusable Module:** Integrate into your Terraform projects for rapid deployment of blob transfer automation.

## Usage

```hcl
module "blob_trigger" {
  source = "<path-to-this-module>"

  source_bucket = "my-source-bucket"
  target_bucket = "my-target-bucket"
  # Add other required variables here
}
```

## Requirements
- Terraform >= 1.0
- AWS provider

## Inputs
| Name           | Description                        | Type   | Default | Required |
|----------------|------------------------------------|--------|---------|----------|
| source_bucket  | Source S3 bucket name              | string | n/a     | yes      |
| target_bucket  | Target S3 bucket name              | string | n/a     | yes      |
| ...            | ...                                | ...    | ...     | ...      |

## Outputs
| Name           | Description                        |
|----------------|------------------------------------|
| lambda_arn     | ARN of the deployed Lambda function |
| ...            | ...                                |

## Testing
See the `test/` directory for example usage and integration tests.

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

act -j terraform-dispatch-test \
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

## Lambda Function Code
The Lambda function source code and dependencies are located in `test/source/`. You can customize the logic as needed.

## License
See [LICENSE](LICENSE) for details.

---

