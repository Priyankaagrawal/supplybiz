# supplybiz_api_client.api.ConfigurationApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**appConfigControllerRead**](ConfigurationApi.md#appconfigcontrollerread) | **GET** /api/v1/config | Get public mobile minimum version and simple flags


# **appConfigControllerRead**
> AppConfigResponse appConfigControllerRead()

Get public mobile minimum version and simple flags

### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getConfigurationApi();

try {
    final response = api.appConfigControllerRead();
    print(response);
} on DioException catch (e) {
    print('Exception when calling ConfigurationApi->appConfigControllerRead: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AppConfigResponse**](AppConfigResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

