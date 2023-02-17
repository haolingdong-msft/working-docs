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
op upload(data: string | bytes | Resource, @header contentType: "text/plain" | "application/json" | "application/octet-stream" | "image/jpeg" | "image/png"): void;
```

### SDK

I wrote three options on the generated SDK. For each options, I listed the pros and cons from my understanding.

#### **Option 1: Generate protocol method only**

```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> uploadWithResponse(String contentType, BinaryData request, RequestOptions requestOptions) {
    return this.client.uploadWithResponse(contentType, request, requestOptions).block();
}
```

**Pros:** 
1. Easy to extend the feature like generating convenience methods. 
2. Implementation cost low. 

**Cons:**
1. may be lack of usibility.

#### Option 2: Generate convenience methods according to content type and data type mapping

In Option 2, we don't expose union base class, but map the content type to modulerfour type, for each modulerfour type, we will find the corresponding data type and generate convenience method.

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
    BinaryData request = BinaryData.fromString(data);
    uploadWithResponse(contentType, request, requestOptions).getValue();
}
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void upload(byte[] data, ContentType contentType) {
    // Generated convenience method for uploadWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // Set content-type to header, it can be: "application/octet-stream" | "image/jpeg" | "image/png"
    BinaryData request = BinaryData.fromBytes(data);
    uploadWithResponse(contentType, request, requestOptions).getValue();
}
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void upload(Resource data) {
    // Generated convenience method for uploadWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // Set "application/json" to header
    BinaryData request = BinaryData.fromObject(data);
    uploadWithResponse(contentType, request, requestOptions).getValue();
}
```

**Pros:** 
1. consistent with modulerfour, user friendly.

**Cons:**
1. Implementation cost high, hard to catch March GA.


#### My preference
We use Option 1 for March GA, and later if needed, we can extend it using Option 2. 

## Case 2

In case 2, we use @overload to define convenience methods.

### Cadl
```ts
@doc("Using `@overload`")
@route("/upload")
op upload(data: string | bytes | Resource, @header contentType: "text/plain" | "application/json" | "application/octet-stream" | "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadString(data: string, @header contentType: "text/plain" ): void;
@overload(upload)
op uploadBytes(data: bytes, @header contentType: "application/octet-stream" | "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadStringOrResource(data: string | Resource, @header contentType: "text/plain" | "application/json"): void;
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
    BinaryData request = BinaryData.fromString(data);
    uploadWithResponse(request, requestOptions).getValue();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void upload(byte[] data, ContentType contentType) {
    // Generated convenience method for uploadBytesWithResponse
    RequestOptions requestOptions = new RequestOptions();
    // Set contentType to header
    BinaryData request = BinaryData.fromBytes(data);
    uploadWithResponse(contentType, request, requestOptions).getValue();
}
// Choose Option 1: we don't generate convenience method for uploadStringOrResource(), user just use the protocol method.
// Choose Option 2: We can generate the convenience methd like option2.
// Choose Option 2: Not applicable to this case?
```

### Open Questions
- Currently we consider `@overload` as methods with the same. Another choice is we generate methods with different names: `uploadString`, `uploadBytes`, `uploadStringOrResource`, if with different names, overload operations are similar to general operations except the route is the same. Do we agree on considering `@overload` as methods with the same?
- In the above example, we don't have conveniece method for `Resource` type. If user wants to send request with content type as "application/json", since he/she does not define overload method for it, he/she needs to use the protocol method to send the request. Do we need to generate convenient method for content types that does not define overload methods?
- What if overload methods have same signature? shall we use different name? e.g.
```ts
@overload(upload)
op uploadImage(data: string, @header contentType: "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadFile(data: bytes, @header contentType: "application/octet-stream"): void;
```

## Case 3

In case 3, we use shared route feature to support multiple content types.


### Cadl
```ts
@doc("Using shared route")
@route("/uploadImage", { shared: true })
op uploadImageBytes(@body body: bytes, @header contentType: "image/png"): void;
@route("/uploadImage", { shared: true })
op uploadImageJson(@body body: {imageBase64: bytes}, @header contentType: "application/json"): void;
```

### SDK

Here we don't have special logic to handle this case. We just treat them as general operations, except for the routings are the same.

```java
@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> uploadImageBytesWithResponse(BinaryData body, RequestOptions requestOptions) {
    return this.client.uploadImageBytesWithResponse(body, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public Response<Void> uploadImageJsonWithResponse(BinaryData body, RequestOptions requestOptions) {
    return this.client.uploadImageJsonWithResponse(body, requestOptions).block();
}

@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void uploadImageBytes(byte[] body) {
    // Generated convenience method for uploadImageBytesWithResponse
    RequestOptions requestOptions = new RequestOptions();
    uploadImageBytesWithResponse(BinaryData.fromObject(body), requestOptions).getValue();
}


@Generated
@ServiceMethod(returns = ReturnType.SINGLE)
public void uploadImageJson() {
    // Generated convenience method for uploadImageJsonWithResponse
    RequestOptions requestOptions = new RequestOptions();
    uploadImageJsonWithResponse(body, requestOptions).getValue();
}
```

## Other Cases

There are still other cases that need to be considered.

- `@overload` on response type
Java can't overload on response type.
(contentType): Ressource1
(contentType): Ressource2

- `@overload` together with `@internal`, shall we keep the overload method name? [python gist](https://gist.github.com/msyyc/87a79b917deec25639f9f10d20589e55?permalink_comment_id=4472409#gistcomment-4472409)
```ts
@doc("Using `@overload`")
@route("/upload")
@internal
op upload(data: string | bytes | Resource, @header contentType: "text/plain" | "application/json" | "application/octet-stream" | "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadString(data: string, @header contentType: "text/plain" ): void;
@overload(upload)
op uploadBytes(data: bytes, @header contentType: "application/octet-stream" | "image/jpeg" | "image/png"): void;
@overload(upload)
op uploadStringOrResource(data: string | Resource, @header contentType: "text/plain" | "application/json"): void;
```


<!-- For operations who define content-type as header parameter, cadl compiler will return four operations. we can treat overload operations the same as general operations, except for overload operations, we don't need to generate protocol methods. I wonder if we can just treat overload operations as `ProtocolApi=false`, which means we will still generate protocol methods with name `uploadString`, `uploadBytes`, `uploadStringOrResource`, but with package-private visibility. -->