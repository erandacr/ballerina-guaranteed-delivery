package ballerina.net.guaranteed.httpr;

import ballerina.guaranteed.processor;
import ballerina.net.http;

@Description { value:"--"}
@Param { value:"--"}
public connector HttpGuaranteedClient (string serviceUri, http:Options connectorOptions, processor:GuaranteedProcessor guaranteedProcessor, function(http:Response) replyFunc) {

    action get (string path, http:Request req) (http:Response, http:HttpConnectorError) {

        // 1. Store the message ===============================================
        // Create a storable message
        StorableRequest storableReq = req.convertToStorableRequest(serviceUrl, path, "get", connectorOptions, replyFunc);
        // convert storable message to blob (do we need functions for this?)
        blob storableStream = <blob>storableReq;
        // store the message
        http:Response response = {};

        transaction {
            guaranteedProcessor.store(config, storableStream);
        } committed {
            response.setStatusCode(202);
        } failed {
            response.setStatusCode(500);
            retry = 0;
        }
        return response, null;
    }
}

public function handle (blob objectStream, function (any) responseCatcher) {
    endpoint<http:HttpClient> httpEp {

             }
    StorableRequest storableReq = <struct> objectStream;
    http:Request request = storableReq.convertToRequest();
    http:HttpClient client = create http:HttpClient(storableReq.serviceUrl, storableReq.options);
    bind client with httpEp;

    http:Response response;
    if("get" == storableReq.method) {
        response, _ = httpEp.get(storableReq.path, request);
    }

    // Start the worker separately and return the task thread to poll next message
    propagateReply(response, responseCatcher);
}

public function propagateReply(http:Response response, function (any) responseCatcher) {
    worker w1 {
        responseCatcher(response);
    }
}



@Description { value:"Represents a http storable request message"}
struct StorableRequest {
    string serviceUrl;
    string path = "/";
    string method = "get";
    Options option;
}


public native function <Request request> convertToStorableRequest (string serviceUrl, string path, string method, Options options) (StorableRequest);

public native function <StorableRequest storableRequest> convertToRequest () (Request);


// This can be moved into util package, for two functions
// any -> blob
// public native function <any object> anyToBlob () (blob);
// blob -> any
// public native function <blob byteStream> blobToAny () (any);
@Description { value:"Get object content of the JMS message"}
@Return { value:"any: Object Message Content" }
public native function <blob byteStream> generateStorableRequest () (StorableRequest);
