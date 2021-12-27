# Issue Root Cause Analysis

## Issue summary
https://github.com/Azure/azure-sdk-for-java/issues/25709

User creates a Spring bean that returns a ServiceBusProcessorClient instance. Define a processMessage and processError handler. In the processMessage handler function, do "throw new NullPointerException()". Observe that processError function is called. Try to stop the application using Ctrl-c. Observe that it is not possible to fully stop it. Can only kill the java-process using kill or system console.

## Reproduce issue

I did below three experiments. I defined below `processMessageHandler` which throw NullPointorException for all experiments.

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

| SpringBoot | Define ServiceBusProcessorClient as bean | Result                                                                                     |
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
    static String connectionString = "Endpoint=sb://testsb-hl.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=omXzcCxktQVAJIyVGtkY03ETZG7ubPA++QicRc87ihM=";
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
