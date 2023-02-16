## ADP cadl definition example

Here I listed two examples, one is a normal operation defined by ADP, another is a LRO operation defined by ADP.
1. a general operation (non-LRO)

This example is a normal operation in ADP. Live demo can be found [here](https://cadlplayground.z22.web.core.windows.net/cadl-azure/?c=aW1wb3J0ICJAY2FkbC1sYW5nL3Jlc3QiOwrJGmF6dXJlLXRvb2xzL8UmxhFjb3JlzCfKQW9wZW5hcGkiOwoKdXNpbmcgQ2FkbC5IdHRwO8wRUmVzdMgRQcRTLkNvcmXSEi5Gb3VuZGF0aW9uczsKCgoKICBpbnRlcmZhY2UgRGlzY292ZXJpZXMgewogICAgI3N1cHByZXNz%2FgC7L3VzZS1zdGFuZGFyZC1vcGVyxmIiICJBRFAgZGF0YS1wbGFuZSBBUEkgdXNlcyBjdXN0b20gySwuIsVxQGRvYygiQ3JlYXRlcyBhIG5ldyBpbmdlc8QkIGTnAKF5IGluxG9jZS4iKcU4Y8UyT3JSZXBs5ADLaXMgQ8ViUmVzb3VyY2XGU8khPMU2IOkA83ksxxHGNkJvZHlXcmFwcGVyPMkjxUNpb25QYXJhbWV0ZXJzPsU1PjsKICB95AFL5gC%2BQesAqHLHf%2BYAqEDIDygiyCNpZXPGG2ZyaWVuZGx5TmFtZSgiyXXFHW1vZGVs6gCs5wGdQGtlecUJaWQ6IHN0cmluZzvkAIboAIhJRCBvZiB0aGUgZXh0ZXJuYWwgcGFja2FnZSAoZm9yIGV4YW1wbGUsxSNkaXNrIHdoaWNoIGNvbnRhaW5lZOUBuSnHFndhc%2BQBumQgdXBvbsUz5QF05AGXb2YgdXBsb2Fk5wGNQHZpc2liaWxpdHkoInJlYWQiLCAixS5lxyLoAJFQ5gCQSWQ%2F8ADCZm9ybWF0KCJ1cmnIVuUA1SLmAihTQVMgc2ln5AClVVJJIOQAz%2BYAg%2BQC729yIMR2xAvnANvnAThtYW5pZmVzdCBmaWxlIG9u5gMZIFN0b3JhZ2UuxVpOb3RlLCBp5gE5yjtzdGF0dXPkAlgn5gJLZCfEIuYBCuQAg2lz6ACRd2l0aCAnV3JpdGUnIHBlcm1pc3PkAw4sIG90aGVyd2lzZcckUmVhZMwj5gCCVGhpc8VTZXhwaXJlcyBpbiAyNCBob3Vyc8YiIiL5AWrGGOgA6VXlARRVcmnuAWDrAq3qAlXoApzqAdhw6QLp5wK%2F9wKk8gMZxi%2FkAOVW6wCh6wIDxRxvdXRPbWl0dGVkUHLkBAl0aWVz6gMaeUnmAM7vAv3SbecDDy4uLskl5wOS6gDnSeQE5eQDAi3lAbHGVOQCNuUE%2FsQZdXPnAJr3AOVJZGVudGlmaWVy9ACWyh7oA53Fd1TtAkRpySXoBLfpA8NAbWluTGVuZ3RoKDHHG21heMcSMzbGE8lKSesD8ecA6QogIG9w%2FwT0xUVU5gTqVM4l5QFOcwogID7yBTtP6AWkzUHda03kAR48VD4gJtZp2kNkT3JPa1Jlc3BvbnNlPFTkBWI%2B5QK0%2FwaLxBHoAsItbWFuYWdlci9ub8QUxUstYm9keSIgIuUDXekGdiBtdXN0IHJldHVybiBh6APlbW9uaXTlAhwgaXRz5AMZxUPlBqNAYXV0b1JvdXRl9AFy6gEr6QD3LCBU5wD05QELxUrlAWXKLOUBDesHmS5JdGVtS2V5c09mykjlAUzsAT7JTucBI%2BQAnW9taXRLZXnqA0%2FpAqr%2FAa%2FlAa%2FJa8Vg5ASFcGRhdGVhYmxlylI8RGVmYXVsxGfqA9zKPCwg5gSIPucAk9p%2BZOsB5uoDw%2BkI3%2BQI08YfMjAx5QdjICBA5AHFIMQFOiBU6AL7ICBhbGlh9gfw8AJOID3WJ8wjfM8jzUHlAovoB%2Bd35ggi5QRIb3DkAbvlB2PnBJjkAj%2FkBGzkAK8uIOQECuQEbG505Acv5gEWaXMgdG8gYWRkIGRlc2NyacVDxBMnxDQn6wRo8giW6QE05QEUxQrECT%2FqARn2AXzuAQ%2FEQ%2FgBdTDlAXXvAXPmBGwK)

```typescript
import "@cadl-lang/rest";
import "@azure-tools/cadl-azure-core";
import "@cadl-lang/openapi";

using Cadl.Http;
using Cadl.Rest;
using Azure.Core;
using Azure.Core.Foundations;


// ADP operation definition
interface Discoveries {
  #suppress "@azure-tools/cadl-azure-core/use-standard-operations" "ADP data-plane API uses custom operation."
  @doc("Creates a new ingestion discovery instance.")
  createOrReplace is CustomResourceCreateOrReplace<
    Discovery,
    CustomBodyWrapper<DiscoveryCreationParameters>
  >;
}

// ADP Discovery related models
@doc("A discovery resource.")
@resource("discoveries")
@friendlyName("Discovery")
model Discovery {
  @key
  id: string;

  @doc("ID of the external package (for example, the disk which contained data) which was used upon the creation of upload")
  @visibility("read", "create")
  externalPackageId?: string;

  @format("uri")
  @doc("""
  SAS signed URI for uploading or reading the discovery manifest file on Azure Storage.
  Note, if the discovery status is 'Created' then the URI is signed with 'Write' permissions, otherwise with 'Read' permission.
  This URI expires in 24 hours.
  """)
  @visibility("read")
  manifestUploadUri?: string;

}

@doc("Discovery resource creation parameters.")
@friendlyName("DiscoveryCreationParameters")
@withVisibility("create")
@withoutOmittedProperties("discoveryId")
model DiscoveryCreationParameters {
  ...Discovery;
}

// ADP common operations
op CustomResourceCreateOrReplace<
  T,
  TResourceCreateParams
> is CustomResourceOperation<
  T,
  CustomResourceCreateOrReplaceModel<T> & TResourceCreateParams,
  CustomResourceCreatedOrOkResponse<T>
>;

#suppress "@azure-tools/cadl-azure-resource-manager/no-response-body" "This operation must return a status monitor in its response."
@autoRoute
op CustomResourceOperation<TResource, TParams, TResponse> is Operation<
  Foundations.ItemKeysOf<TResource> & TParams,
  TResponse
>;


// ADP common models
@omitKeyProperties
model CustomResourceCreateOrReplaceModel<TResource>
  is UpdateableProperties<DefaultKeyVisibility<TResource, "read">>;


model CustomResourceCreatedResponse<T> {
  ...Cadl.Http.Response<201>;
  @body body: T;
}


alias CustomResourceCreatedOrOkResponse<T> = CustomResourceCreatedResponse<T> | CustomResourceOkResponse<T>;

@doc("A wrapper for optional parameter in the body. The intent of model is to add description to 'body'")
model CustomBodyWrapper<T> {
  @body
  body?: T;
}

model CustomResourceOkResponse<T> {
  ...Cadl.Http.Response<200>;
  @body body: T;
}

```

2. Long running operation
This is a LRO definition in ADP. Live demo can be found [here](https://cadlplayground.z22.web.core.windows.net/cadl-azure/?c=aW1wb3J0ICJAY2FkbC1sYW5nL3Jlc3QiOwrJGmF6dXJlLXRvb2xzL8UmxhFjb3JlzCfKQW9wZW5hcGneRHV0b8dpCnVzaW5nIENhZGwuSHR0cDvMEVJlc3TIEUHERS5Db3Jl0hIuRm91bmRhdGlvbnPIHk9wZW5BUEnJLcdzOwoKaW50ZXJmYWNlIERpc2NvdmVyaWVzIHsKCiAgI3N1cHByZXNz%2FgD6L3VzZS1zdGFuZGFyZC1vcGVyxnwiICJBRFAgZGF0YS1wbGFuZSBBUEkgdXNlcyBjdXN0b20gTFJPIHJlc3BvbnNlIHRlbXBsYXRlIHRoZcUaYWPFRy4iCiAgQGRvYygiSW5pdGlhdGVzxSRwcm9j5ACdb2YgY29tcGxldOQA28QaZOcAynkgYW5kIGNyZWHJG3VwbG9hZCBmaWxlIGdyb3VwxBltYW5pZmVzdMUXcy4iKcRyZXh0ZW5zaW9uKCJ4LW1zLWxvbmctcnVubmluZ%2BoA5iIsIHRydWXFMmFzeW5jT8gaT3DEBnMoImxvY8YrxSVwb2xsaW5nyScoTG9uZ1LGV8kVcy5nZXRTdGF0dXPENecA32UgaXMgQ%2BUBO8s1UmVzb3VyY2VB5QEvPAogICDpAct5LMUPe33OCMkfTHJvUucBgAogID47Cn0KCuYBa0HrAUVyx2LkARlAyA0oIsghaWVzxBlmcmllbmRseU5hbWUoIsljIikKbW9kZWzKdSB75QCFICBAa2V5xQtpZDogc3RyaW5nO%2BQCeOcB7UTkAdrkAbTkAYpybmFsIHBhY2thZ2UgKGZvciBleGHkARYs6AHyayB3aGljaCBjb250YWluZWTlAnopxxZ3YXPkAntkIHVwb27FM%2BYCF29uxGbmAhbmAaF2aXNpYmlsaXR5KCJyZWFkIiwgIsUsZcUg6ACNUOYAjElkP%2B4AvGZvcm1hdCgidXJpxlDlAM0i5ALFU0FTIHNpZ%2BQAm1VSSSDkAMXGeeQChG9yIMRu8gLD7QKdIG9u5gPqIFN0b3JhZ2UuCiAgTm90ZSwgaeYBLco5c%2BUCQOQCNCdD5QDAZCfEIuYA%2FuQAgWlz6ACPd2l0aCAnV3JpdGUnIHBlcm1pc%2BQC%2BnMsIG90aGVyd2lzZcckUmVhZMwj5ACAVGhpc8VRZXhwaXJlcyBpbiAyNCBob3Vyc8QgIiL3AVrEFugA31XlAQpVcmnsAVDpAo%2FkBBBvZuoCROkDKlR5cGUgdHlw5AGd7wJo7gLdaXMg9ANqyCI81ls%2BO%2BgAgktub3du6wFe6QQCxX7lBDVAa8QkVmFsdWVzKNZQS1bxAKfNIOUBlOgA%2FsZ5VGhlIOQFiW9ydGVk6AUV5AII6QCMIikKZW51bddTS1blA3HKTf8FOMdSICBDxh1lyVc6ICLRFCIs6gOyz11maW5hbGl6yF3lAr9saXN06APXzm5Gxi5lRmlsZUxpc3Q6ICLQE9tsY2FuY2XlBVnTW0Fib3J07ADGzhEiLOQCaC8vLc4BCi8vIGFkcOQBJG1vbiDlAbZz5wGURGVmYXVsdCBlcnLlA7jnBsPlAyPnBtxoZWFkZXLlAhfuBRrmBcFFxDroAn1XaXRoWE1zxRRDb2RlSMU86QLS2DJt0DLkAj7rB%2F0uzTPlAgYuLi7SaesF98UaIGNvZGXrAMHmAIbSOOsCWMs45ATXc3BlY2lmaWPnASF0aGF0IG9jY3VycmVk5wdfxl%2FkBB7lB17FKS3EQSLqBAB9CgruAQN0YWdQcuQDenTmBkb1Ba11cGToBa3qAixlbnRpdHkgdGFn5QChdOQEs%2BwG2CAgZXRhZ817xj1BIHdyYXBwZXLFOG%2FlB9XlBotyYW1ldOQBdOYFUWJvZHkuIMRr5AlSbuUC5uYAvGlzIHRvIGFkZCBkZXNjcmnFQ8QTJ8Q0J%2B8B50JvZHlXxnI8VD7mAObEKAogxWM%2FOiBU5QCezDToCANPa%2BkEz8c7Li4u6QpN5ApBxh0yMDA%2BO8hZxVfIVuQC9S0tLecJmuQJj%2BQAtmZp5Al5b25zCkDmBIAKQOQKtVJvdXRlCkBzZWdtZW50U2XkARR0b3IoIjrkAvbkAT7kAd9SdW5zIGHoAxfGQOQEv3tuYW1lfSBhcyDsCVrrBVgoTFJPKSLkCLJU6ADhCikKb3D%2FCQPlCQPJMuUHsG5kcyBvYmplY3THTnF1ZXN0UOgBw3PmB9bKJiA95wkrVMZryR%2FsA13GG2l6xQ9GaWVsZHPKOExST%2BkDeM5cPSDnBD3sBp8%2B5AEqLi7sC7ouSXRlbUtleXNPZjzpAM4%2BxF0uLi7yAMPHGcxB5gChyiM85wDOyEXMLEFwaVZlcuQH0ckwxyb0BzVJZOYEAQopOiAoQWNjZXB0ZWTpAl7zAsjrAQ8%2BPiAmCiD1B4zmCvFM5wsvxSfyANDISOYBcukA1CkgfPsDDcgUPskm7QUb6QdsxRbvBdAn7wSgJ%2F8F285b%2FAXF%2FwWv%2FgWvdGFnKCLkAUYg5wFH5A3k5wyUKesN1vUMX%2BsFukdldOYHM2V0YWls5QdNYW7kBADmBRbpDIjkAK3oAUfkCgU81FnkBpfoAMHmAK1z5gxV5wFgIiIKQ2xp5AUe6QYi5AP9IPID%2FWlk5AWyZmllci4K5QpgyhEgd2lsbCBzZXJ2ZeQEPmlkZW1wb3RlbmNlIGtleeQFWWVuc%2BQLI8kac3noCHTWbi4K5Qqj5gGp%2FALx7wlK1k7sALzqAZUtSWQgc2hvdWxkIGJlIHZhbGlkIFVVSUTnBnLnBxbpDD51aecMj%2BoHKMlhLWlkIusLJuQCDu8NffEEYuoLHtEb6AJp%2FAse6wcQ%2BwD46AM48gMZ3Fz9AXnIJTxU7gsnPecA%2FucHIekAmuoAjUnoCGltaW5MZW5ndGgoMcYQYXjHEDM2xBHJM0nrDob5ARLkAuJvdXRLZXnvAJPsDz1NZXRh5A595Qgz9wEt5w2ebW9uaXTFJuYE9uQPS%2FoBD%2B8FIuUA%2FOcQUcgV7wKhxyrkAInHa%2BgLJO4Ai%2BcJBecCbygiyXMtyFnFIMk1yBY66QQVyBL1BBnsAR77AkLmAPrkBXdvdeYEl2tleeoKg%2F8Bkf8CJPICJOYBhMRgIMcMOtVk5gF36xCczkfkDgHGRckU5ACB5AmryUPEEdlB5QZdxkLFCz869xPP5gYj7wFM5RJ38QDW8A6Q%2BgDY5A6U%2FwOwyi3%2FAp%2FoBirpDsTlDpncfOUBnecQoOQIc0luUHJvZ%2BQUdsQOU3VjY2VlZMYbRmFpbMYKQ%2BUN78QM5AZc5wEMU%2BcUg%2BcRIe0UXeYC1%2BUB6%2F4CS%2B8GvvwFHecEJuwBn1JldHJ5QWZ0ZXLGQPsESVJlc%2BQFiOcDNesB0%2BUO9uoDuucGue0FZnVsdP4Ays5d6wMA313LXeQGjcQtyEXsBB3tBBPITT86IHVyaewH7kH7Bin0FFHJIf4CZuYAz2tlecsySecHLukDFXVuaXF1ZSDqFEXJK%2F8GF%2F8GF%2FcBzkJh5wcl%2FwTk%2FwTk9wDyxF74BN4sIFTmA0vmCrw9%2FQQ6%2FwUL6Bb7%2Fw9W%2FwUr%2FwUr6AZq%2FxVo%2FwVL2GHrBUvNYusAv%2BgFY%2BwBONlQ5QME5wMX5BTkLiBX5Ap%2BYmUgcmV0dXLkFT3nFXnKNHPmBLVzIHZpYSBg6AMtYOcEheQQMegEmP8BC%2BcAscZ%2B5hUb5QNj5w%2FZ8REU5QKC5w%2FC9QIH5wJk8Q2zVOUOuj7lGGDpEC%2FQJugFDOQQKg%3D%3D)
```typescript

import "@cadl-lang/rest";
import "@azure-tools/cadl-azure-core";
import "@cadl-lang/openapi";
import "@azure-tools/cadl-autorest";

using Cadl.Http;
using Cadl.Rest;
using Azure.Core;
using Azure.Core.Foundations;
using OpenAPI;
using Autorest;


// ADP operation definition
interface Discoveries {

  #suppress "@azure-tools/cadl-azure-core/use-standard-operations" "ADP data-plane API uses custom LRO response template the LRO actions."
  @doc("Initiates the process of completing the discovery and creating the upload file grouping manifest files.")
  @extension("x-ms-long-running-operation", true)
  @asyncOperationOptions("location")
  @pollingOperation(LongRunningOperations.getStatus)
  complete is CustomLongRunningResourceAction<
    Discovery,
    {},
    {},
    DiscoveryLroResponse
  >;
}


// ADP Discovery related models
@doc("A discovery resource.")
@resource("discoveries")
@friendlyName("Discovery")
model Discovery {
      @key
    id: string;

  @doc("ID of the external package (for example, the disk which contained data) which was used upon the creation of upload")
  @visibility("read", "create")
  externalPackageId?: string;

  @format("uri")
  @doc("""
  SAS signed URI for uploading or reading the discovery manifest file on Azure Storage.
  Note, if the discovery status is 'Created' then the URI is signed with 'Write' permissions, otherwise with 'Read' permission.
  This URI expires in 24 hours.
  """)
  @visibility("read")
  manifestUploadUri?: string;

}

@doc("LRO of DiscoveryOperationType type")
model DiscoveryLroResponse
  is LongRunningOperationResponse<DiscoveryOperationType>;

@doc("Known discovery operation types.")
@knownValues(DiscoveryOperationTypeKV)
model DiscoveryOperationType is string;

@doc("The supported actions on discovery")
enum DiscoveryOperationTypeKV {
  @doc("The process of completing the discovery")
  CompleteDiscovery: "CompleteDiscovery",

  @doc("The process of finalizing the file list of the discovery")
  FinalizeFileList: "FinalizeFileList",

  @doc("The process of cancelling the discovery")
  AbortDiscovery: "AbortDiscovery",
}


// ADP common models
@doc("Default error response with custom header.")
@friendlyName("CustomErrorResponseWithXMsErrorCodeHeader")
model CustomErrorResponseWithXmsErrorCodeHeader is Foundations.ErrorResponse {
  ...XMsErrorCodeHeader;
}

@doc("Error code header.")
model XMsErrorCodeHeader {
  @doc("Error code for specific error that occurred.")
  @header
  "x-ms-error-code": string;
}


model CustomEtagProperty {
  @visibility("read", "update")
  @doc("The entity tag for this resource.")
  etag: string;
}

@doc("A wrapper for optional parameter in the body. The intent of model is to add description to 'body'")
model CustomBodyWrapper<T> {
  @body
  body?: T;
}

model CustomResourceOkResponse<T> {
  ...Cadl.Http.Response<200>;
  @body body: T;
}


// ADP LRO related definitions
@action
@autoRoute
@segmentSeparator(":")
@doc(
  "Runs a custom action on {name} as long-running operation (LRO)",
  TResource
)
op CustomLongRunningResourceAction<
  TResource extends object,
  TRequestParameters  extends object = {},
  TCustom extends Foundations.CustomizationFields = {},
  TLROResponse extends object= DefaultLroResponse
>(
  ...Foundations.ItemKeysOf<TResource>,
  ...TRequestParameters,
  ...Foundations.CustomParameters<TCustom>,
  ...Foundations.ApiVersionParameter,
  ...LongRunningOperationIdHeader
): (AcceptedResponse<CustomBodyWrapper<TLROResponse>> &
  LongRunningOperationStatusLocation &
  Foundations.CustomResponseFields<TCustom>) | CustomResourceOkResponse<TResource> | CustomErrorResponse;

@doc("Error response with 'x-ms-error-code' header.")
@friendlyName("CustomErrorResponse")
model CustomErrorResponse is Foundations.ErrorResponse {
  ...XMsErrorCodeHeader;
}

@tag("Long Running Operation")
interface LongRunningOperations {
  @doc("Get the details of an LRO.")
  getStatus is ResourceRead<LongRunningOperationWithResponseHeaders>;
}


@doc("""
Client specific long running operation identifier.
This identifier will serve as idempotence key to ensure idempotensy of the long running operation.
""")
model LongRunningOperationIdHeader {
  @doc("The long running operation identifier. Operation-Id should be valid UUID string.")
  @format("uuid")
  @header
  "operation-id"?: string;
}

@friendlyName("DefaultLroResponse")
model DefaultLroResponse {
  ...LongRunningOperationResponse;
}

@doc("The long running operation response")
@friendlyName("LongRunningOperationResponse")
model LongRunningOperationResponse<TOperationType = string> {
  @doc("The operation Id.")
  @minLength(1)
  @maxLength(36)
  operationId: string;
  ...LongRunningOperationWithoutKey<TOperationType>;
}

@doc("Metadata for long running operation status monitor locations")
model LongRunningOperationStatusLocation {
  @pollingLocation
  @doc("The location for monitoring the operation state.")
  @header("Operation-Location")
  operationLocation: ResourceLocation<LongRunningOperation>;
}

@doc("The long running operation model without the key.")
model LongRunningOperationWithoutKey<TOperationType = string> {
  @doc("The operation status.")
  status: LongRunningOperationStatus;

  @doc("The operation type.")
  operationType?: TOperationType;

  @doc("The operation error.")
  error?: Azure.Core.Foundations.Error;
}

@doc("The async operation status")
@knownValues(LongRunningOperationStatusKV)
@friendlyName("LongRunningOperationStatus")
model LongRunningOperationStatus is string;

enum LongRunningOperationStatusKV {
  Created,
  InProgress,
  Succeeded,
  Failed,
  Canceled,
}


@doc("Standard Azure LRO response headers.")
model LongRunningOperationWithResponseHeaders {
  ...LongRunningOperation;
  ...Foundations.RetryAfterHeader;
  ...LongRunningOperationResultLocation;
}

@doc("Final location of the operation result.")
model LongRunningOperationResultLocation {
  @doc("Final location of the operation result.")
  @finalLocation
  @header("Location")
  location?: uri;
}


@doc("A long running operation resource.")
@resource("operations")
model LongRunningOperation {
  @key("operationId")
  @doc("The unique ID of the operation.")
  @minLength(1)
  @maxLength(36)
  operationId: string;
  ...LongRunningOperationBase;
}


@doc("The long running operation model without the key.")
model LongRunningOperationBase<TOperationType = string, TStatusError = Azure.Core.Foundations.Error> {
  @doc("The operation status.")
  @visibility("read", "update")
  status: LongRunningOperationStatus;

  @doc("The operation type.")
  @visibility("read", "create")
  operationType?: TOperationType;

  @doc("The operation error.")
  @visibility("update")
  error?: TStatusError;

  @doc("The operation final result URI. Will be returned if the operation succeeds via `Location` header in response.")
  @visibility("read", "create")
  resultUri?: uri;

  ...CustomEtagProperty;
}

// Azure.Core.Foundation
model AcceptedResponse<T = {}> is Cadl.Http.AcceptedResponse {
  ...T;
}

```

## Issues met during codegen

- They have very complex definitions like Paging LRO, we can't support it yet.

- Multiple methods have the same name and signature. They should be seperated into different clients, otherwise one client contains methods with the same signature, this will definitelly cause compliation error.

- For ADP, since there is lots of operations and models, [API view](https://apiview.dev/Assemblies/Review/3b77bee6b3b940ad9c85df75cee51df1) is large and can be hard to review.