import json
import boto3

'''
Example commands to run: 
aws lambda invoke --function-name STH_AuditTask \
    --payload '{"service": "ec2", "action": "describe_instances", "params": {"Filters": [{"Name": "instance-state-name", "Values": ["running"]}]}}' \
    --cli-binary-format raw-in-base64-out \
    response.json'
aws lambda invoke --function-name STH_AuditTask \
    --payload '{"service": "secretsmanager", "action": "list_secrets", "params": {}}' \
    --cli-binary-format raw-in-base64-out \
    response.json
'''


def lambda_handler(event, context):
    """
    Payload format:
    {
      "service": "ec2",
      "action": "describe_instances",
      "params": {
         "Filters": [ { "Name": "instance-state-name", "Values": ["running"] } ]
      }
    }
    """
    service = event.get("service")
    action  = event.get("action")
    params  = event.get("params", {})

    if not service or not action:
        return { "statusCode": 400, "body": "service and action required" }

    client = boto3.client(service)
    try:
        # Dynamically call the requested AWS API
        func = getattr(client, action)
        response = func(**params)
        body = json.dumps(response, default=str)
    except Exception as e:
        body = f"Error calling {service}.{action}: {str(e)}"

    return {
        "statusCode": 200,
        "body": body
    }
