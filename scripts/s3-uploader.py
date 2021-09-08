# BESI-C Relay S3 Data Uploader
#   https://github.com/pennbauman/besic-relay
#   Yudel Martinez <yam3nv@virginia.edu>
#   Penn Bauman <pcb8gb@virginia.edu>
import boto3
import sys
import os

# Check file to upload
if len(sys.argv) < 2:
    print("Missing file to upload")
    sys.exit(2)
upfile = sys.argv[1]

# Setup uploader
aws_path = os.environ['DEPLOYMENT_NAME'] + "/Relays/" + os.environ['RELAY_ID'] + "/" + upfile.split()[-1]
session = boto3.Session(aws_access_key_id=os.environ['S3_ACCESS_KEY'],
        aws_secret_access_key=os.environ['S3_SECRET_KEY'])
s3 = session.resource('s3')

# Upload
try:
    with open(upfile, "rb") as data:
        s3.Bucket("besi-c").put_object(Key=aws_path, Body=data)
    sys.exit(0)
except Exception as e:
    print(e)
    sys.exit(1)
