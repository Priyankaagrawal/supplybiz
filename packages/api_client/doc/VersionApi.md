# supplybiz_api_client.api.VersionApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**versionControllerGetVersion**](VersionApi.md#versioncontrollergetversion) | **GET** /api/v1/version | Get build metadata


# **versionControllerGetVersion**
> VersionControllerGetVersion200Response versionControllerGetVersion()

Get build metadata

### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVersionApi();

try {
    final response = api.versionControllerGetVersion();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VersionApi->versionControllerGetVersion: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**VersionControllerGetVersion200Response**](VersionControllerGetVersion200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

