import boto3
import json

def lambda_handler(event, context):

    print(event)
    for record in event['Records']:
        message_body = record['body']
        print("Message Body is ",message_body)
        #For local SQS testing 
        #payload = message_body["value"]
        #For SQS triggered
        payload = ""
        try:
            message = json.loads(message_body)
            # Process the message
            print("Message received:", message)
            payload = message["value"]
        except json.JSONDecodeError as e:
            print("Failed to decode JSON message:", e)

        print("Payload size is", len(payload))

        try:
            # initiate Step Function
            inputData = json.dumps(payload)
            print("InputData to step fucntion is "+inputData)
            
            #step_function_client = boto3.client('stepfunctions')
            #stepfunctionArn = "arn:aws:states:us-east-1:<1234567>:stateMachine:<processor>";

            #response = step_function_client.start_execution(
            #    stateMachineArn=stepfunctionArn,
            #    input=inputData
            #)

            # The response contains the execution ARN
            #execution_arn = response['executionArn']
            #print(f"Step Function execution started: {execution_arn}")

            return {
                'statusCode': 200,
                #'body': json.dumps({'message': f'execution ARN: {execution_arn}'})
                'body': json.dumps({'message': f'Payload input is : {inputData}'})
            }

        except Exception as e:
            print(f"Error processor execution: {e}")

            return {
                'statusCode': 500,
                'body': json.dumps({'error': str(e)})
            }


