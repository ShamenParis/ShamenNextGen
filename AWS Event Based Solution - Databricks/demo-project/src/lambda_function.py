import json
import urllib.request
import urllib.parse
import os

def lambda_handler(event, context):
    dbx_host = os.environ['DATABRICKS_HOST']
    dbx_token = os.environ['DATABRICKS_TOKEN']
    url = f"https://{dbx_host}/api/2.1/jobs/runs/submit"
    
    headers = {
        'Authorization': f'Bearer {dbx_token}', 
        'Content-Type': 'application/json'
    }

    for record in event['Records']:
        body = json.loads(record['body'])
        if 'detail' not in body: continue
            
        bucket = body['detail']['bucket']['name']
        key = urllib.parse.unquote_plus(body['detail']['object']['key'])

        # Ephemeral Serverless Job Definition
        payload = {
            "run_name": f"Process_S3_File_{key}",
            "tasks": [
                {
                    "task_key": "process_files",
                    "notebook_task": {
                        "notebook_path": "/Workspace/Shared/DataEngineering/Events/Process_S3_Event",
                        "base_parameters": {
                        "s3_bucket": bucket,
                        "s3_key": key,
                        "host": "{{workspace.url}}",
                        "job_id": "{{job.id}}",
                        "run_id": "{{job.run_id}}"
                        },
                        "source": "WORKSPACE"
                    },
                    "environment_key": "Default"
                }
            ],
            "environments": [
                {
                    "environment_key": "Default",
                    "spec": {
                        "environment_version": "5"
                    }
                }
            ]
        }
        
        req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers)
        
        try:
            response = urllib.request.urlopen(req)
            response_body = json.loads(response.read().decode('utf-8'))
            print(f"Submitted temporary serverless job. Run ID: {response_body.get('run_id')}")
        except Exception as e:
            print(f"Failed to trigger Databricks Job: {str(e)}")
            raise e
            
    return {
        'statusCode': 200,
        'body': json.dumps('Successfully processed S3 events using Serverless')
    }