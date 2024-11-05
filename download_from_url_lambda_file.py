import os
import urllib.request

def lambda_handler(event, context):
    url = os.environ['FILE_URL']
    efs_path = "/mnt/efs/providers.json"
    try:
        urllib.request.urlretrieve(url, efs_path)
        return {
            'statusCode': 200,
            'body': 'File downloaded successfully!'
        }
    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': "Failed to download file: {e}"
        }