package ballerina.net.guaranteed.processor;

import ballerina.task;


public map retryCounterMap = {};

public struct GuaranteedProcessor {
    int retryCount;
    int interval;
    map config;
    function(map, blob) store;
    function(map)(blob) retrieve;
    function(blob) handler;
    function(any) responseCatcher;
    string taskId;
}

public function <GuaranteedProcessor guaranteedProcessor> store (map config, blob storableStream) {
    guaranteedProcessor.store(config, storableStream);
}

public function <GuaranteedProcessor guaranteedProcessor> startProcessor () {
    //start the task
    function () returns (error) onTriggerFunction = handleMessage;

    function (error e) onErrorFunction = cleanupError;

    var taskId, schedulerError = task:scheduleTimer(onTriggerFunction(guaranteedProcessor),
                                                    onErrorFunction, {delay:500, interval:1000});
    retryCounterMap[taskId] = guaranteedProcessor.retryCount;
    if (schedulerError != null) {
        println("Timer scheduling failed: " + schedulerError.msg) ;
    } else {
        println("Task ID:" + taskId);
    }
}

function handleMessage(GuaranteedProcessor guaranteedProcessor) returns (error) {
    int retryIteration;
    retryIteration, _ = (int)retryCounterMap[guaranteedProcessor.taskId];

    //retrying is over
    if(retryIteration == 0) {
        return;
    }

    transaction (retry:0){
        blob retrievedMessageStream = guaranteedProcessor.retrieve(guaranteedProcessor.config);
        if (retrievedMessageStream) {
            guaranteedProcessor.handler(retrievedMessageStream,guaranteedProcessor.responseCatcher);
        }
    } failed {
        retryCounterMap[guaranteedProcessor.taskId] =  retryIteration-1;
    } committed {
        retryCounterMap[guaranteedProcessor.taskId] = guaranteedProcessor.retryCount;
    }
}

function cleanupError(error e) {
    print("[ERROR] cleanup failed");
    println(e);
}