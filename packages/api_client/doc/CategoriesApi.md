# supplybiz_api_client.api.CategoriesApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**categoriesControllerCreate**](CategoriesApi.md#categoriescontrollercreate) | **POST** /api/v1/admin/categories |
[**categoriesControllerList**](CategoriesApi.md#categoriescontrollerlist) | **GET** /api/v1/admin/categories |
[**categoriesControllerUpdate**](CategoriesApi.md#categoriescontrollerupdate) | **PUT** /api/v1/admin/categories/{id} |


# **categoriesControllerCreate**
> CategoryRow categoriesControllerCreate(idempotencyKey, xCSRFToken, categoryInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCategoriesApi();
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final CategoryInput categoryInput = ; // CategoryInput |

try {
    final response = api.categoriesControllerCreate(idempotencyKey, xCSRFToken, categoryInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CategoriesApi->categoriesControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **categoryInput** | [**CategoryInput**](CategoryInput.md)|  |

### Return type

[**CategoryRow**](CategoryRow.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **categoriesControllerList**
> CategoryList categoriesControllerList()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCategoriesApi();

try {
    final response = api.categoriesControllerList();
    print(response);
} on DioException catch (e) {
    print('Exception when calling CategoriesApi->categoriesControllerList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CategoryList**](CategoryList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **categoriesControllerUpdate**
> CategoryRow categoriesControllerUpdate(id, idempotencyKey, xCSRFToken, categoryInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCategoriesApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final CategoryInput categoryInput = ; // CategoryInput |

try {
    final response = api.categoriesControllerUpdate(id, idempotencyKey, xCSRFToken, categoryInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CategoriesApi->categoriesControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **categoryInput** | [**CategoryInput**](CategoryInput.md)|  |

### Return type

[**CategoryRow**](CategoryRow.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

