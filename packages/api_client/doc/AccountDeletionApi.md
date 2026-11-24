# supplybiz_api_client.api.AccountDeletionApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**accountDeletionControllerConfirm**](AccountDeletionApi.md#accountdeletioncontrollerconfirm) | **POST** /api/v1/me/deletion |
[**accountDeletionControllerPreview**](AccountDeletionApi.md#accountdeletioncontrollerpreview) | **GET** /api/v1/me/deletion |
[**accountDeletionControllerSend**](AccountDeletionApi.md#accountdeletioncontrollersend) | **POST** /api/v1/me/deletion/otp |


# **accountDeletionControllerConfirm**
> DeletionReceipt accountDeletionControllerConfirm(idempotencyKey, confirmDeletionInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAccountDeletionApi();
final String idempotencyKey = idempotencyKey_example; // String |
final ConfirmDeletionInput confirmDeletionInput = ; // ConfirmDeletionInput |

try {
    final response = api.accountDeletionControllerConfirm(idempotencyKey, confirmDeletionInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountDeletionApi->accountDeletionControllerConfirm: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **confirmDeletionInput** | [**ConfirmDeletionInput**](ConfirmDeletionInput.md)|  |

### Return type

[**DeletionReceipt**](DeletionReceipt.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **accountDeletionControllerPreview**
> DeletionPreview accountDeletionControllerPreview()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAccountDeletionApi();

try {
    final response = api.accountDeletionControllerPreview();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountDeletionApi->accountDeletionControllerPreview: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DeletionPreview**](DeletionPreview.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **accountDeletionControllerSend**
> SendOtpResponse accountDeletionControllerSend(xDeviceId, idempotencyKey)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAccountDeletionApi();
final String xDeviceId = xDeviceId_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |

try {
    final response = api.accountDeletionControllerSend(xDeviceId, idempotencyKey);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AccountDeletionApi->accountDeletionControllerSend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xDeviceId** | **String**|  |
 **idempotencyKey** | **String**|  |

### Return type

[**SendOtpResponse**](SendOtpResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

