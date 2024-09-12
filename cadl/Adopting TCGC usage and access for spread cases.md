# Adopting TCGC usage and access for spread and flatten body cases

## Terminology
As flatten or spread concepts are quite confusing, this document will use below definition:
- spread body case: it means spreading a model using `...`, e.g. `op(...AModel)`
- flatten body case: it means defining request body without `@body` and not using spread syntax `...`, e.g. `op(a: AModel)`

## TCGC logic
If a body parameter is defined without @body, TCGC will create an anonymous model with `spread` usage for it, unless it is like case1, where there is only single spread body param, it will not create anonymous model, but reuse the spreaded model. 

##  Cases
[playground](https://cadlplayground.z22.web.core.windows.net/cadl-azure/?c=aW1wb3J0ICJAdHlwZXNwZWMvcmVzdCI7DQrSGnZlcnNpb25pbmfNIGF6dXJlLXRvb2xzL8gsLWNsaWVudC1nZW5lcmF0b3ItY29yZcQ3DQp1c2luZyBUeXBlU3BlYy5IdHRwO9EWVslsyRxBxGguQ8VZR8hYLkNvcmXFV0BzZXJ2aWNlKHsNCiAgdGl0bGU6ICJTcHJlYWQiLA0KfSnHJGVyKMQiIntlbmRwb2ludH0vb3BlbmFpxCYgICIvyjQgIMVNICDIKzogc3RyaW5nxRx9DQrEVOcBF2VkKFPmAIJBcGnnAL9zKQ0KbmFtZXNwYWNlIENhZGwuxl3lALJlbnVtINI0xnR2MjAyMl8wNl8wMV9wcmV2aWV3OiAixBUtMDYtMDEtxxXlANvETkBkb2MoIlRoZSDKTCBxdWVyeSBwYXJhbWV0ZXIuIikNCm1vZGVsyyVQyB7GeUDFNCgiYXBpLecA28Q2ICBAbWluTGVuZ3RoKDHGEcpyUEkgxywgdG8gdXNlIGZvciB0aGlzIG9w5AGqaW9uxX0gIGHJeegBTTvnAMLnAJnoAXRwMcshxREy1zJQYXRjaMo3P9E4zBLFOUDmAqDmAiznAjk67AGh5QHh5AG76QJE5gJ56QJKcm91dGUoIi9zxR3kANtpbnRlcmbkAelGbGF0dGVuT3DoAJQvLyDIMW9wMcQtyBZwb3N0yQ5vcCBvcDEoLi4uQSk6IHZvaeYCKNFCMt5CMihhOiDNQtNEM95EM%2BUAhiwgc%2BgBOv0AkTTeTTTlAJHbTdNTNd5TNShAcGF0aCBpZMhULCD%2FAThvcDbeVDbTVPABSvcArjfeWjflBHLFEMQBQGhlYWRlciBjb250ZW505AT1OiAiYXBwbGlj5QMrL21lcmdlLXDkAtgranNvbuYEjclBxRk65wL58ACf8wCW6wCT5QCQOOcAkPoAjW11bHRpcGFydC9mb3JtLWRhdGHoAITEAWJvZHk6IGJ5dGVzzH99DQo%3D&e=%40azure-tools%2Ftypespec-autorest&options=%7B%7D)

### Common definitions
```tsp
model A {
    p1: string;
    p2: string;  
}

model APatch {
    p1?: string;
    p2?: string;
}
```

### case1: single spread body param
```tsp
op op1(...A);
```

TCGC return:
```ts
A: {
  access: internal
  usage: spread
}
```

code-model expected return:
```ts
A: {
    usage: ["internal", "input"]
}
```  
client method:
```java
void op1(String p1, String p2);
```

### case2: single flatten body param
```ts
op op1(a: A);
```

TCGC return:
```ts
Op1Request: {
    access: internal
    usage: spread
}

A: {
    access: public
    usage: input
}
```

code-model expected return:
```ts
A: {
    usage: ["public", "input"]
}

Op1Request: {
    usage: ["internal", "input"]
}
```

client method:
```java
void op1(A a);
```


### case3: spread body + flatten body
```ts
op op1(s: string, ...A);
```

TCGC return:
```ts
Op1Request: {
    access: internal
    usage: spread
}
```

code-model expected return:
```ts
Op1Request: {
    usage: ["internal", "input"]
}
```

client method:
```java
void op1(String, s, String p1, String p2);
```

### case4: multiple flatten body param
```ts
op op1(s: string, a: A);
```

TCGC return:
```ts
Op1Request: {
    access: internal
    usage: spread
}

A: {
    access: public
    usage: input
}
```

code-model expected return:
```ts
Op1Request: {
    usage: ["internal", "input"]
}

A: {
    access: public
    usage: input
}
```
client method:
```java
void op1(String s, A a);
```

### case5: single spread body param + parameter
```ts
op op1(@path id: string, ...A);
```
TCGC return:
```ts
A: {
  access: internal
  usage: spread
}
```

code-model expected return:
```ts
A: {
    usage: ["internal", "input"]
}
```

client method:
```java
op1(String id, String p1, String p2);
```

### case6: single flatten body + parameter
```ts
op op1(@path id: string, a: A);
```
TCGC return:
```ts
Op1Request: {
  access: internal
  usage: spread
}

A: {
    access: public
    usage: input
}
```

code-model expected return:
```ts
Op1Request: {
    usage: ["internal", "input"]
}

A: {
    usage: ["public", "input"]
}
```

client method:
```java
void op1(String id, A a);
```


### Case7: flatten body + json-merge-patch
```ts
op op1(
    @header contentType: "application/merge-patch+json",
    patch: APatch);
```

TCGC return:
```ts
Op1Request: {
    access: internal
    usage: spread
}

APatch: {
    access: public
    usage: [input, json-merge-patch]
}
```

code-model expected return:
```
Op1PatchRequest: {
    access: public
    usage: input
}

APatch: {
    access: public
    usage: input
}
```

client method:
```java
void op1(Op1PatchRequest patch);
```

### Case8: flatten body + multipart
```ts
op op1(
    @header contentType: "multipart/form-data",
    body: bytes);
```

TCGC return:
```ts
Op1Request: {
    access: internal
    usage: [spread, multipart-form-data]
}

```

code-model expected return:
```
BodyFileDetails: {
    access: public
    usage: input
}

Op1Request: {
    access: internal
    usage: input
}
```

client method:
```java
void op1(BodyFileDetails body);
```

### Case9: combination of spread body op and flattened body op
```ts
op op1(...A);
op op2(a: A);
```

TCGC return:
```ts
A: {
  access: public
  usage: [input, spread]
}

Op2Request: {
   access: internal
   usage: spread
}
```

code-model expected return:
```ts
A: {
    usage: ["public", "input"]
}

Op2Request: {
   usage: ["internal", "internal"]
}
```

client method:
```java
void op1(String p1, String p2);
void op2(A a);
```

## Adopting TCGC model usage and access solution

We could treat TCGC returned `spread` usage on model type as `input`, but there remains two issues:

1. case 7: flatten body + json-merge-patch, we don't know the access for `Op1PatchRequest` from operation.
2. case 8: flatten body + multipart, as we create our own multipart model `BodyFileDetails`, and tcgc returns `bytes` type for the body param, we can't know what is the access.

