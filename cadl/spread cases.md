## Spread/Flattened body Cases

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

### case1:
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

### case2:
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


### case3:
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

### case4:
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

### case5:
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

### case6:
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


### Case7:
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

### Case8:
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

### Case9: combination of spread and flattened method signature
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
