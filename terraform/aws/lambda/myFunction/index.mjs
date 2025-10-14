import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";

// Main Lambda handler
export const listener_handler = async (event,ctx) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    const stepFunctionClient = new SFNClient({
      region: 'us-east-1'
  });
    const stepFunctionArn = "arn:aws:states:us-east-1:<account>:stateMachine:my-stepfunction";

    for (const record of event.Records) {
      console.log('record in event.Records:', record);
        try {

            let msgbody;

            if(typeof record.body === 'string'){
              console.log("record.body is a string");
              msgbody = JSON.parse(record.body);
            }else{
              console.log("record.body is an object");
              msgbody = record.body;
            }
            
            console.log("body is", JSON.stringify(msgbody));

            //let i=0;
            const inputData = new Array();

            for(const item of msgbody.value){
              
              const eventtype = item["eventtype"];
              if(eventtype !== "SoftDeleteActivation" && eventtype !== "SoftDeleteDeActivation"){
                 console.log("Warning: event type not supported", eventtype);
                 //payload.splice(i,1);
              } else {
                console.log('Found a soft delete or de active soft delete event! Details:', JSON.stringify(item));
                //i += 1;
                inputData.push(item);
              }
            }

            const executionName = "listener"+Date.now();
            console.log("executionName will be ",executionName);
            console.log("Input data for stepfunction:", JSON.stringify(inputData));
            const command = new StartExecutionCommand({
              stateMachineArn: stepFunctionArn,
              name: executionName, // Optional
              input: JSON.stringify(inputData), // Input must be a stringified JSON
            });

            const response = await stepFunctionClient.send(
              command
            );

            const executionArn = response.executionArn;
            console.log("Step function execution started:", executionArn);

        } catch (error) {
            console.error('Error parsing message body:', record.body, error);
            // Handle parsing errors, e.g., dead-letter queueing or retry logic
        }
    }

    return {
        statusCode: 200,
        body: JSON.stringify('Messages processed successfully!'),
    };
};

export const proxy_handler = async (event,ctx) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    const event_type=event.eventtype;
    
    if(event_type === "SoftDeleteActivation"){
      console.log("Call MDM service for soft delete");
      const req = "<soapenv:Envelope><soapenv:Header/><soapenv:Body><message>request message</message></soapenv:Body></soapenv:Envelope>"
      const serviceResp = await lambda_apigw_mdm_call(req);
    }else{
      console.log("not a softdelete event",event_type);
    }
    return {
        statusCode: 200,
        body: JSON.stringify('Proxy return successfully!'),
    };
};

async function lambda_apigw_mdm_call(soap_payload){
  return "<soapenv:Envelope><soapenv:Header/><soapenv:Body><message>Success</message></soapenv:Body></soapenv:Envelope>"
}