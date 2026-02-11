import boto3
import os

ssm = boto3.client("ssm")

INSTANCE_ID = os.environ["INSTANCE_ID"]

def lambda_handler(event, context):
    ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": [
                "sudo systemctl start nginx"
            ]
        }
    )

    return {
        "status": "healing triggered",
        "instance": INSTANCE_ID
    }
