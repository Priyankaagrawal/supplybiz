# supplybiz_api_client.api.AdminPlansApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminPlansControllerAssign**](AdminPlansApi.md#adminplanscontrollerassign) | **POST** /api/v1/admin/vendors/{id}/plan-assignments |
[**adminPlansControllerCatalog**](AdminPlansApi.md#adminplanscontrollercatalog) | **GET** /api/v1/admin/plans |
[**adminPlansControllerCurrent**](AdminPlansApi.md#adminplanscontrollercurrent) | **GET** /api/v1/admin/vendors/{id}/plan |
[**adminPlansControllerExtend**](AdminPlansApi.md#adminplanscontrollerextend) | **POST** /api/v1/admin/vendors/{id}/plan-assignments/{assignmentId}/extend |


# **adminPlansControllerAssign**
> AssignmentResponse adminPlansControllerAssign(id, idempotencyKey, xCSRFToken, assignPlanInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminPlansApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final AssignPlanInput assignPlanInput = ; // AssignPlanInput |

try {
    final response = api.adminPlansControllerAssign(id, idempotencyKey, xCSRFToken, assignPlanInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminPlansApi->adminPlansControllerAssign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **assignPlanInput** | [**AssignPlanInput**](AssignPlanInput.md)|  |

### Return type

[**AssignmentResponse**](AssignmentResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminPlansControllerCatalog**
> PlanCatalogResponse adminPlansControllerCatalog()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminPlansApi();

try {
    final response = api.adminPlansControllerCatalog();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminPlansApi->adminPlansControllerCatalog: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PlanCatalogResponse**](PlanCatalogResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminPlansControllerCurrent**
> CurrentPlanResponse adminPlansControllerCurrent(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminPlansApi();
final String id = id_example; // String |

try {
    final response = api.adminPlansControllerCurrent(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminPlansApi->adminPlansControllerCurrent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**CurrentPlanResponse**](CurrentPlanResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminPlansControllerExtend**
> AssignmentResponse adminPlansControllerExtend(id, assignmentId, idempotencyKey, xCSRFToken, extendPlanInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminPlansApi();
final String id = id_example; // String |
final String assignmentId = assignmentId_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final ExtendPlanInput extendPlanInput = ; // ExtendPlanInput |

try {
    final response = api.adminPlansControllerExtend(id, assignmentId, idempotencyKey, xCSRFToken, extendPlanInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminPlansApi->adminPlansControllerExtend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **assignmentId** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **extendPlanInput** | [**ExtendPlanInput**](ExtendPlanInput.md)|  |

### Return type

[**AssignmentResponse**](AssignmentResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

