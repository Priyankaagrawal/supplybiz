# supplybiz_api_client.api.HealthApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthControllerGetLive**](HealthApi.md#healthcontrollergetlive) | **GET** /api/v1/health/live | Liveness probe
[**healthControllerGetReady**](HealthApi.md#healthcontrollergetready) | **GET** /api/v1/health/ready | Readiness probe


# **healthControllerGetLive**
> HealthControllerGetLive200Response healthControllerGetLive()

Liveness probe

### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getHealthApi();

try {
    final response = api.healthControllerGetLive();
    print(response);
} on DioException catch (e) {
    print('Exception when calling HealthApi->healthControllerGetLive: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthControllerGetLive200Response**](HealthControllerGetLive200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **healthControllerGetReady**
> Map<String, Object> healthControllerGetReady()

Readiness probe

### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getHealthApi();

try {
    final response = api.healthControllerGetReady();
    print(response);
} on DioException catch (e) {
    print('Exception when calling HealthApi->healthControllerGetReady: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map&lt;String, Object&gt;**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

