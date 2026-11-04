# supplybiz_api_client.api.AuditApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**auditControllerList**](AuditApi.md#auditcontrollerlist) | **GET** /api/v1/admin/audit-logs |


# **auditControllerList**
> AuditPage auditControllerList(beforeId, action, actorId)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAuditApi();
final String beforeId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String action = action_example; // String |
final String actorId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |

try {
    final response = api.auditControllerList(beforeId, action, actorId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuditApi->auditControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **beforeId** | **String**|  | [optional]
 **action** | **String**|  | [optional]
 **actorId** | **String**|  | [optional]

### Return type

[**AuditPage**](AuditPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

