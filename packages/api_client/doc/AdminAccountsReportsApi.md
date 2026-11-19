# supplybiz_api_client.api.AdminAccountsReportsApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminAccountsControllerChange**](AdminAccountsReportsApi.md#adminaccountscontrollerchange) | **PATCH** /api/v1/admin/admins/{id} |
[**adminAccountsControllerCreate**](AdminAccountsReportsApi.md#adminaccountscontrollercreate) | **POST** /api/v1/admin/admins |
[**adminAccountsControllerExport**](AdminAccountsReportsApi.md#adminaccountscontrollerexport) | **POST** /api/v1/admin/reports/exports |
[**adminAccountsControllerList**](AdminAccountsReportsApi.md#adminaccountscontrollerlist) | **GET** /api/v1/admin/admins |


# **adminAccountsControllerChange**
> AdminAccountResponse adminAccountsControllerChange(idempotencyKey, id, xCSRFToken, changeAdminInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAccountsReportsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final String id = id_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final ChangeAdminInput changeAdminInput = ; // ChangeAdminInput |

try {
    final response = api.adminAccountsControllerChange(idempotencyKey, id, xCSRFToken, changeAdminInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminAccountsReportsApi->adminAccountsControllerChange: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **id** | **String**|  |
 **xCSRFToken** | **String**|  |
 **changeAdminInput** | [**ChangeAdminInput**](ChangeAdminInput.md)|  |

### Return type

[**AdminAccountResponse**](AdminAccountResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminAccountsControllerCreate**
> AdminAccountResponse adminAccountsControllerCreate(idempotencyKey, xCSRFToken, createAdminInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAccountsReportsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final CreateAdminInput createAdminInput = ; // CreateAdminInput |

try {
    final response = api.adminAccountsControllerCreate(idempotencyKey, xCSRFToken, createAdminInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminAccountsReportsApi->adminAccountsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **createAdminInput** | [**CreateAdminInput**](CreateAdminInput.md)|  |

### Return type

[**AdminAccountResponse**](AdminAccountResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminAccountsControllerExport**
> PlatformExportResponse adminAccountsControllerExport(idempotencyKey, xCSRFToken, platformExportInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAccountsReportsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final PlatformExportInput platformExportInput = ; // PlatformExportInput |

try {
    final response = api.adminAccountsControllerExport(idempotencyKey, xCSRFToken, platformExportInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminAccountsReportsApi->adminAccountsControllerExport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **platformExportInput** | [**PlatformExportInput**](PlatformExportInput.md)|  |

### Return type

[**PlatformExportResponse**](PlatformExportResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminAccountsControllerList**
> AdminAccountsResponse adminAccountsControllerList(offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminAccountsReportsApi();
final num offset = 8.14; // num |

try {
    final response = api.adminAccountsControllerList(offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminAccountsReportsApi->adminAccountsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **offset** | **num**|  | [optional]

### Return type

[**AdminAccountsResponse**](AdminAccountsResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

