# **Multiple Content Type Design**

# Use cases

## Case 1

In case 1, we define an operation with multiple data types and content types, without defining `@overload` decorator.

### Cadl
```ts
model Resource {
  @visibility("read")
  id: string;

  @key
  @segment("resources")
  name: string;
  description?: string;
  type: string;
}

@doc("Using union in operation without defining overload mapping")
@route("/upload")
op upload(@body data: string | bytes | Resource, @header contentType: "text/plain" | "application/json" | "application/octet-stream" | "image/jpeg" | "image/png"): void;
```

### SDK

I wrote two options on the generated SDK. For each options, I listed the pros and cons from my understanding.

#### **Option 1: Generate protocol method only**

```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> uploadWithResponse(String contentType, BinaryData request, RequestOptions requestOptions) {
    return this.client.uploadWithResponse(contentType, request, requestOptions).block();
}
```

**Pros:** 
1. Easy to extend the feature, e.g. generate convenience methods. 
2. Implementation cost low. 

**Cons:**
1. May be lack of usibility.

#### Option 2: Generate convenience methods according to content type and data type mapping

In Option 2, we will map the content type to modulerfour type, for each modulerfour type, we will find the corresponding data type and generate convenience method.

```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> uploadWithResponse(String contentType, BinaryData request, RequestOptions requestOptions) {
    return this.client.uploadWithResponse(contentType, request, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void upload(String data) {
    // Generated convenience method for uploadWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // Set "text/plain" to header
    uploadWithResponse(contentType, BinaryData.fromString(data), requestOptions).getValue();
}

// comments describing the content-type can be: "application/octet-stream" | "image/jpeg" | "image/png"
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void upload(byte[] data, ContentType contentType) {
    // Generated convenience method for uploadWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // Set content-type to header, it can be: "application/octet-stream" | "image/jpeg" | "image/png"
    uploadWithResponse(contentType, BinaryData.fromBytes(data), requestOptions).getValue();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void upload(Resource data) {
    // Generated convenience method for uploadWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // Set "application/json" to header
    uploadWithResponse(contentType, BinaryData.fromObject(data), requestOptions).getValue();
}
```

**Pros:** 
1. consistent with modulerfour, user friendly.

**Cons:**
1. Implementation cost high, hard to catch March GA.


#### My preference
We use Option 1 for March GA, and later if needed, we can extend it using Option 2. 

#### Notes
This case is invalid because we don't the mapping between body type and content type. We want to prevent this case from linter. Before linter is ready, we can either throw error or generate protocol method only for this case.


## Case 2

In case 2, we use @overload to define convenience methods.

### Cadl
```ts
@doc("Using `@overload`")
@route("/upload")
op upload(@body data: string | bytes | Resource, @header contentType: "text/plain" | "application/json" | "application/octet-stream" | "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadString(@body data: string, @header contentType: "text/plain" ): void;
@overload(upload)
op uploadBytes(@body data: bytes, @header contentType: "application/octet-stream" | "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadStringOrResource(@body data: string | Resource, @header contentType: "text/plain" | "application/json"): void; // This case is triky, user might not define like this way, but want to bring this up since user can define this way, and it causes complexity in SDK.
```

### SDK:

We will generate protocol method and convenient methods for the operations defined with @overload. For the operation `uploadStringOrResource`, it's a bit tricky, I wrote it as comment in below code snippet.

```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> uploadWithResponse(BinaryData request, RequestOptions requestOptions) {
    return this.client.uploadWithResponse(request, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void upload(String data) {
    // Generated convenience method for uploadStringWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // Set content-type as "text/plain" to header
    uploadWithResponse(BinaryData.fromString(data), requestOptions).getValue();
}

// comments describing the content-type can be: "application/octet-stream" | "image/jpeg" | "image/png"
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void upload(byte[] data, ContentType contentType) {
    // Generated convenience method for uploadBytesWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // Set contentType to header
    uploadWithResponse(contentType, BinaryData.fromBytes(data), requestOptions).getValue();
}
// For generating uploadStringOrResource():
// Choose Option 1: we don't generate convenience method for uploadStringOrResource(), user just use the protocol method.
// Choose Option 2: Not applicable to this case?
```

### Open Questions

- Currently we consider `@overload` as methods with the same. Another choice is we generate methods with different names: `uploadString`, `uploadBytes`, `uploadStringOrResource`, if with different names, overload operations are similar to general operations except the route is the same. Do we agree on considering `@overload` as methods with the same name? -> Yes, overload means method with the same name.
- In the above example, we don't have conveniece method for `Resource` type. If user wants to send request with content type as "application/json", since he/she does not define overload method for it, he/she needs to use the protocol method to send the request. Do we need to generate convenient method for content types that does not define overload methods? -> if the user does not define overload, we will not generate convenient method for them.
- What if overload methods have same signature from Java code perspective? shall we use different name? e.g.  -> prevent from linter
```ts
@overload(upload)
op uploadImage(@body data: bytes, @header contentType: "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadFile(@body data: bytes, @header contentType: "application/octet-stream"): void;
```

## Case 3

In case 3, we use 'shared route' feature to support multiple content types.


### Cadl
```ts
@doc("Using shared route")
@route("/upload", { shared: true })
op uploadString(@body data: string, @header contentType: "text/plain"): void;
@route("/upload", { shared: true })
op uploadBytes(@body data: bytes, @header contentType: "application/octet-stream" | "image/jpeg" | "image/png"): void;
```

### SDK

Here we don't want to have special logic to handle this case. We just treat them as general operations, except for the routings are the same. So we will generate two protocol methods and two convenient methods.

```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> uploadStringWithResponse(BinaryData request, RequestOptions requestOptions) {
    return this.client.uploadStringWithResponse(request, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> uploadBytesWithResponse(
        String contentType, BinaryData request, RequestOptions requestOptions) {
    return this.client.uploadBytesWithResponse(contentType, request, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void uploadString(String data) {
    // Generated convenience method for uploadStringWithResponse
    RequestOptions requestOptions = new RequestOptions();
    uploadStringWithResponse(BinaryData.fromString(data), requestOptions).getValue();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void uploadBytes(byte[] data, ContentType contentType) {
    // Generated convenience method for uploadBytesWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // set contentType to header
    uploadStringWithResponse(BinaryData.fromBytes(data), requestOptions).getValue();
}
```

## Other Cases

There are still other cases that need to be considered.

- `@overload` on response type
 
For overload with the same input parameters, we will use client.cadl to overwrite the name of the method to be different.
For overload with different input parameters, we will need to generate method with the same name.

- `@overload` together with `@internal`, shall we keep the overload method name? [python decision](https://gist.github.com/msyyc/87a79b917deec25639f9f10d20589e55?permalink_comment_id=4472409#gistcomment-4472409)
```ts
@doc("Using `@overload`")
@route("/upload")
@internal
op upload(@body data: string | bytes | Resource, @header contentType: "text/plain" | "application/json" | "application/octet-stream" | "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadString(@body data: string, @header contentType: "text/plain" ): void;
@overload(upload)
op uploadBytes(@body data: bytes, @header contentType: "application/octet-stream" | "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadStringOrResource(@body data: string | Resource, @header contentType: "text/plain" | "application/json"): void;
```


<!-- For operations who define content-type as header parameter, cadl compiler will return four operations. we can treat overload operations the same as general operations, except for overload operations, we don't need to generate protocol methods. I wonder if we can just treat overload operations as `ProtocolApi=false`, which means we will still generate protocol methods with name `uploadString`, `uploadBytes`, `uploadStringOrResource`, but with package-private visibility. -->
