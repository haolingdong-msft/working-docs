# Issue Root Cause Analysis

## Issue summary
https://github.com/Azure/azure-sdk-for-java/issues/25709

User creates a Spring bean that returns a ServiceBusProcessorClient instance. Define a processMessage and processError handler. In the processMessage handler function, do "throw new NullPointerException()". Observe that processError function is called. Try to stop the application using Ctrl-c. Observe that it is not possible to fully stop it. Can only kill the java-process using kill or system console.

## Reproduce issue

I did below three experiments. I defined below `processMessageHandler` which throw NullPointerException for all experiments.

```java
@Component
public class ServiceBusMessageHandler {

    public static void processMessageHandler(ServiceBusReceivedMessageContext context) {
        System.out.println("process message");
        throw new NullPointerException();
    }

    public static void processErrorHandler(ServiceBusErrorContext context) {
        System.out.println("process error");
    }

}
```

### SpringBoot Application + define ServiceBusProcessorClient as bean

I define a `ServiceBusProcessorClient` bean.
The result is sometimes ctrl-c can't terminate successfully, sometimes ctrl-c can terminate successfully.


```java
@Configuration
public class ServiceBusTestConfiguration {
    static String connectionString = "Endpoint=sb://testsb-hl.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=omXzcCxktQVAJIyVGtkY03ETZG7ubPA++QicRc87ihM=";
    static String queueName = "smallsizequeue";

    @Bean( initMethod = "start")
    public ServiceBusProcessorClient serviceBusProcessorClient() {
        ServiceBusProcessorClient processorClient = new ServiceBusClientBuilder()
                .connectionString(connectionString)
                .processor()
                .queueName(queueName)
                .processMessage(ServiceBusMessageHandler::processMessageHandler)
                .processError(ServiceBusMessageHandler::processErrorHandler)
                .buildProcessorClient();
        return processorClient;
    }
}
```

### non-SpringBoot application

If I only create `ServiceBusProcessorClient` inside `main()`, I can always terminate successfully.

```java
public class DemoApplication {
	public static void main(String[] args) throws InterruptedException {
		ServiceBusProcessorClient processorClient = new ServiceBusClientBuilder()
				.connectionString(connectionString)
				.processor()
				.queueName(queueName)
				.processMessage(ServicebusMessageHandler::processMessageHandler)
				.processError(ServicebusMessageHandler::processErrorHandler)
				.buildProcessorClient();
		processorClient.start();
	}

}
```

### SpringBoot Application + not define ServiceBusProcessorClient as bean

I create a SpringBoot Application and create `ServiceBusProcessorClient` inside `main()`. The result is I can always terminate successfully.

```java
@SpringBootApplication
public class DemoApplication {
	public static void main(String[] args) throws InterruptedException {
		ServiceBusProcessorClient processorClient = new ServiceBusClientBuilder()
				.connectionString(connectionString)
				.processor()
				.queueName(queueName)
				.processMessage(ServicebusMessageHandler::processMessageHandler)
				.processError(ServicebusMessageHandler::processErrorHandler)
				.buildProcessorClient();
		processorClient.start();
	}

}
```
In conclusion. The issue happens when we define ServiceBusProcessorClient as bean, if it's not defined as bean, the issue will not happen.

| SpringBoot | Define ServiceBusProcessorClient as bean | Reproduce Result                                                                                     |
| ---------- | ---------------------------------------- | ------------------------------------------------------------------------------------------ |
| Y          | Y                                        | sometimes ctrl-c can't terminate successfully, sometimes ctrl-c can terminate successfully |
| Y          | N                                        | always terminate successfully                                                              |
| N          | N                                        | always terminate successfully                                                              |

## Check difference in jstack

From the experiments, I found **the issue only happens when we define ServiceBusProcessorClient as bean**.

I compared log for 'SpringBoot Application + define ServiceBusProcessorClient as bean' and log for 'SpringBoot Application + not define ServiceBusProcessorClient as bean'. In log for 'SpringBoot Application + define ServiceBusProcessorClient as bean', we found below additional stack after receiving ctrl-c (SIGINT):

[jstack log for SpringBoot Application + define ServiceBusProcessorClient as bean]
```jstack log for SpringBoot Application + define ServiceBusProcessorClient as bean
"SIGINT handler" #37 daemon prio=9 os_prio=2 cpu=0.00ms elapsed=34.39s tid=0x00000201f61e8160 nid=0x97c8 in Object.wait()  [0x000000e40d4fe000]
   java.lang.Thread.State: WAITING (on object monitor)
	at java.lang.Object.wait(java.base@17.0.1/Native Method)
	- waiting on <0x000000060980ecf8> (a java.lang.Thread)
	at java.lang.Thread.join(java.base@17.0.1/Thread.java:1304)
	- locked <0x000000060980ecf8> (a java.lang.Thread)
	at java.lang.Thread.join(java.base@17.0.1/Thread.java:1372)
	at java.lang.ApplicationShutdownHooks.runHooks(java.base@17.0.1/ApplicationShutdownHooks.java:107)
	at java.lang.ApplicationShutdownHooks$1.run(java.base@17.0.1/ApplicationShutdownHooks.java:46)
	at java.lang.Shutdown.runHooks(java.base@17.0.1/Shutdown.java:130)
	at java.lang.Shutdown.exit(java.base@17.0.1/Shutdown.java:173)
	- locked <0x00000006046f81b0> (a java.lang.Class for java.lang.Shutdown)
	at java.lang.Terminator$1.handle(java.base@17.0.1/Terminator.java:51)
	at jdk.internal.misc.Signal$1.run(java.base@17.0.1/Signal.java:219)
	at java.lang.Thread.run(java.base@17.0.1/Thread.java:833)

   Locked ownable synchronizers:
	- None

"SpringApplicationShutdownHook" #19 prio=5 os_prio=0 cpu=15.62ms elapsed=34.39s tid=0x00000201f61e8fd0 nid=0x2d0c waiting on condition  [0x000000e40d5fe000]
   java.lang.Thread.State: WAITING (parking)
	at jdk.internal.misc.Unsafe.park(java.base@17.0.1/Native Method)
	- parking to wait for  <0x0000000620a0ed38> (a java.util.concurrent.Semaphore$NonfairSync)
	at java.util.concurrent.locks.LockSupport.park(java.base@17.0.1/LockSupport.java:211)
	at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquire(java.base@17.0.1/AbstractQueuedSynchronizer.java:715)
	at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireSharedInterruptibly(java.base@17.0.1/AbstractQueuedSynchronizer.java:1047)
	at java.util.concurrent.Semaphore.acquire(java.base@17.0.1/Semaphore.java:318)
	at com.azure.messaging.servicebus.ServiceBusReceiverAsyncClient.close(ServiceBusReceiverAsyncClient.java:1202)
	at com.azure.messaging.servicebus.ServiceBusProcessorClient.close(ServiceBusProcessorClient.java:242)
	- locked <0x0000000620a0d648> (a com.azure.messaging.servicebus.ServiceBusProcessorClient)
	at org.springframework.beans.factory.support.DisposableBeanAdapter.destroy(DisposableBeanAdapter.java:238)
	at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.destroyBean(DefaultSingletonBeanRegistry.java:587)
	at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.destroySingleton(DefaultSingletonBeanRegistry.java:559)
	at org.springframework.beans.factory.support.DefaultListableBeanFactory.destroySingleton(DefaultListableBeanFactory.java:1152)
	at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.destroySingletons(DefaultSingletonBeanRegistry.java:520)
	at org.springframework.beans.factory.support.DefaultListableBeanFactory.destroySingletons(DefaultListableBeanFactory.java:1145)
	at org.springframework.context.support.AbstractApplicationContext.destroyBeans(AbstractApplicationContext.java:1106)
	at org.springframework.context.support.AbstractApplicationContext.doClose(AbstractApplicationContext.java:1075)
	at org.springframework.context.support.AbstractApplicationContext.close(AbstractApplicationContext.java:1021)
	- locked <0x00000006052d8080> (a java.lang.Object)
	at org.springframework.boot.SpringApplicationShutdownHook.closeAndWait(SpringApplicationShutdownHook.java:137)
	at org.springframework.boot.SpringApplicationShutdownHook$$Lambda$608/0x00000008010f6640.accept(Unknown Source)
	at java.lang.Iterable.forEach(java.base@17.0.1/Iterable.java:75)
	at org.springframework.boot.SpringApplicationShutdownHook.run(SpringApplicationShutdownHook.java:106)
	at java.lang.Thread.run(java.base@17.0.1/Thread.java:833)

   Locked ownable synchronizers:
	- None
```
When defing ServiceBusProcessorClient as bean, after sending ctrl-c event. SpringApplicationShutdownHook calls ServiceBusProcessorClient.close() and ServiceBusReceiverAsyncClient.close(). 

## Narrow down problem to ServiceBusProcessorClient.close()
```java
@Configuration
public class ServiceBusTestConfiguration {
    static String connectionString = "<connection-string>";
    static String queueName = "smallsizequeue";

    @Bean( initMethod = "start", destroyMethod = "")
    public ServiceBusProcessorClient serviceBusProcessorClient() {
        ServiceBusProcessorClient processorClient = new ServiceBusClientBuilder()
                .connectionString(connectionString)
                .processor()
                .queueName(queueName)
                .processMessage(ServiceBusMessageHandler::processMessageHandler)
                .processError(ServiceBusMessageHandler::processErrorHandler)
                .buildProcessorClient();
        return processorClient;
    }
}
```
If we rewrite `destroyMethod=""` to avoid it call ServiceBusProcessorClient.close(), then ctrl-c can always terminate process. So the the issue is caused by ServiceBusProcessorClient.close()

## Narrow down problem to ServiceBusReceiverAsyncClient.close()
Adding logs in ServiceBusProcessorClient.close():
```java
    @Override
    public synchronized void close() {
        System.out.println("ServiceBusProcessorClient close() start");
        isRunning.set(false);
        receiverSubscriptions.keySet().forEach(Subscription::cancel);
        receiverSubscriptions.clear();
        System.out.println("ServiceBusProcessorClient close() subscription clear");
        if (scheduledExecutor != null) {
            scheduledExecutor.shutdown();
            scheduledExecutor = null;
            System.out.println("ServiceBusProcessorClient close() scheduledExecutor shutdown");
        }
        if (asyncClient.get() != null) {
            System.out.println("ServiceBusProcessorClient close() asyncClient not null");
            asyncClient.get().close();
            asyncClient.set(null);
            System.out.println("ServiceBusProcessorClient close() asyncClient shutdown");
        }
        System.out.println("ServiceBusProcessorClient close() end");
    }
```

[ctrl-c can't terminate log]
```ctrl-c can't terminate log
2021-12-22 14:05:33.122  INFO 4380 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Passing message downstream. sequenceNumber[119]
FluxAutoComplete acquire semaphore
2021-12-22 14:05:33.125  INFO 4380 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkCredits: '0', expectedTotalCredit: '2'
2021-12-22 14:05:33.125  INFO 4380 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : prefetch: '0', requested: '2', linkCredits: '0', expectedTotalCredit: '2', queuedMessages:'1', creditsToAdd: '1', messageQueue.size(): '0'
2021-12-22 14:05:33.126  INFO 4380 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Link credits='0', Link credits to add: '1'
process error
2021-12-22 14:05:33.128  WARN 4380 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Error when processing message. Abandoning message.
--- ctrl+c
ServiceBusProcessorClient close() start
ServiceBusProcessorClient close() subscription clear
ServiceBusProcessorClient close() scheduledExecutor shutdown
ServiceBusProcessorClient close() asyncClient not null
ServiceBusReceiverAsyncClient close() start
```

In [ctrl-c can't terminate log], `ServiceBusProcessorClient close() asyncClient shutdown` is not printed which means `asyncClient.get().close();` has error.

## Narrow down problem to `completionLock.acquire();`
Adding logs in ServiceBusReceiverAsyncClient.close():
```java
@Override
    public void close() {
        System.out.println("ServiceBusReceiverAsyncClient close() start");
        if (isDisposed.get()) {
            System.out.println("is disposed");
            return;
        }

        try {
            System.out.println("acquire completionLock " + completionLock);
            completionLock.acquire();
        } catch (InterruptedException e) {
            logger.info("Unable to obtain completion lock.", e);
        }

        System.out.println("try isDisposed.getAndSet(true)");

        if (isDisposed.getAndSet(true)) {
            System.out.println("isDisposed.getAndSet(true)");
            return;
        }

        // Blocking until the last message has been completed.
        logger.info("Removing receiver links.");
        final ServiceBusAsyncConsumer disposed = consumer.getAndSet(null);
        if (disposed != null) {
            disposed.close();
        }

        if (sessionManager != null) {
            sessionManager.close();
        }

        managementNodeLocks.close();
        renewalContainer.close();

        onClientClose.run();
    }
```


[ctrl-c can't terminate log]
```ctrl-c can't terminate log
2021-12-22 14:05:33.122  INFO 4380 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Passing message downstream. sequenceNumber[119]
FluxAutoComplete acquire semaphore
2021-12-22 14:05:33.125  INFO 4380 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkCredits: '0', expectedTotalCredit: '2'
2021-12-22 14:05:33.125  INFO 4380 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : prefetch: '0', requested: '2', linkCredits: '0', expectedTotalCredit: '2', queuedMessages:'1', creditsToAdd: '1', messageQueue.size(): '0'
2021-12-22 14:05:33.126  INFO 4380 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Link credits='0', Link credits to add: '1'
process error
2021-12-22 14:05:33.128  WARN 4380 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Error when processing message. Abandoning message.
--- ctrl+c
ServiceBusProcessorClient close() start
ServiceBusProcessorClient close() subscription clear
ServiceBusProcessorClient close() scheduledExecutor shutdown
ServiceBusProcessorClient close() asyncClient not null
ServiceBusReceiverAsyncClient close() start
acquire completionLock java.util.concurrent.Semaphore@559905b[Permits = 0]
```

[ctrl-c terminate successful log]
```ctrl-c can terminate log
2021-12-22 14:04:57.390  INFO 15012 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Finished. sequenceNumber[118]
FluxAutoComplete release semaphore

---> ctrl+c
ServiceBusProcessorClient close() start
ServiceBusProcessorClient close() subscription clear
ServiceBusProcessorClient close() scheduledExecutor shutdown
ServiceBusProcessorClient close() asyncClient not null
ServiceBusReceiverAsyncClient close() start
acquire completionLock java.util.concurrent.Semaphore@1d794a2f[Permits = 1]
try isDisposed.getAndSet(true)
2021-12-22 14:05:10.165  INFO 15012 --- [ionShutdownHook] c.a.m.s.ServiceBusReceiverAsyncClient    : Removing receiver links.
2021-12-22 14:05:10.167  INFO 15012 --- [ionShutdownHook] c.a.m.s.ServiceBusClientBuilder          : Closing a dependent client. # of open clients: 0
2021-12-22 14:05:10.168  INFO 15012 --- [ionShutdownHook] c.a.m.s.ServiceBusClientBuilder          : No more open clients, closing shared connection [ServiceBusConnectionProcessor].
2021-12-22 14:05:10.169  INFO 15012 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : Upstream connection publisher was completed. Terminating processor.
2021-12-22 14:05:10.170  INFO 15012 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: AMQP channel processor completed. Notifying 0 subscribers.
2021-12-22 14:05:10.171  INFO 15012 --- [ionShutdownHook] c.a.c.a.i.ReactorConnection              : connectionId[MF_91434a_1640153092809] signal[Disposed by client., isTransient[false], initiatedByClient[true]]: Disposing of ReactorConnection.
2021-12-22 14:05:10.172  INFO 15012 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Channel is disposed.
ServiceBusProcessorClient close() asyncClient shutdown
ServiceBusProcessorClient close() end
```

You will see in [ctrl-c can't terminate log] log, "try isDisposed.getAndSet(true)" log is not printed. This is because `completionLock.acquire();` stucked. If `completionLock` Permits = 0, then the process can't be terminated, otherwise process can be terminated.

## Conclusion
In conclusion, the issue is caused by [`completionLock.acquire()`](https://github.com/haolingdong-msft/azure-sdk-for-java/blob/main/sdk/servicebus/azure-messaging-servicebus/src/main/java/com/azure/messaging/servicebus/ServiceBusReceiverAsyncClient.java#L1202-L1202) in `ServiceBusReceiverAsyncClient.close()` stucks. If we create `ServiceBusProcessorClient` as bean in SpringBoot application, and send ctrl-c signal to spring Boot applcation, SpringBoot Shutdown hook calls `ServiceBusReceiverAsyncClient.close()` which calls `completionLock.acquire()`, sometimes `completionLock` is not released, so the process stucked since `completionLock` can not be aquired.

The `completionLock` is released in `finally` block [here](https://github.com/haolingdong-msft/azure-sdk-for-java/blob/main/sdk/servicebus/azure-messaging-servicebus/src/main/java/com/azure/messaging/servicebus/FluxAutoComplete.java#L98-L98). Not sure why sometimes it can not be released.

## Analysis on why `completionLock.acquire()` stucks

By comparing the logs happens before ctrl-c (logs can be found at the end of this section). We have below findings:

* `FluxAutoComplete.java` handles message with two steps:
  
  In `downstream.onNext`, it calls `ServiceBusProcessorClient` `onNext()` hook and will **abandon** message on error [here](https://github.com/haolingdong-msft/azure-sdk-for-java/blob/f99ed77b4b04214360a6b27d5c7f03af1903ee40/sdk/servicebus/azure-messaging-servicebus/src/main/java/com/azure/messaging/servicebus/.ServiceBusProcessorClient.java#L302-L302). 
  
  It also calls `applyWithCatch(onComplete, value, "complete");` to **complete** message. From the log you will see ABANDON and COMPLETED happens in different thread. **ABANDON and COMPLETED happen in parallel.**
  
  Please also notice that `ServiceBusProcessorClient.java` uses `catch` to handle error [here](https://github.com/haolingdong-msft/azure-sdk-for-java/blob/f99ed77b4b04214360a6b27d5c7f03af1903ee40/sdk/servicebus/azure-messaging-servicebus/src/main/java/com/azure/messaging/servicebus/ServiceBusProcessorClient.java#L297-L303). The `catch` block in `FluxAutoComplete.java` to abandon message **never** get chance to run.
```java
try {
    downstream.onNext(value);
    applyWithCatch(onComplete, value, "complete");
} catch (Exception e) {
    logger.error("Error occurred processing message. Abandoning. sequenceNumber[{}]",
        sequenceNumber, e);

    applyWithCatch(onAbandon, value, "abandon");
} finally {
    logger.info("ON NEXT: Finished. sequenceNumber[{}]", sequenceNumber);
    System.out.println("FluxAutoComplete release semaphore");
    semaphore.release();
}
```

* When ctrl-c can't terminate, we will find the log
  `smallsizequeue: Update started. Disposition: COMPLETED. Lock: 673a8a82-35e9-40e5-8197-eee3741f31c8. SessionId: null.`. But no `smallsizequeue: Update completed. Disposition: COMPLETED. Lock: 09ae1203-5e23-4bfd-a034-34cd6e03fb26.` log found. It means disposition status COMPLETED is never completed. Disposition status 'ABANDON' has started and completed successfully. It stucks at `applyWithCatch(onComplete, value, "complete");` and could never go to `finally` block to release semaphore.

* When ctrl-c can termiate, we will find the opposite behavior. ABANDON status is started but not completed, but COMPLETED status is started and completed successfully. Since `applyWithCatch(onComplete, value, "complete");` completed, it can go to `finally` block to release semaphore.

* The ABANDON process and COMPLETE process seem to have impact on each other and can only finish one of them.

In conclusion, `completionLock.acquire()` stucks because `applyWithCatch(onComplete, value, "complete");` in `FluxAutoComplete.java` stucks. 

When processing message throws error, it will start ABANDON and COMPLETE proccess in parrallel (each process happens in one thread). If ABANDON finished earlier, then COMPLETE stucks, so the lock can't be released and ctrl-c can't terminate. If CONPLETED finished earlier, the lock can be released and ctrl-c can terminate. The ABANDON process and COMPLETE process seem to have impact on each other and can only finish one of them. That also explains we can't 100% reproduce the issue.

A potential fix would be to make `downstream.onNext(value);` and `applyWithCatch(onComplete, value, "complete");` happen in sequence. We ABANDON message on error and COMPLETE message on success. 

But this brings up a question that: when `processMessage()` throws error, current behavior is that it will start ABANDON and COMPLETE in parallel, rather than only sending ABANDON. So would like to know is it by design to both ABANDON and COMPLETE message on error? (My gut feeling is that it makes more sense to ABANDON message on error and to COMPLETE message on success.)

[ctrl-c can't terminate log]
```ctrl-c can't terminate log
2021-12-27 14:56:43.452  INFO 13408 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteOpen connectionId[MF_8feec4_1640588199433], entityPath[smallsizequeue], linkName[smallsizequeue_2a68a7_1640588199495], remoteSource[Source{address='smallsizequeue', durable=NONE, expiryPolicy=SESSION
_END, timeout=0, dynamic=false, dynamicNodeProperties=null, distributionMode=null, filter=null, defaultOutcome=null, outcomes=null, capabilities=null}]
2021-12-27 14:56:43.499  INFO 13408 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Passing message downstream. sequenceNumber[135]
FluxAutoComplete acquire semaphore
process message
2021-12-27 14:56:43.505  INFO 13408 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkCredits: '0', expectedTotalCredit: '2'
2021-12-27 14:56:43.508  INFO 13408 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : prefetch: '0', requested: '2', linkCredits: '0', expectedTotalCredit: '2', queuedMessages:'1', creditsToAdd: '1', messageQueue.size(): '0'
2021-12-27 14:56:43.508  INFO 13408 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Link credits='0', Link credits to add: '1'
process error
2021-12-27 14:56:43.508  INFO 13408 --- [oundedElastic-3] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update started. Disposition: COMPLETED. Lock: 673a8a82-35e9-40e5-8197-eee3741f31c8. SessionId: null.
2021-12-27 14:56:43.514  WARN 13408 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Error when processing message. Abandoning message.
2021-12-27 14:56:43.514  INFO 13408 --- [oundedElastic-2] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update started. Disposition: ABANDONED. Lock: 673a8a82-35e9-40e5-8197-eee3741f31c8. SessionId: null.
2021-12-27 14:56:44.122  INFO 13408 --- [ctor-executor-1] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update completed. Disposition: ABANDONED. Lock: 673a8a82-35e9-40e5-8197-eee3741f31c8.
2021-12-27 14:56:44.122  INFO 13408 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Requesting 1 more message from upstream
--> ctrl + c
ServiceBusProcessorClient close() start
ServiceBusProcessorClient close() subscription clear
ServiceBusProcessorClient close() scheduledExecutor shutdown
ServiceBusProcessorClient close() asyncClient not null
ServiceBusReceiverAsyncClient close() start
acquire completionLock java.util.concurrent.Semaphore@55a91cd4[Permits = 0]
2021-12-27 15:06:44.206  INFO 13408 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteClose connectionId[MF_8feec4_1640588199433] linkName[smallsizequeue_2a68a7_1640588199495], errorCondition[amqp:link:detach-forced] errorDescription[The link 'G3:186414153:smallsizequeue_2a68a7_164058
8199495' is force detached. Code: consumer(link23744312). Details: AmqpMessageConsumer.IdleTimerExpired: Idle timeout: 00:10:00. TrackingId:29b60df900000479016a4f3861c963ab_G3_B12, SystemTracker:testsb-hl:Queue:smallsizequeue, Timestamp:2021-12-27T07:06:44]
```

[ctrl-c terminate successful log]
```ctrl-c can terminate log
2021-12-23 11:58:28.736  INFO 11504 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteOpen connectionId[MF_f466b4_1640231904906], entityPath[smallsizequeue], linkName[smallsizequeue_2d0e38_1640231904982], remoteSource[Source{address='smallsizequeue', durable=NONE, expiryPolicy=SESSION
_END, timeout=0, dynamic=false, dynamicNodeProperties=null, distributionMode=null, filter=null, defaultOutcome=null, outcomes=null, capabilities=null}]
2021-12-23 11:58:28.797  INFO 11504 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Passing message downstream. sequenceNumber[131]
FluxAutoComplete acquire semaphore
process message
2021-12-23 11:58:28.803  INFO 11504 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkCredits: '0', expectedTotalCredit: '2'
2021-12-23 11:58:28.805  INFO 11504 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : prefetch: '0', requested: '2', linkCredits: '0', expectedTotalCredit: '2', queuedMessages:'1', creditsToAdd: '1', messageQueue.size(): '0'
2021-12-23 11:58:28.806  INFO 11504 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Link credits='0', Link credits to add: '1'
process error
2021-12-23 11:58:28.808  INFO 11504 --- [oundedElastic-3] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update started. Disposition: COMPLETED. Lock: 09ae1203-5e23-4bfd-a034-34cd6e03fb26. SessionId: null.
2021-12-23 11:58:28.809  WARN 11504 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Error when processing message. Abandoning message.
2021-12-23 11:58:28.810  INFO 11504 --- [oundedElastic-2] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update started. Disposition: ABANDONED. Lock: 09ae1203-5e23-4bfd-a034-34cd6e03fb26. SessionId: null.
2021-12-23 11:58:29.533  INFO 11504 --- [ctor-executor-1] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update completed. Disposition: COMPLETED. Lock: 09ae1203-5e23-4bfd-a034-34cd6e03fb26.
2021-12-23 11:58:29.536  INFO 11504 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Finished. sequenceNumber[131]
FluxAutoComplete release semaphore
2021-12-23 11:58:29.543  INFO 11504 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Passing message downstream. sequenceNumber[132]
2022-01-04 13:40:28.826  INFO 25568 --- [ionShutdownHook] c.a.m.s.ServiceBusReceiverAsyncClient    : Removing receiver links.
2022-01-04 13:40:28.826  INFO 25568 --- [ionShutdownHook] c.a.m.s.ServiceBusClientBuilder          : Closing a dependent client. # of open clients: 0
2022-01-04 13:40:28.826  INFO 25568 --- [ionShutdownHook] c.a.m.s.ServiceBusClientBuilder          : No more open clients, closing shared connection [ServiceBusConnectionProcessor].
2022-01-04 13:40:28.826  INFO 25568 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : Upstream connection publisher was completed. Terminating processor.
2022-01-04 13:40:28.826  INFO 25568 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: AMQP channel processor completed. Notifying 0 subscribers.
2022-01-04 13:40:28.826  INFO 25568 --- [ionShutdownHook] c.a.c.a.i.ReactorConnection              : connectionId[MF_68376c_1641274817436] signal[Disposed by client., isTransient[false], initiatedByClient[true]]: Disposing of ReactorConnection.
2022-01-04 13:40:28.826  INFO 25568 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Channel is disposed.
---> ctrl+c
ServiceBusProcessorClient close() start
ServiceBusProcessorClient close() subscription clear
ServiceBusProcessorClient close() scheduledExecutor shutdown
ServiceBusProcessorClient close() asyncClient not null
ServiceBusReceiverAsyncClient close() start
acquire completionLock java.util.concurrent.Semaphore@1d794a2f[Permits = 1]
try isDisposed.getAndSet(true)
2021-12-22 14:05:10.165  INFO 15012 --- [ionShutdownHook] c.a.m.s.ServiceBusReceiverAsyncClient    : Removing receiver links.
2021-12-22 14:05:10.167  INFO 15012 --- [ionShutdownHook] c.a.m.s.ServiceBusClientBuilder          : Closing a dependent client. # of open clients: 0
2021-12-22 14:05:10.168  INFO 15012 --- [ionShutdownHook] c.a.m.s.ServiceBusClientBuilder          : No more open clients, closing shared connection [ServiceBusConnectionProcessor].
2021-12-22 14:05:10.169  INFO 15012 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : Upstream connection publisher was completed. Terminating processor.
2021-12-22 14:05:10.170  INFO 15012 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: AMQP channel processor completed. Notifying 0 subscribers.
2021-12-22 14:05:10.171  INFO 15012 --- [ionShutdownHook] c.a.c.a.i.ReactorConnection              : connectionId[MF_91434a_1640153092809] signal[Disposed by client., isTransient[false], initiatedByClient[true]]: Disposing of ReactorConnection.
2021-12-22 14:05:10.172  INFO 15012 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Channel is disposed.
ServiceBusProcessorClient close() asyncClient shutdown
ServiceBusProcessorClient close() end
```

## Mitigate issue on client side

Try to unblock the customer use case (how to do graceful shutdown), we can try to modify the sample code in the processMessage() to catch exceptions from cx business logic and call processor stop() (to init the closure of underlying clients). Then rethrow the exception for bean to run the destroy/shutdown phase for other cleanups. 

### Use processorClient.close() in catch
Able to use ctrl-c to kill: in catch, we use `processorClient.close();` to close client.
```java
@Configuration
public class ServiceBusTestConfiguration {
    static String connectionString = "<connection-string>";
    static String queueName = "<queue-name>";

    ServiceBusProcessorClient processorClient = null;

    @Bean( initMethod = "start")
    public ServiceBusProcessorClient serviceBusProcessorClient() {
        processorClient = new ServiceBusClientBuilder()
                .connectionString(connectionString)
                .processor()
                .queueName(queueName)
                .processMessage((context) -> {
                    try {
                        System.out.println("process message");
                        throw new NullPointerException();
                    } catch (Exception e) {
                        processorClient.close();
                        e.printStackTrace();
                        throw e;
                    }
                })
                .processError(ServiceBusMessageHandler::processErrorHandler)
                .buildProcessorClient();
        return processorClient;
    }
}
```

### Use processorClient.stop() in catch
unable to use ctrl-c to kill: in catch, we use `processorClient.stop();` to close client.
```java
@Configuration
public class ServiceBusTestConfiguration {
    static String connectionString = "<connection-string>";
    static String queueName = "<queue-name>";

    ServiceBusProcessorClient processorClient = null;

    @Bean( initMethod = "start")
    public ServiceBusProcessorClient serviceBusProcessorClient() {
        processorClient = new ServiceBusClientBuilder()
                .connectionString(connectionString)
                .processor()
                .queueName(queueName)
                .processMessage((context) -> {
                    try {
                        System.out.println("process message");
                        throw new NullPointerException();
                    } catch (Exception e) {
                        processorClient.stop();
                        e.printStackTrace();
                        throw e;
                    }
                })
                .processError(ServiceBusMessageHandler::processErrorHandler)
                .buildProcessorClient();
        return processorClient;
    }
}
```
In summary, if we use processor.close() in catch block, ctrl-c can work and even if user don't use ctrl-c, the program will exit. But if we use processor.stop() in catch block,  ctrl-c can't work and if user don't use ctrl-c, the program will not exit.

## Fixing

I tried to add timeout when acquiring `completionLock` in `ServiceBusReceiverAsyncClient.close()`.
The application can be terminated gracefully after the timeout period.

[log for adding timeout]
```
2022-01-10 14:59:47.653  INFO 20140 --- [           main] c.s.demo.DemoSprintBootApplication       : Starting DemoSprintBootApplication v0.0.1-SNAPSHOT using Java 17.0.1 on haolindong-712 with PID 20140 (C:\workspace\servicebus-test\target\demo-0.0.1-SNAPSHOT.jar started by haolingdong in C:\workspace\servicebus-
test)
2022-01-10 14:59:47.653  INFO 20140 --- [           main] c.s.demo.DemoSprintBootApplication       : No active profile set, falling back to default profiles: default
2022-01-10 14:59:48.167  INFO 20140 --- [           main] f.a.AutowiredAnnotationBeanPostProcessor : Autowired annotation is not supported on static fields: static com.azure.messaging.servicebus.ServiceBusProcessorClient com.servicebus.demo.ServiceBusMessageHandler.serviceBusProcessorClient
2022-01-10 14:59:48.444  INFO 20140 --- [           main] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Setting next AMQP channel.
2022-01-10 14:59:48.444  INFO 20140 --- [           main] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Next AMQP channel received, updating 0 current subscribers
2022-01-10 14:59:48.444  INFO 20140 --- [           main] c.a.m.s.ServiceBusClientBuilder          : # of open clients with shared connection: 1
2022-01-10 14:59:48.460  INFO 20140 --- [           main] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Creating consumer for link 'smallsizequeue_e14a7a_1641797988460'
2022-01-10 14:59:48.475  INFO 20140 --- [           main] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Requesting a new AmqpReceiveLink from upstream.
2022-01-10 14:59:48.497  INFO 20140 --- [           main] c.a.c.a.i.ReactorConnection              : connectionId[MF_a61cc2_1641797988413]: Creating and starting connection to testsb-hl.servicebus.windows.net:5671
2022-01-10 14:59:48.561  INFO 20140 --- [           main] c.a.c.a.implementation.ReactorExecutor   : connectionId[MF_a61cc2_1641797988413] message[Starting reactor.]
2022-01-10 14:59:48.561  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ConnectionHandler      : onConnectionInit connectionId[MF_a61cc2_1641797988413] hostname[testsb-hl.servicebus.windows.net] amqpHostname[testsb-hl.servicebus.windows.net]
2022-01-10 14:59:48.561  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ReactorHandler         : connectionId[MF_a61cc2_1641797988413] reactor.onReactorInit
2022-01-10 14:59:48.561  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ConnectionHandler      : onConnectionLocalOpen connectionId[MF_a61cc2_1641797988413] hostname[testsb-hl.servicebus.windows.net] errorCondition[null] errorDescription[null]
2022-01-10 14:59:48.611  INFO 20140 --- [           main] c.a.m.servicebus.FluxAutoComplete        : Subscription received. Subscribing downstream. reactor.core.publisher.FluxMap$MapSubscriber@6f204a1a
2022-01-10 14:59:48.717  INFO 20140 --- [           main] c.s.demo.DemoSprintBootApplication       : Started DemoSprintBootApplication in 1.554 seconds (JVM running for 1.998)
2022-01-10 14:59:48.747  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ConnectionHandler      : onConnectionBound connectionId[MF_a61cc2_1641797988413] hostname[testsb-hl.servicebus.windows.net] peerDetails[testsb-hl.servicebus.windows.net:5671]
2022-01-10 14:59:50.517  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ConnectionHandler      : onConnectionRemoteOpen hostname[testsb-hl.servicebus.windows.net], connectionId[MF_a61cc2_1641797988413], remoteContainer[18b631be1a354aa6b04c0e3ad3ab118d_G2]
2022-01-10 14:59:50.517  INFO 20140 --- [ctor-executor-1] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Channel is now active.
2022-01-10 14:59:50.849  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.SessionHandler         : onSessionRemoteOpen connectionId[MF_a61cc2_1641797988413], entityName[smallsizequeue], sessionIncCapacity[0], sessionOutgoingWindow[2147483647]
2022-01-10 14:59:50.880  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.ReactorConnection              : Setting CBS channel.
2022-01-10 14:59:51.165  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.SessionHandler         : onSessionRemoteOpen connectionId[MF_a61cc2_1641797988413], entityName[cbs-session], sessionIncCapacity[0], sessionOutgoingWindow[2147483647]
2022-01-10 14:59:51.203  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.ReactorConnection              : connectionId[MF_a61cc2_1641797988413] entityPath[$cbs] linkName[cbs] Emitting new response channel.
2022-01-10 14:59:51.203  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.RequestResponseChannel:$cbs    : namespace[MF_a61cc2_1641797988413] entityPath[$cbs]: Setting next AMQP channel.
2022-01-10 14:59:51.203  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.RequestResponseChannel:$cbs    : namespace[MF_a61cc2_1641797988413] entityPath[$cbs]: Next AMQP channel received, updating 1 current subscribers
2022-01-10 14:59:51.520  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.SendLinkHandler        : onLinkRemoteOpen connectionId[MF_a61cc2_1641797988413], entityPath[$cbs], linkName[cbs:sender], remoteTarget[Target{address='$cbs', durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNodeProp
erties=null, capabilities=null}]
2022-01-10 14:59:51.520  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteOpen connectionId[MF_a61cc2_1641797988413], entityPath[$cbs], linkName[cbs:receiver], remoteSource[Source{address='$cbs', durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNodePr
operties=null, distributionMode=null, filter=null, defaultOutcome=null, outcomes=null, capabilities=null}]
2022-01-10 14:59:51.520  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.SendLinkHandler        : onLinkRemoteOpen connectionId[MF_a61cc2_1641797988413], entityPath[$cbs], linkName[cbs:sender], remoteTarget[Target{address='$cbs',
 durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNodeProperties=null, capabilities=null}]
2022-01-10 14:59:51.520  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteOpen connectionId[MF_a61cc2_1641797988413], entityPath[$cbs], linkName[cbs:receiver], remoteSource[Source{address='$cbs
', durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNodeProperties=null, distributionMode=null, filter=null, defaultOutcome=null, outcomes=null, capabilities=null}]
2022-01-10 14:59:51.535  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.RequestResponseChannel:$cbs    : namespace[MF_a61cc2_1641797988413] entityPath[$cbs]: Channel is now active.
2022-01-10 14:59:51.852  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.ActiveClientTokenManager       : Scheduling refresh token task. scopes[amqp://testsb-hl.servicebus.windows.net/smallsizequeue]
2022-01-10 14:59:51.883  INFO 20140 --- [ctor-executor-1] c.a.c.a.implementation.ReactorSession    : connectionId[MF_a61cc2_1641797988413] sessionId[smallsizequeue] linkName[smallsizequeue_e14a7a_1641797988460] Creating a new receiv
er link.
2022-01-10 14:59:51.203  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.RequestResponseChannel:$cbs    : namespace[MF_a61cc2_1641797988413] entityPath[$cbs]: Next AMQP channel received
, updating 1 current subscribers
2022-01-10 14:59:51.520  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.SendLinkHandler        : onLinkRemoteOpen connectionId[MF_a61cc2_1641797988413], entityPath[$cbs], linkN
ame[cbs:sender], remoteTarget[Target{address='$cbs', durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNodeProperties=null, capabilities=null}]
2022-01-10 14:59:51.520  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteOpen connectionId[MF_a61cc2_1641797988413], entityPath[$cbs], linkN
ame[cbs:receiver], remoteSource[Source{address='$cbs', durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNodeProperties=null, distributionMode=null, filter=n
ull, defaultOutcome=null, outcomes=null, capabilities=null}]
2022-01-10 14:59:51.535  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.RequestResponseChannel:$cbs    : namespace[MF_a61cc2_1641797988413] entityPath[$cbs]: Channel is now active.
2022-01-10 14:59:51.852  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.ActiveClientTokenManager       : Scheduling refresh token task. scopes[amqp://testsb-hl.servicebus.windows.net/s
mallsizequeue]
2022-01-10 14:59:51.883  INFO 20140 --- [ctor-executor-1] c.a.c.a.implementation.ReactorSession    : connectionId[MF_a61cc2_1641797988413] sessionId[smallsizequeue] linkName[smalls
izequeue_e14a7a_1641797988460] Creating a new receiver link.
2022-01-10 14:59:51.890  INFO 20140 --- [ctor-executor-1] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkName[smallsizequeue_e14a7a_1641797988460] entityPath[smallsizequeue]. Setti
ng next AMQP receive link.
2022-01-10 14:59:51.906  INFO 20140 --- [ctor-executor-1] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkCredits: '0', expectedTotalCredit: '1'
2022-01-10 14:59:51.906  INFO 20140 --- [ctor-executor-1] c.a.m.s.i.ServiceBusReceiveLinkProcessor : prefetch: '0', requested: '1', linkCredits: '0', expectedTotalCredit: '1', queu
edMessages:'0', creditsToAdd: '1', messageQueue.size(): '0'
2022-01-10 14:59:51.906  INFO 20140 --- [ctor-executor-1] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Link credits='0', Link credits to add: '1'
2022-01-10 14:59:51.906  INFO 20140 --- [ctor-executor-1] c.a.c.a.implementation.ReactorSession    : linkName[smallsizequeue_e14a7a_1641797988460] entityPath[smallsizequeue] Return
ing existing receive link.
2022-01-10 14:59:52.207  INFO 20140 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteOpen connectionId[MF_a61cc2_1641797988413], entityPath[smallsizeque
ue], linkName[smallsizequeue_e14a7a_1641797988460], remoteSource[Source{address='smallsizequeue', durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNodePrope
rties=null, distributionMode=null, filter=null, defaultOutcome=null, outcomes=null, capabilities=null}]
2022-01-10 14:59:58.228  INFO 20140 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Passing message downstream. sequenceNumber[165]
FluxAutoComplete acquire semaphore
2022-01-10 14:59:58.228  INFO 20140 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkCredits: '0', expectedTotalCredit: '2'
process message
2022-01-10 14:59:58.228  INFO 20140 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : prefetch: '0', requested: '2', linkCredits: '0', expectedTotalCredit: '2', queu
edMessages:'1', creditsToAdd: '1', messageQueue.size(): '0'
2022-01-10 14:59:58.241  INFO 20140 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Link credits='0', Link credits to add: '1'
2022-01-10 14:59:58.241  INFO 20140 --- [oundedElastic-3] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update started. Disposition: COMPLETED. Lock: 66818b05-e182-498
5-a471-98bea55407b2. SessionId: null.
process error
--> ctrl+c
2022-01-10 14:59:58.242  WARN 20140 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Error when processing message. Abandoning message.
2022-01-10 14:59:58.242  INFO 20140 --- [oundedElastic-2] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update started. Disposition: ABANDONED. Lock: 66818b05-e182-498
5-a471-98bea55407b2. SessionId: null.
2022-01-10 14:59:58.860  INFO 20140 --- [ctor-executor-1] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update completed. Disposition: ABANDONED. Lock: 66818b05-e182-4
985-a471-98bea55407b2.
2022-01-10 14:59:58.876  INFO 20140 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Requesting 1 more message from upstream
ServiceBusProcessorClient close() start
2022-01-10 15:08:32.700  INFO 20140 --- [ionShutdownHook] c.a.m.s.ServiceBusReceiverAsyncClient    : Removing receiver links.
2022-01-10 15:08:32.700  INFO 20140 --- [ionShutdownHook] c.a.m.s.ServiceBusClientBuilder          : Closing a dependent client. # of open clients: 0
2022-01-10 15:08:32.700  INFO 20140 --- [ionShutdownHook] c.a.m.s.ServiceBusClientBuilder          : No more open clients, closing shared connection [ServiceBusConnectionProcessor]
.
2022-01-10 15:08:32.700  INFO 20140 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : Upstream connection publisher was completed. Terminating processor.
2022-01-10 15:08:32.700  INFO 20140 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: AMQP channel proce
ssor completed. Notifying 0 subscribers.
2022-01-10 15:08:32.700  INFO 20140 --- [ionShutdownHook] c.a.c.a.i.ReactorConnection              : connectionId[MF_a61cc2_1641797988413] signal[Disposed by client., isTransient[f
alse], initiatedByClient[true]]: Disposing of ReactorConnection.
2022-01-10 15:08:32.721  INFO 20140 --- [ionShutdownHook] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Channel is dispose
d.
2022-01-10 15:08:32.721  WARN 20140 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : Unable to 'complete' message.
java.lang.InterruptedException
2022-01-10 15:08:32.731 ERROR 20140 --- [oundedElastic-3] reactor.core.publisher.Operators         : Operator called default onErrorDropped

reactor.core.Exceptions$ReactiveException: java.lang.InterruptedException
        at reactor.core.Exceptions.propagate(Exceptions.java:392) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at reactor.core.publisher.BlockingSingleSubscriber.blockingGet(BlockingSingleSubscriber.java:91) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at reactor.core.publisher.Mono.block(Mono.java:1707) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at com.azure.messaging.servicebus.FluxAutoComplete$AutoCompleteSubscriber.applyWithCatch(FluxAutoComplete.java:144) ~[classes!/:0.0.1-SNAPSHOT]
        at com.azure.messaging.servicebus.FluxAutoComplete$AutoCompleteSubscriber.hookOnNext(FluxAutoComplete.java:91) ~[classes!/:0.0.1-SNAPSHOT]
        at com.azure.messaging.servicebus.FluxAutoComplete$AutoCompleteSubscriber.hookOnNext(FluxAutoComplete.java:52) ~[classes!/:0.0.1-SNAPSHOT]
        at reactor.core.publisher.BaseSubscriber.onNext(BaseSubscriber.java:160) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at com.azure.messaging.servicebus.FluxAutoLockRenew$LockRenewSubscriber.hookOnNext(FluxAutoLockRenew.java:171) ~[classes!/:0.0.1-SNAPSHOT]
        at com.azure.messaging.servicebus.FluxAutoLockRenew$LockRenewSubscriber.hookOnNext(FluxAutoLockRenew.java:76) ~[classes!/:0.0.1-SNAPSHOT]
        at reactor.core.publisher.BaseSubscriber.onNext(BaseSubscriber.java:160) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at reactor.core.publisher.FluxMap$MapSubscriber.onNext(FluxMap.java:120) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at reactor.core.publisher.FluxMap$MapSubscriber.onNext(FluxMap.java:120) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at com.azure.messaging.servicebus.implementation.ServiceBusReceiveLinkProcessor.drainQueue(ServiceBusReceiveLinkProcessor.java:478) ~[classes!/:0.0.1-SNAPSHOT]
        at com.azure.messaging.servicebus.implementation.ServiceBusReceiveLinkProcessor.drain(ServiceBusReceiveLinkProcessor.java:437) ~[classes!/:0.0.1-SNAPSHOT]
        at com.azure.messaging.servicebus.implementation.ServiceBusReceiveLinkProcessor.lambda$onNext$2(ServiceBusReceiveLinkProcessor.java:210) ~[classes!/:0.0.1-SNAPSHOT]
        at reactor.core.publisher.LambdaSubscriber.onNext(LambdaSubscriber.java:160) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at reactor.core.publisher.FluxPublishOn$PublishOnSubscriber.runAsync(FluxPublishOn.java:440) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at reactor.core.publisher.FluxPublishOn$PublishOnSubscriber.run(FluxPublishOn.java:527) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at reactor.core.scheduler.WorkerTask.call(WorkerTask.java:84) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at reactor.core.scheduler.WorkerTask.call(WorkerTask.java:37) ~[reactor-core-3.4.12.jar!/:3.4.12]
        at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264) ~[na:na]
        at java.base/java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:304) ~[na:na]
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136) ~[na:na]
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635) ~[na:na]
        at java.base/java.lang.Thread.run(Thread.java:833) ~[na:na]
Caused by: java.lang.InterruptedException: null
        at java.base/java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireSharedInterruptibly(AbstractQueuedSynchronizer.java:1048) ~[na:na]
        at java.base/java.util.concurrent.CountDownLatch.await(CountDownLatch.java:230) ~[na:na]
        at reactor.core.publisher.BlockingSingleSubscriber.blockingGet(BlockingSingleSubscriber.java:87) ~[reactor-core-3.4.12.jar!/:3.4.12]
        ... 23 common frames omitted

2022-01-10 15:08:32.731  INFO 20140 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Finished. sequenceNumber[165]
FluxAutoComplete release semaphore
ServiceBusProcessorClient close() asyncClient shutdown
ServiceBusProcessorClient close() end

```
[log for not adding timeout]
```
2022-01-10 16:26:43.899  INFO 26320 --- [lication.main()] c.s.demo.DemoSpringBootApplication       : Starting DemoSpringBootApplication using Java 17.0.1 on haolindong-712 with PID 26320 (C:\workspace\servicebus-test\target\classes started by haolingdong in C:\workspace\servicebus-test)
2022-01-10 16:26:43.903  INFO 26320 --- [lication.main()] c.s.demo.DemoSpringBootApplication       : No active profile set, falling back to default profiles: default
2022-01-10 16:26:44.712  INFO 26320 --- [lication.main()] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Setting next AMQP channel.
2022-01-10 16:26:44.728  INFO 26320 --- [lication.main()] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Next AMQP channel received, updating 0 current subscribers
2022-01-10 16:26:44.728  INFO 26320 --- [lication.main()] c.a.m.s.ServiceBusClientBuilder          : # of open clients with shared connection: 1
2022-01-10 16:26:44.752  INFO 26320 --- [lication.main()] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Creating consumer for link 'smallsizequeue_37d1da_1641803204752'
2022-01-10 16:26:44.752  INFO 26320 --- [lication.main()] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Requesting a new AmqpReceiveLink from upstream.
2022-01-10 16:26:44.767  INFO 26320 --- [lication.main()] c.a.c.a.i.ReactorConnection              : connectionId[MF_812b28_1641803204681]: Creating and starting connection to testsb-hl.servicebus.windows.net:5671
2022-01-10 16:26:44.830  INFO 26320 --- [lication.main()] c.a.c.a.implementation.ReactorExecutor   : connectionId[MF_812b28_1641803204681] message[Starting reactor.]
2022-01-10 16:26:44.834  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.ConnectionHandler      : onConnectionInit connectionId[MF_812b28_1641803204681] hostname[testsb-hl.servicebus.windows.net] amqpHostname[testsb-hl.servicebus.windows.net]
2022-01-10 16:26:44.834  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.ReactorHandler         : connectionId[MF_812b28_1641803204681] reactor.onReactorInit
2022-01-10 16:26:44.834  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.ConnectionHandler      : onConnectionLocalOpen connectionId[MF_812b28_1641803204681] hostname[testsb-hl.servicebus.windows.net] errorCondition[null] errorDescription[null]
2022-01-10 16:26:44.864  INFO 26320 --- [lication.main()] c.a.m.servicebus.FluxAutoComplete        : Subscription received. Subscribing downstream. reactor.core.publisher.FluxMap$MapSubscriber@1fafe3a8
2022-01-10 16:26:44.864  INFO 26320 --- [lication.main()] f.a.AutowiredAnnotationBeanPostProcessor : Autowired annotation is not supported on static fields: static com.azure.messaging.servicebus.ServiceBusProcessorClient com.servicebus.demo.ServiceBusMessageHandler.serviceBusProcessorClient
2022-01-10 16:26:44.983  INFO 26320 --- [lication.main()] c.s.demo.DemoSpringBootApplication       : Started DemoSpringBootApplication in 1.495 seconds (JVM running for 8.605)
2022-01-10 16:26:44.998  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.ConnectionHandler      : onConnectionBound connectionId[MF_812b28_1641803204681] hostname[testsb-hl.servicebus.windows.net] peerDetails[testsb-hl.servicebus.windows.net:5671]
2022-01-10 16:26:46.918  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.ConnectionHandler      : onConnectionRemoteOpen hostname[testsb-hl.servicebus.windows.net], connectionId[MF_812b28_1641803204681], remoteContainer[9c2604c2da8a493ca0a6d86dba2f5936_G13]
2022-01-10 16:26:46.918  INFO 26320 --- [ctor-executor-1] c.a.m.s.i.ServiceBusConnectionProcessor  : namespace[testsb-hl.servicebus.windows.net] entityPath[N/A]: Channel is now active.
2022-01-10 16:26:47.241  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.SessionHandler         : onSessionRemoteOpen connectionId[MF_812b28_1641803204681], entityName[smallsizequeue], sessionIncCapacity[0], sessionOutgoingWindow[2147483647]
2022-01-10 16:26:47.272  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.ReactorConnection              : Setting CBS channel.
2022-01-10 16:26:47.557  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.SessionHandler         : onSessionRemoteOpen connectionId[MF_812b28_1641803204681], entityName[cbs-session], sessionIncCapacity[0], sessionOutgoingWindow[2147483647]
2022-01-10 16:26:47.588  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.ReactorConnection              : connectionId[MF_812b28_1641803204681] entityPath[$cbs] linkName[cbs] Emitting new response channel.
2022-01-10 16:26:47.588  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.RequestResponseChannel:$cbs    : namespace[MF_812b28_1641803204681] entityPath[$cbs]: Setting next AMQP channel.
2022-01-10 16:26:47.588  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.RequestResponseChannel:$cbs    : namespace[MF_812b28_1641803204681] entityPath[$cbs]: Next AMQP channel received, updating 1 current subscribers
2022-01-10 16:26:47.905  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.SendLinkHandler        : onLinkRemoteOpen connectionId[MF_812b28_1641803204681], entityPath[$cbs], linkName[cbs:sender], remoteTarget[Target{address='$cbs', durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNodePr
operties=null, capabilities=null}]
2022-01-10 16:26:47.905  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteOpen connectionId[MF_812b28_1641803204681], entityPath[$cbs], linkName[cbs:receiver], remoteSource[Source{address='$cbs', durable=NONE, expiryPolicy=SESSION_END, timeout=0, dynamic=false, dynamicNode
Properties=null, distributionMode=null, filter=null, defaultOutcome=null, outcomes=null, capabilities=null}]
2022-01-10 16:26:47.905  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.RequestResponseChannel:$cbs    : namespace[MF_812b28_1641803204681] entityPath[$cbs]: Channel is now active.
2022-01-10 16:26:48.221  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.ActiveClientTokenManager       : Scheduling refresh token task. scopes[amqp://testsb-hl.servicebus.windows.net/smallsizequeue]
2022-01-10 16:26:48.243  INFO 26320 --- [ctor-executor-1] c.a.c.a.implementation.ReactorSession    : connectionId[MF_812b28_1641803204681] sessionId[smallsizequeue] linkName[smallsizequeue_37d1da_1641803204752] Creating a new receiver link.
2022-01-10 16:26:48.243  INFO 26320 --- [ctor-executor-1] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkName[smallsizequeue_37d1da_1641803204752] entityPath[smallsizequeue]. Setting next AMQP receive link.
2022-01-10 16:26:48.259  INFO 26320 --- [ctor-executor-1] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkCredits: '0', expectedTotalCredit: '1'
2022-01-10 16:26:48.259  INFO 26320 --- [ctor-executor-1] c.a.m.s.i.ServiceBusReceiveLinkProcessor : prefetch: '0', requested: '1', linkCredits: '0', expectedTotalCredit: '1', queuedMessages:'0', creditsToAdd: '1', messageQueue.size(): '0'
2022-01-10 16:26:48.259  INFO 26320 --- [ctor-executor-1] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Link credits='0', Link credits to add: '1'
2022-01-10 16:26:48.259  INFO 26320 --- [ctor-executor-1] c.a.c.a.implementation.ReactorSession    : linkName[smallsizequeue_37d1da_1641803204752] entityPath[smallsizequeue] Returning existing receive link.
2022-01-10 16:26:48.562  INFO 26320 --- [ctor-executor-1] c.a.c.a.i.handler.ReceiveLinkHandler     : onLinkRemoteOpen connectionId[MF_812b28_1641803204681], entityPath[smallsizequeue], linkName[smallsizequeue_37d1da_1641803204752], remoteSource[Source{address='smallsizequeue', durable=NONE, expiryPolicy=SESSION
_END, timeout=0, dynamic=false, dynamicNodeProperties=null, distributionMode=null, filter=null, defaultOutcome=null, outcomes=null, capabilities=null}]
2022-01-10 16:26:48.609  INFO 26320 --- [oundedElastic-3] c.a.m.servicebus.FluxAutoComplete        : ON NEXT: Passing message downstream. sequenceNumber[166]
FluxAutoComplete acquire semaphore
2022-01-10 16:26:48.609  INFO 26320 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : linkCredits: '0', expectedToprocess message
talCredit: '2'
2022-01-10 16:26:48.635  INFO 26320 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : prefetch: '0', requested: '2', linkCredits: '0', expectedTotalCredit: '2', queuedMessages:'1', creditsToAdd: '1', messageQueue.size(): '0'
2022-01-10 16:26:48.635  INFO 26320 --- [oundedElastic-3] c.a.m.s.i.ServiceBusReceiveLinkProcessor : Link credits='0', Link credits to add: '1'
process error
--> ctrl+c
2022-01-10 16:26:48.635  WARN 26320 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Error when processing message. Abandoning message.
2022-01-10 16:26:48.635  INFO 26320 --- [oundedElastic-3] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update started. Disposition: COMPLETED. Lock: 138ca674-910d-443a-91b4-0a1fd1c968b5. SessionId: null.
2022-01-10 16:26:48.635  INFO 26320 --- [oundedElastic-2] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update started. Disposition: ABANDONED. Lock: 138ca674-910d-443a-91b4-0a1fd1c968b5. SessionId: null.
2022-01-10 16:26:49.239  INFO 26320 --- [ctor-executor-1] c.a.m.s.ServiceBusReceiverAsyncClient    : smallsizequeue: Update completed. Disposition: ABANDONED. Lock: 138ca674-910d-443a-91b4-0a1fd1c968b5.
2022-01-10 16:26:49.245  INFO 26320 --- [oundedElastic-2] c.a.m.s.ServiceBusProcessorClient        : Requesting 1 more message from upstream
ServiceBusProcessorClient close() start
```
