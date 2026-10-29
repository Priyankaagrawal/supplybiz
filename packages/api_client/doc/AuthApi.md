# supplybiz_api_client.api.AuthApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**otpControllerSend**](AuthApi.md#otpcontrollersend) | **POST** /api/v1/auth/otp/send | Send OTP (development simulation until Q-09 is resolved)
[**sessionsControllerJwks**](AuthApi.md#sessionscontrollerjwks) | **GET** /api/v1/auth/.well-known/jwks.json | 
[**sessionsControllerLogout**](AuthApi.md#sessionscontrollerlogout) | **POST** /api/v1/auth/logout | 
[**sessionsControllerRefresh**](AuthApi.md#sessionscontrollerrefresh) | **POST** /api/v1/auth/refresh | 
[**sessionsControllerVerify**](AuthApi.md#sessionscontrollerverify) | **POST** /api/v1/auth/otp/verify | 


# **otpControllerSend**
> SendOtpResponse otpControllerSend(xDeviceId, idempotencyKey, sendOtpDto)

Send OTP (development simulation until Q-09 is resolved)

### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAuthApi();
final String xDeviceId = xDeviceId_example; // String | Stable installation identifier, 1–128 ASCII letters, digits, hyphens or underscores.
final String idempotencyKey = idempotencyKey_example; // String | 
final SendOtpDto sendOtpDto = ; // SendOtpDto | 

try {
    final response = api.otpControllerSend(xDeviceId, idempotencyKey, sendOtpDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->otpControllerSend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xDeviceId** | **String**| Stable installation identifier, 1–128 ASCII letters, digits, hyphens or underscores. | 
 **idempotencyKey** | **String**|  | 
 **sendOtpDto** | [**SendOtpDto**](SendOtpDto.md)|  | 

### Return type

[**SendOtpResponse**](SendOtpResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sessionsControllerJwks**
> sessionsControllerJwks(idempotencyKey)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAuthApi();
final String idempotencyKey = idempotencyKey_example; // String | 

try {
    api.sessionsControllerJwks(idempotencyKey);
} on DioException catch (e) {
    print('Exception when calling AuthApi->sessionsControllerJwks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sessionsControllerLogout**
> sessionsControllerLogout(idempotencyKey, all)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAuthApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final String all = all_example; // String | 

try {
    api.sessionsControllerLogout(idempotencyKey, all);
} on DioException catch (e) {
    print('Exception when calling AuthApi->sessionsControllerLogout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **all** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sessionsControllerRefresh**
> TokensResponse sessionsControllerRefresh(idempotencyKey, refreshDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAuthApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final RefreshDto refreshDto = ; // RefreshDto | 

try {
    final response = api.sessionsControllerRefresh(idempotencyKey, refreshDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->sessionsControllerRefresh: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **refreshDto** | [**RefreshDto**](RefreshDto.md)|  | 

### Return type

[**TokensResponse**](TokensResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **sessionsControllerVerify**
> TokensResponse sessionsControllerVerify(idempotencyKey, verifyOtpDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAuthApi();
final String idempotencyKey = idempotencyKey_example; // String | 
final VerifyOtpDto verifyOtpDto = ; // VerifyOtpDto | 

try {
    final response = api.sessionsControllerVerify(idempotencyKey, verifyOtpDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->sessionsControllerVerify: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  | 
 **verifyOtpDto** | [**VerifyOtpDto**](VerifyOtpDto.md)|  | 

### Return type

[**TokensResponse**](TokensResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

