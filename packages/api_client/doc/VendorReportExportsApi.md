# supplybiz_api_client.api.VendorReportExportsApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**reportExportsControllerCreate**](VendorReportExportsApi.md#reportexportscontrollercreate) | **POST** /api/v1/vendor/reports/exports |
[**reportExportsControllerDownload**](VendorReportExportsApi.md#reportexportscontrollerdownload) | **GET** /api/v1/vendor/reports/exports/{id}/download |
[**reportExportsControllerStatus**](VendorReportExportsApi.md#reportexportscontrollerstatus) | **GET** /api/v1/vendor/reports/exports/{id} |


# **reportExportsControllerCreate**
> ReportExportCreated reportExportsControllerCreate(idempotencyKey, reportExportInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorReportExportsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final ReportExportInput reportExportInput = ; // ReportExportInput |

try {
    final response = api.reportExportsControllerCreate(idempotencyKey, reportExportInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorReportExportsApi->reportExportsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **reportExportInput** | [**ReportExportInput**](ReportExportInput.md)|  |

### Return type

[**ReportExportCreated**](ReportExportCreated.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportExportsControllerDownload**
> Uint8List reportExportsControllerDownload(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorReportExportsApi();
final String id = id_example; // String |

try {
    final response = api.reportExportsControllerDownload(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorReportExportsApi->reportExportsControllerDownload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/csv

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportExportsControllerStatus**
> ReportExportStatus reportExportsControllerStatus(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorReportExportsApi();
final String id = id_example; // String |

try {
    final response = api.reportExportsControllerStatus(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorReportExportsApi->reportExportsControllerStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**ReportExportStatus**](ReportExportStatus.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

