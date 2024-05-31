""" Unit Test: AWS Blob Trigger

Unit testing AWS Blob Trigger involves verifying the functionality of the 
trigger mechanism responsible for initiating actions upon the creation or 
modification of objects within Amazon Simple Storage Service (S3) buckets. This 
entails simulating the triggering event, such as the addition of a new 
blob to a specified bucket, and validating that the associated actions, 
like invoking lambda functions or workflows, are executed as expected. Through 
meticulous testing, developers ensure the reliability and accuracy of their 
AWS Blob Trigger implementation, fostering robustness and confidence in their 
cloud-based applications.

Local Testing Steps:
```
terraform init && \
terraform apply -auto-approve

export INPUT_BUCKET=$(terraform output -raw trigger_bucket_name)
export OUTPUT_BUCKET=$(terraform output -raw results_bucket_name)

python3 -m pytest -m github

terraform destroy -auto-approve
```
"""

import logging
import pytest
import boto3
import s3fs
import json
import uuid
import time
import os

# Environment Variables
INPUT_BUCKET=os.getenv('INPUT_BUCKET')
OUTPUT_BUCKET=os.getenv('OUTPUT_BUCKET')
assert not INPUT_BUCKET is None
assert not OUTPUT_BUCKET is None


def _write_blob(fs, payload):
    with fs.open(f's3://{INPUT_BUCKET}/test.json', 'w') as f:
        f.write(json.dumps(payload))

def _read_blob(fs):
    with fs.open(f's3://{OUTPUT_BUCKET}/test.json', 'rb') as f:
        return json.loads(f.read())

@pytest.mark.github
@pytest.mark.env
def test_aws_env_blob_trigger(payload={'test_value': str(uuid.uuid4())}):
    logging.info('Pytest | Test AWS Blob Trigger')

    fs = s3fs.S3FileSystem()
    _write_blob(fs, payload)

    time.sleep(10)
    rs = _read_blob(fs)

    assert rs['test_value'] == payload['test_value']

@pytest.mark.github
@pytest.mark.oidc
def test_aws_oidc_blob_trigger(payload={'test_value': str(uuid.uuid4())}):
    logging.info('Pytest | Test AWS Blob Trigger')
    ASSUME_ROLE=os.getenv('ASSUME_ROLE')
    OIDC_TOKEN=os.getenv('OIDC_TOKEN')
    assert not ASSUME_ROLE is None
    assert not OIDC_TOKEN is None

    client = boto3.client('sts')
    creds = client.assume_role_with_web_identity(
        RoleArn=ASSUME_ROLE,
        RoleSessionName='github-unit-test-oidc-session',
        WebIdentityToken=OIDC_TOKEN
    )

    fs = s3fs.S3FileSystem(
        key=creds['Credentials']['AccessKeyId'],
        secret=creds['Credentials']['SecretAccessKey'],
        token=creds['Credentials']['SessionToken']
    )
    _write_blob(fs, payload)

    time.sleep(10)
    rs = _read_blob(fs)

    assert rs['test_value'] == payload['test_value']
