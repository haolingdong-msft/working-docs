# Support `ProtocolApi` and `ConvenientApi`

## Design

### Generated SDK

We defined five operations with different `@convenientApi` and `@protocolApi` decorators. Below are the cadl definition and corresponding generated SDK will be look like.

**Cadl definition**
```typescript
interface ProtocolAndConvenienceOp {
    @doc("When set protocol false and convenient true, then the protocol method should be package private")
    @route("onlyConvenient")
    @post
    @convenientAPI(true)
    @protocolAPI(false)
    onlyConvenient(@body body: ResourceA): ResourceB;

    @doc("When set protocol true and convenient false, only the protocol method should be generated, ResourceC and ResourceD should not be generated")
    @route("onlyProtocol")
    @post
    @convenientAPI(false)
    @protocolAPI(true)
    onlyProtocol(@body body: ResourceC): ResourceD;

    @doc("When set protocol false and convenient false")
    @route("errorSetting")
    @post
    @convenientAPI(false)
    @protocolAPI(false)
    errorSetting(@body body: ResourceC): ResourceD;

    @doc("Setting protocol true and convenient true, both convenient and protocol methods will be generated")
    @route("bothConvenientAndProtocol")
    @post
    @convenientAPI(true)
    @protocolAPI(true)
    bothConvenientAndProtocol(@body body: ResourceA): ResourceB;

    @doc("Default behavior is both convenient and protocol methods will be generated")
    @route("default")
    @post
    default(@body body: ResourceA): ResourceB;
}
```

**SDK**
```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
Response<BinaryData> onlyConvenientWithResponse(BinaryData body, RequestOptions requestOptions) {
    return this.client.onlyConvenientWithResponse(body, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public ResourceB onlyConvenient(ResourceA body) {
    // Generated convenience method for onlyConvenientWithResponse
    RequestOptions requestOptions = new RequestOptions();
    return onlyConvenientWithResponse(BinaryData.fromObject(body), requestOptions)
            .getValue()
            .toObject(ResourceB.class);
}
```
```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> onlyProtocolWithResponse(RequestOptions requestOptions) {
    return this.client.onlyProtocolWithResponse(requestOptions).block();
}
```
```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<BinaryData> bothConvenientAndProtocolWithResponse(BinaryData body, RequestOptions requestOptions) {
    return this.client.bothConvenientAndProtocolWithResponse(body, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public ResourceB bothConvenientAndProtocol(ResourceA body) {
    // Generated convenience method for bothConvenientAndProtocolWithResponse
    RequestOptions requestOptions = new RequestOptions();
    return bothConvenientAndProtocolWithResponse(BinaryData.fromObject(body), requestOptions)
            .getValue()
            .toObject(ResourceB.class);
}

```

```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<BinaryData> defaultMethodWithResponse(BinaryData body, RequestOptions requestOptions) {
    return this.client.defaultMethodWithResponse(body, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public ResourceB defaultMethod(ResourceA body) {
    // Generated convenience method for defaultMethodWithResponse
    RequestOptions requestOptions = new RequestOptions();
    return defaultMethodWithResponse(BinaryData.fromObject(body), requestOptions)
            .getValue()
            .toObject(ResourceB.class);
}
```



### Internal logic for emittr and codegen

* Emitter:

We will have `protocolApi: boolean` to set generating protocol Api or not.

code-model.yaml
```yaml
protocolApi: false
convenienceApi:
    language:
    default:
        name: onlyConvenient
        description: ''
    protocol: {}
```

* Codegen

Set visibility of ClientMethod according to `operation.protocolApi` in `ClientMethodMapper`.
