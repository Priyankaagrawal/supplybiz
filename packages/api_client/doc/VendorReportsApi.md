# supplybiz_api_client.api.VendorReportsApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**reportsControllerDaily**](VendorReportsApi.md#reportscontrollerdaily) | **GET** /api/v1/vendor/reports/sales-daily |
[**reportsControllerProducts**](VendorReportsApi.md#reportscontrollerproducts) | **GET** /api/v1/vendor/reports/products |
[**reportsControllerSummary**](VendorReportsApi.md#reportscontrollersummary) | **GET** /api/v1/vendor/reports/summary |


# **reportsControllerDaily**
> ReportDailySales reportsControllerDaily(from, to)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorReportsApi();
final String from = from_example; // String | Inclusive IST date. Supply from and to together; omit both for database Today. Max 366 days.
final String to = to_example; // String |

try {
    final response = api.reportsControllerDaily(from, to);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorReportsApi->reportsControllerDaily: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **String**| Inclusive IST date. Supply from and to together; omit both for database Today. Max 366 days. | [optional]
 **to** | **String**|  | [optional]

### Return type

[**ReportDailySales**](ReportDailySales.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportsControllerProducts**
> ReportProducts reportsControllerProducts(from, to, limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorReportsApi();
final String from = from_example; // String | Inclusive IST date. Supply from and to together; omit both for database Today. Max 366 days.
final String to = to_example; // String |
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.reportsControllerProducts(from, to, limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorReportsApi->reportsControllerProducts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **String**| Inclusive IST date. Supply from and to together; omit both for database Today. Max 366 days. | [optional]
 **to** | **String**|  | [optional]
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**ReportProducts**](ReportProducts.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportsControllerSummary**
> ReportSummary reportsControllerSummary(from, to)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorReportsApi();
final String from = from_example; // String | Inclusive IST date. Supply from and to together; omit both for database Today. Max 366 days.
final String to = to_example; // String |

try {
    final response = api.reportsControllerSummary(from, to);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorReportsApi->reportsControllerSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **String**| Inclusive IST date. Supply from and to together; omit both for database Today. Max 366 days. | [optional]
 **to** | **String**|  | [optional]

### Return type

[**ReportSummary**](ReportSummary.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

