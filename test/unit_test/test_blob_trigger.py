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

References:
 - https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sts/client/assume_role_with_web_identity.html

Local Testing Steps:
```
terraform -chdir=./test init && \
terraform -chdir=./test apply -auto-approve

export SOURCE_BUCKET=$(terraform -chdir=./test output -raw bronze_bucket_id)
export TARGET_BUCKET=$(terraform -chdir=./test output -raw silver_bucket_id)

python3 -m pytest -m 'local and env' test/unit_test/test_blob_trigger.py

terraform -chdir=./test destroy -auto-approve
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
SOURCE_BUCKET=os.getenv('SOURCE_BUCKET')
TARGET_BUCKET=os.getenv('TARGET_BUCKET')
assert not SOURCE_BUCKET is None
assert not TARGET_BUCKET is None


def _write_blob(fs, payload):
    with fs.open(f's3://{SOURCE_BUCKET}/test.json', 'w') as f:
        f.write(json.dumps(payload))

def _read_blob(fs):
    with fs.open(f's3://{TARGET_BUCKET}/test.json', 'rb') as f:
        return json.loads(f.read())

@pytest.mark.local
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
