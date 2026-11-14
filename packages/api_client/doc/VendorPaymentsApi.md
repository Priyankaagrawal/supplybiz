# supplybiz_api_client.api.VendorPaymentsApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**paymentsControllerList**](VendorPaymentsApi.md#paymentscontrollerlist) | **GET** /api/v1/vendor/payments |
[**paymentsControllerRecord**](VendorPaymentsApi.md#paymentscontrollerrecord) | **POST** /api/v1/vendor/payments |
[**paymentsControllerSummary**](VendorPaymentsApi.md#paymentscontrollersummary) | **GET** /api/v1/vendor/payments/summary |


# **paymentsControllerList**
> PaymentList paymentsControllerList(vendorCustomerId, limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorPaymentsApi();
final String vendorCustomerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.paymentsControllerList(vendorCustomerId, limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorPaymentsApi->paymentsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vendorCustomerId** | **String**|  | [optional]
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**PaymentList**](PaymentList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsControllerRecord**
> PaymentRecord paymentsControllerRecord(idempotencyKey, recordPaymentInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorPaymentsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final RecordPaymentInput recordPaymentInput = ; // RecordPaymentInput |

try {
    final response = api.paymentsControllerRecord(idempotencyKey, recordPaymentInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorPaymentsApi->paymentsControllerRecord: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **recordPaymentInput** | [**RecordPaymentInput**](RecordPaymentInput.md)|  |

### Return type

[**PaymentRecord**](PaymentRecord.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsControllerSummary**
> PaymentSummary paymentsControllerSummary()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorPaymentsApi();

try {
    final response = api.paymentsControllerSummary();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorPaymentsApi->paymentsControllerSummary: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PaymentSummary**](PaymentSummary.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

