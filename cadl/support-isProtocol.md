# Support `ProtocolApi` and `ConvenientApi`

## Design

### Generated SDK

We defined five operations with different `@convenientApi` and `@protocolApi` decorators. Below are the cadl definition and corresponding generated SDK will be look like.

**Cadl definition**
```typescript
interface ProtocolAndConvenienceOp {
  @doc("When set protocol false and convenient true, then the protocol method should be package private")
  @route("internalProtocol")
  @post
  @convenientAPI(true)
  @protocolAPI(false)
  op onlyConvenient(@body body: Resource): Resource;  

  @doc("When set protocol true and convenient false, only the protocol method should be generated")
  @route("onlyProtocol")
  @get
  @convenientAPI(false)
  @protocolAPI(true)
  op onlyProtocol(): void;

  @doc("When set protocol false and convenient false, this will throw error in emitter")
  @route("errorSetting")
  @get
  @convenientAPI(false)
  @protocolAPI(false)
  op errorSetting(@body body: Resource): Resource;

  @doc("Setting protocol true and convenient true, both convenient and protocol methods will be generated")
  @route("bothConvenientAndProtocol")
  @get
  @convenientAPI(false)
  @protocolAPI(false)
  op bothConvenientAndProtocol(@body body: Resource): Resource;

  @doc("Default behavior is both convenient and protocol methods will be generated")
  @route("default")
  @get
  op default(@body body: Resource): Resource;
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
public Resource onlyConvenient(Resource body) {
    // Generated convenience method for onlyConvenientWithResponse
    RequestOptions requestOptions = new RequestOptions();
    return onlyConvenientWithResponse(BinaryData.fromObject(body), requestOptions)
            .getValue()
            .toObject(Resource.class);
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
public Resource bothConvenientAndProtocol(Resource body) {
    // Generated convenience method for bothConvenientAndProtocolWithResponse
    RequestOptions requestOptions = new RequestOptions();
    return bothConvenientAndProtocolWithResponse(BinaryData.fromObject(body), requestOptions)
            .getValue()
            .toObject(Resource.class);
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
public Resource defaultMethod(Resource body) {
    // Generated convenience method for defaultMethodWithResponse
    RequestOptions requestOptions = new RequestOptions();
    return defaultMethodWithResponse(BinaryData.fromObject(body), requestOptions)
            .getValue()
            .toObject(Resource.class);
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
