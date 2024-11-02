import os
import urllib.request

def lambda_handler(event, context):
    url = os.environ['FILE_URL']
    efs_path = "/providers.json"
    
    urllib.request.urlretrieve(url, efs_path)

    return {
        'statusCode': 200,
        'body': 'File downloaded successfully!'
    }