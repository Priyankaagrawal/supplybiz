# supplybiz_api_client.api.MeApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**meControllerActiveRole**](MeApi.md#mecontrolleractiverole) | **PUT** /api/v1/me/active-role | 
[**meControllerAddRole**](MeApi.md#mecontrolleraddrole) | **POST** /api/v1/me/roles | 
[**meControllerMe**](MeApi.md#mecontrollerme) | **GET** /api/v1/me | 


# **meControllerActiveRole**
> MeResponse meControllerActiveRole(idempotencyKey, roleDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getMeApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final RoleDto roleDto = ; // RoleDto | 

try {
    final response = api.meControllerActiveRole(idempotencyKey, roleDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->meControllerActiveRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **roleDto** | [**RoleDto**](RoleDto.md)|  | 

### Return type

[**MeResponse**](MeResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **meControllerAddRole**
> MeResponse meControllerAddRole(idempotencyKey, roleDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getMeApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final RoleDto roleDto = ; // RoleDto | 

try {
    final response = api.meControllerAddRole(idempotencyKey, roleDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->meControllerAddRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **roleDto** | [**RoleDto**](RoleDto.md)|  | 

### Return type

[**MeResponse**](MeResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **meControllerMe**
> MeResponse meControllerMe()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getMeApi();

try {
    final response = api.meControllerMe();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MeApi->meControllerMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MeResponse**](MeResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

