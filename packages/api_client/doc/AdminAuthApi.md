# supplybiz_api_client.api.AdminAuthApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminAuthControllerChallenge**](AdminAuthApi.md#adminauthcontrollerchallenge) | **GET** /api/v1/admin/auth/challenge |
[**adminAuthControllerLogin**](AdminAuthApi.md#adminauthcontrollerlogin) | **POST** /api/v1/admin/auth/login |
[**adminAuthControllerLogout**](AdminAuthApi.md#adminauthcontrollerlogout) | **POST** /api/v1/admin/auth/logout |
[**adminAuthControllerMe**](AdminAuthApi.md#adminauthcontrollerme) | **GET** /api/v1/admin/auth/me |
[**adminAuthControllerVerify**](AdminAuthApi.md#adminauthcontrollerverify) | **POST** /api/v1/admin/auth/totp/verify |


# **adminAuthControllerChallenge**
> AdminEnrollmentResponse adminAuthControllerChallenge()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAuthApi();

try {
    final response = api.adminAuthControllerChallenge();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminAuthApi->adminAuthControllerChallenge: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AdminEnrollmentResponse**](AdminEnrollmentResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminAuthControllerLogin**
> AdminChallengeResponse adminAuthControllerLogin(idempotencyKey, loginDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAuthApi();
final String idempotencyKey = idempotencyKey_example; // String |
final LoginDto loginDto = ; // LoginDto |

try {
    final response = api.adminAuthControllerLogin(idempotencyKey, loginDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminAuthApi->adminAuthControllerLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **loginDto** | [**LoginDto**](LoginDto.md)|  |

### Return type

[**AdminChallengeResponse**](AdminChallengeResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminAuthControllerLogout**
> adminAuthControllerLogout(xCSRFToken, idempotencyKey)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAuthApi();
final String xCSRFToken = xCSRFToken_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |

try {
    api.adminAuthControllerLogout(xCSRFToken, idempotencyKey);
} on DioException catch (e) {
    print('Exception when calling AdminAuthApi->adminAuthControllerLogout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCSRFToken** | **String**|  |
 **idempotencyKey** | **String**|  |

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminAuthControllerMe**
> AdminMeResponse adminAuthControllerMe()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAuthApi();

try {
    final response = api.adminAuthControllerMe();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminAuthApi->adminAuthControllerMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AdminMeResponse**](AdminMeResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminAuthControllerVerify**
> AdminSessionResponse adminAuthControllerVerify(idempotencyKey, totpDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAuthApi();
final String idempotencyKey = idempotencyKey_example; // String |
final TotpDto totpDto = ; // TotpDto |

try {
    final response = api.adminAuthControllerVerify(idempotencyKey, totpDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminAuthApi->adminAuthControllerVerify: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **totpDto** | [**TotpDto**](TotpDto.md)|  |

### Return type

[**AdminSessionResponse**](AdminSessionResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

