# supplybiz_api_client.api.ProfileApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**profileControllerGet**](ProfileApi.md#profilecontrollerget) | **GET** /api/v1/me/profile |
[**profileControllerSave**](ProfileApi.md#profilecontrollersave) | **PUT** /api/v1/me/profile |


# **profileControllerGet**
> ProfileResponse profileControllerGet()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getProfileApi();

try {
    final response = api.profileControllerGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProfileApi->profileControllerGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ProfileResponse**](ProfileResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **profileControllerSave**
> ProfileResponse profileControllerSave(idempotencyKey, profileInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getProfileApi();
final String idempotencyKey = idempotencyKey_example; // String |
final ProfileInput profileInput = ; // ProfileInput |

try {
    final response = api.profileControllerSave(idempotencyKey, profileInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProfileApi->profileControllerSave: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **profileInput** | [**ProfileInput**](ProfileInput.md)|  |

### Return type

[**ProfileResponse**](ProfileResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

