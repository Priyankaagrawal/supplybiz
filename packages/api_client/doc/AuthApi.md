# supplybiz_api_client.api.AuthApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**otpControllerSend**](AuthApi.md#otpcontrollersend) | **POST** /api/v1/auth/otp/send | Send OTP (development simulation until Q-09 is resolved)


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

