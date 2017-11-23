import ballerina.guaranteed.storejms;
import ballerina.net.http;
import ballerina.guaranteed.processor;
import ballerina.guaranteed.httpr;


service<http> sampleService {
    processor:GuaranteedConfig guaranteedConfig = {retryCount:23, interval:1234,
                                             config:{ "initialContextFactory":"org.apache.activemq.jndi.ActiveMQInitialContextFactory",
                                                        "providerUrl":"tcp://localhost:61616",
                                                        "connectionFactoryName":"QueueConnectionFactory"
                                                    },
                                                       store: storejms:store,
                                                       retriever: storejms:retrieve,
                                                       handler: httpr:handle,
                                                      responseCatcher: handleMyCustomResponse

                                         };
    // starting the message processor task
    guaranteedConfig.startProcessor();

    @http:resourceConfig {
        methods:["GET"],
        path:"/sayHello"
    }
    resource sayHello (http:Request req, http:Response res) {

        endpoint<http:HttpClient> httpEp {
        }

        http:HttpGuaranteedClient httpGuaranteedClient = create httpr:HttpGuaranteedClient("https://postman-echo.com", {}, guaranteedProcessor);
        bind httpGuaranteedClient with httpEp;

        http:Request req = {};
        req.setStringPayload();

        var resp, err = httpEp.get("/my-webapp/echo", req);
        res.send();
    }

}

// my custom response handler
function handleMyCustomResponse(any response) {
    http:Response httpResponse = (http:Response) response;
    println(httpResponse);
}