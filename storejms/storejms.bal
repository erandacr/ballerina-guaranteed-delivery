package ballerina.net.guaranteed.storejms;

import ballerina.net.jms;

@Description {value:""}
@Return {value:""}
public function store (map config, string queue, blob objectStream) {
    endpoint<jms:JmsClient> jmsEP {
    }

    jms:ClientProperties properties = <struct> config;

    jms:JmsClient jmsConnector = create jms:JmsClient(properties);
    bind jmsConnector with jmsEP;

    jms:JMSMessage message = jms:createBytesMessage(properties);
    message.setBytesMessageContent(objectStream);
    jmsEP.send(queue, message);
}

@Description {value:"Get object content of the JMS message"}
@Return {value:"any: Object Message Content"}
public function retrieve (map config, string queue) (blob objectStream) {
    endpoint<jms:JmsClient> jmsEP {
    }

    jms:ClientProperties properties = <struct> config;

    jms:JmsClient jmsConnector = create jms:JmsClient(properties);
    bind jmsConnector with jmsEP;

    jms:JMSMessage message = jmsEP.poll(queue, {timeout:12});
    if (message == null) {
        return null;
    }
    return message.getBytesMessageContent();
}

