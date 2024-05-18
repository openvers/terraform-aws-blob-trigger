""" AWS Lambda Function Example

An Amazon Web Services (AWS) Lambda Function with a Blob Storage Trigger is a 
serverless function that automatically executes in response to changes in a 
specified Cloud Storage bucket. When a new blob (file) is created, modified, 
or deleted in the specified bucket, the Cloud Function is triggered, allowing 
you to perform custom logic or processing on the blob data. This trigger mechanism 
enables event-driven architecture and allows you to build scalable and event-based 
solutions on GCP.

This example in particular will take JSON data from the Trigger GCS Bucket,
and store the exact same content with same file name in the Results GCS Bucket
referred to under ENV Variable OUTPUT_BUCKET.

"""

import logging
import urllib
import s3fs
import json
import sys
import os

# Environment Variables
OUTPUT_BUCKET=os.getenv('OUTPUT_BUCKET')


# Setup
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

def load_json(fs, bucket, name):
    """
    Load JSON data from a file.

    Args:
        fs (s3fs.S3Filesystem): File system object.
        bucket (str): Name of the bucket.
        name (str): Name of the JSON file.

    Returns:
        dict: Loaded JSON data.

    """
    file_path = os.path.join(bucket, name)
    logging.info('Loading JSON %s' % file_path)

    with fs.open(os.path.join(bucket, name), 'rb') as f:
        return json.load(f)

# Triggered by a change in a storage bucket
def run(event, context):
    """
    Function triggered by a S3 Storage event.

    Args:
        event (dict): JSON-formatted document that contains data for a Lambda function to process.
        context (dict): This object provides methods and properties that provide information about
                        the invocation, function, and runtime environment

    """
    bucket = event['Records'][0]['s3']['bucket']['name']
    name = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    logging.info('Bucket:%s Blob:%s | Initiating ELT trigger' % (bucket, name))

    fs = s3fs.S3FileSystem()
    rs = load_json(fs, bucket, name)
    with fs.open(os.path.join(f's3://{OUTPUT_BUCKET}', name), 'w') as f:
        f.write(json.dumps(rs))
