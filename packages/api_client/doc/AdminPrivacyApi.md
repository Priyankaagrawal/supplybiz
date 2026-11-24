# supplybiz_api_client.api.AdminPrivacyApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminPrivacyControllerCreate**](AdminPrivacyApi.md#adminprivacycontrollercreate) | **POST** /api/v1/admin/data-requests |
[**adminPrivacyControllerDownload**](AdminPrivacyApi.md#adminprivacycontrollerdownload) | **GET** /api/v1/admin/data-requests/{id}/export |
[**adminPrivacyControllerHold**](AdminPrivacyApi.md#adminprivacycontrollerhold) | **POST** /api/v1/admin/data-requests/{id}/hold |
[**adminPrivacyControllerList**](AdminPrivacyApi.md#adminprivacycontrollerlist) | **GET** /api/v1/admin/data-requests |


# **adminPrivacyControllerCreate**
> PrivacyRequestRow adminPrivacyControllerCreate(idempotencyKey, xCSRFToken, privacyExportInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminPrivacyApi();
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final PrivacyExportInput privacyExportInput = ; // PrivacyExportInput |

try {
    final response = api.adminPrivacyControllerCreate(idempotencyKey, xCSRFToken, privacyExportInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminPrivacyApi->adminPrivacyControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **privacyExportInput** | [**PrivacyExportInput**](PrivacyExportInput.md)|  |

### Return type

[**PrivacyRequestRow**](PrivacyRequestRow.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminPrivacyControllerDownload**
> SubjectExportResponse adminPrivacyControllerDownload(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminPrivacyApi();
final String id = id_example; // String |

try {
    final response = api.adminPrivacyControllerDownload(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminPrivacyApi->adminPrivacyControllerDownload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**SubjectExportResponse**](SubjectExportResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminPrivacyControllerHold**
> PrivacyRequestRow adminPrivacyControllerHold(id, idempotencyKey, xCSRFToken, privacyHoldInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminPrivacyApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final PrivacyHoldInput privacyHoldInput = ; // PrivacyHoldInput |

try {
    final response = api.adminPrivacyControllerHold(id, idempotencyKey, xCSRFToken, privacyHoldInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminPrivacyApi->adminPrivacyControllerHold: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **privacyHoldInput** | [**PrivacyHoldInput**](PrivacyHoldInput.md)|  |

### Return type

[**PrivacyRequestRow**](PrivacyRequestRow.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminPrivacyControllerList**
> PrivacyRequestsPage adminPrivacyControllerList(offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminPrivacyApi();
final num offset = 8.14; // num |

try {
    final response = api.adminPrivacyControllerList(offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminPrivacyApi->adminPrivacyControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **offset** | **num**|  | [optional]

### Return type

[**PrivacyRequestsPage**](PrivacyRequestsPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

