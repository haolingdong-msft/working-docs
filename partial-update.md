# Partial Update in Azure Java Data-plane Codegen

## Background

Data-plane codegen has the benifit of stable API, quickly shippable package etc. But it has one drawback that the usage of the API could be difficult because the generated code is low-level. You need to generate your request body as `BinaryData` (e.g. using `BinaryData.fromString(<jsonString>)`) to call API. Thus there will be needs to add customized manual code on top of low level client layer, e.g. adding additional API for better usage. Now we already released services like WebPubSub which already contains lots of manual updated code, we don't want the generated code to overwrite the existing manual code. That's why we need to support partial update.

## Usage

### partial-update Flag

If you want to use partial update feature, you will need to add flag `--partial-update` to enable it. The flag can be added in swagger/README.md, like this:
```yaml
input-file: ./specification/bodystring.json
java: true
output-folder: ../
namespace: fixtures.bodystring
low-level-client: true
partial-update: true
```

Currently partial update functionality is only supported in `Client` and `Builder`.

### Detect Manual Source File Path

We first detect your `swagger/README.md`, then get its parent `swagger` folder, then get its parent - project base directory. Then get source folder `src/main/java` and files from project base directory. This is a sample code structure: https://github.com/Azure/autorest.java/tree/main/partial-update-tests/existing


### Detect Manual Code

If a member in the class has `@Generated` annotation, then we consider it as auto-generated code, otherwise, we consider it as manual code. 

When adding/updating code manually, you need to **remove** `@Generated` annotation from the member, because this is how we detect the code is manually updated and will not overwrite your update after finishing codegen. 

## Use Cases

Below partial update use cases are supported.

### Manually add class member (field / method / constructor)

We supported manually add class members, like field, method and constructor. We will keep the added member after codegen. Below are examples demonstrating how you add an additional field or method or constructor.

* manually added field: 

	This is an example file of manually adding field: 
	https://github.com/Azure/autorest.java/blob/main/partial-update-tests/existing/src/main/java/fixtures/bodystring/StringOperationClient.java#L23-L24

	After codegen, the output is like this: 
	https://github.com/Azure/autorest.java/blob/main/partial-update-tests/generated/src/main/java/fixtures/bodystring/StringOperationClient.java#L23-L24

* manually added constructor:
	This is an example of manually adding constructor:
	https://github.com/Azure/autorest.java/blob/main/partial-update-tests/existing/src/main/java/fixtures/bodystring/StringOperationClient.java#L36-L39

	After codegen, the output is like this: 
	https://github.com/Azure/autorest.java/blob/main/partial-update-tests/generated/src/main/java/fixtures/bodystring/StringOperationClient.java#L36-L39

* manually added member method: 
	This is an example of manually adding member method:
	https://github.com/Azure/autorest.java/blob/main/partial-update-tests/existing/src/main/java/fixtures/bodystring/StringOperationClient.java#L275-L282

	After codegen, the output is like this: 
	https://github.com/Azure/autorest.java/blob/main/partial-update-tests/generated/src/main/java/fixtures/bodystring/StringOperationClient.java#L275-L282

### Manually update method signature, e.g. parameter change, method access level change

We supported manually update method, including update method signature, like parameter type/name change, method access level change, as well as update method body. Please do remember to **remove** `@Generated` annotation when you do the update. We will keep your manual code change and not generate the corresponding method with the same method name as your updated function.

This is an example of manually updated method, here we change the method access level from `public` to `package-private`:
https://github.com/Azure/autorest.java/blob/main/partial-update-tests/existing/src/main/java/fixtures/bodystring/StringOperationClient.java#L80-L98

After codegen, you will see method `getEmptyWithResponse` access level is still `package-private`, and there no generated method called `getEmptyWithResponse` with `public` access level.
https://github.com/Azure/autorest.java/blob/main/partial-update-tests/generated/src/main/java/fixtures/bodystring/StringOperationClient.java#L80-L98

### Manually remove one class member

If you manually removed one class member, if the member's definition is in Swagger specification, this member will be auto generated again, so if you want to remove a class member, the correct way to do it is to modify swagger directly. 

### Add a new api in Swagger

If Swagger specification adds a new API, after codegen, the generated method will be added to the generated class.

This is an example of adding a new API to Swagger specification. We added an API called `getStringAdded`.
https://github.com/Azure/autorest.java/blob/main/partial-update-tests/existing/swagger/specification/bodystring_updated.json#L430

After codegen, the output is like this, method `getStringAdded` is generated.
https://github.com/Azure/autorest.java/blob/main/partial-update-tests/generated/src/main/java/fixtures/bodystring/EnumClient.java


### Update an existing API in Swagger
 
We also support updating an existing API in Swagger speficication. If the API is auto generated, then the existing generated member will be replaced to the new one. If it is manual updated, we will keep the manual updated member.

This is an example of updating a new API in Swagger specification. Here we modify the parameter name from `stringBody` to `stringBodyUpdated`.
https://github.com/Azure/autorest.java/blob/main/partial-update-tests/existing/swagger/specification/bodystring_updated.json#L299

After codegen, the output is like this:
https://github.com/Azure/autorest.java/blob/main/partial-update-tests/generated/src/main/java/fixtures/bodystring/EnumClient.java

### Delete an existing API in Swagger
	
When deleting an existing API in Swagger. If the existing api is auto generated, then it should be removed. If it is manual updated, we will keep the manual updated member.

Foe example, below API from bodystring.json is removed and we did not do manual code change on this method:
https://github.com/Azure/autorest.java/blob/main/partial-update-tests/existing/swagger/specification/bodystring.json#L382-L406

After codegen, the output is like this, you will see the method is removed from generated file.
https://github.com/Azure/autorest.java/blob/main/partial-update-tests/generated/src/main/java/fixtures/bodystring/EnumClient.java

## Design

### Alternatives

For Java, we have existing feature called [customizations](https://github.com/Azure/autorest.java#customizations). It supports various types of customizations, like add annotation to methods, modify return type and return statement, update method access level etc. However, it has limitations. It does not support adding custom code, e.g. changing the body of a method, adding a method. But it is a common usage to add a wrapper on fundamental methods to provide high-level user experience. For this kind of use cases, `customizations` can't support and we look for supporting partial update. 

### Code Change

Partial update is supported for .java files with `@Generated` annotation, currently they are async and sync `Client`, as well as `Builder` . We already supported add `@Generated` annotation to members in async and sync clients, as well as builders in these prs: https://github.com/Azure/autorest.java/pull/1239, https://github.com/Azure/autorest.java/pull/1292.

The code change is mainly in Postprocessor.java and PartialUpdateHandler.java. It will handle partial update for each .java file after finishing customization. When handling partial update for each file, it will compare **existing file** which has manual update and **generated file** which is generated by autorest. We will keep existing file's format as much as possible.

Detailed logic:
1. Parse existing file content and generated file content using [JavaParser](https://javaparser.org/)
2. Get class members for existing file and generated file
3. Check if the file is in scope of partial update by iterate the members in generated file to see if there is a method has `@Generated` annotation. If it has `@Generated` annotation, then the file is in scope of partial update, otherwise return generated file content directly.
4. Iterate existing file members, keep manual updated members, and replace generated members with the corresponding newly generated one. Here we will not do the replace on the existing file member list,  we just create a new member list `updatedMembersList` and put in those manually update members and newly generated members.
5. Add remaining newly generated members to `updatedMembersList`
6. Update generated file members with `updatedMembersList`
7. Update generated file imports


### Unit Test

Unit test is in [PartialUpdateHandlerTest.java](https://github.com/Azure/autorest.java/blob/main/postprocessor/src/test/java/com/azure/autorest/postprocessor/util/PartialUpdateHandlerTest.java). 

It tests below cases:

1. Existing file manually add class member (field / method / constructor)
2. Existing file manually update method signature - parameter change and access level change
3. Existing file manually remove method
4. Generated file add API
5. Generated file remove API
6. Generated file update API
7. Generated file update API and the method is also manually updated in existing file -> keep manual update one
8. Generated file remove API and the method is also manually updated in existing file -> keep manual update one

### Integration Test

Integration tests are also added to test the overall process for partial update in [partial-update-tests](https://github.com/Azure/autorest.java/tree/main/partial-update-tests). The test will generate code based on existing folder and [bodystring_updated.json](https://github.com/Azure/autorest.java/blob/main/partial-update-tests/existing/swagger/specification/bodystring_updated.json). The existing files are in `existing` folder and the generated files are in `generated` folder. `StringOperationClient.java` covers manually code change on existing file, `EnumClient.java` covers swagger change.

It tests below cases:
1. Manually add class member (field / method / constructor)
2. Manually update method signature - parameter change
3. Manually update method signature -  method accessibility level change
4. Swagger update api - method parameter name change 
5. Swagger add new api
6. Swagger remove api

## References
* Feature issue: https://github.com/Azure/autorest.java/issues/1050
* PR: https://github.com/Azure/autorest.java/pull/1273
