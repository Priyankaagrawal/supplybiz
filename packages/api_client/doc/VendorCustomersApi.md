# supplybiz_api_client.api.VendorCustomersApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**customersControllerCreate**](VendorCustomersApi.md#customerscontrollercreate) | **POST** /api/v1/vendor/customers |
[**customersControllerGet**](VendorCustomersApi.md#customerscontrollerget) | **GET** /api/v1/vendor/customers/{id} |
[**customersControllerList**](VendorCustomersApi.md#customerscontrollerlist) | **GET** /api/v1/vendor/customers |
[**customersControllerPatch**](VendorCustomersApi.md#customerscontrollerpatch) | **PATCH** /api/v1/vendor/customers/{id} |


# **customersControllerCreate**
> CustomerResponse customersControllerCreate(idempotencyKey, customerInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorCustomersApi();
final String idempotencyKey = idempotencyKey_example; // String |
final CustomerInput customerInput = ; // CustomerInput |

try {
    final response = api.customersControllerCreate(idempotencyKey, customerInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorCustomersApi->customersControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **customerInput** | [**CustomerInput**](CustomerInput.md)|  |

### Return type

[**CustomerResponse**](CustomerResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerGet**
> CustomerResponse customersControllerGet(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorCustomersApi();
final String id = id_example; // String |

try {
    final response = api.customersControllerGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorCustomersApi->customersControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**CustomerResponse**](CustomerResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerList**
> CustomerList customersControllerList(search, filter, limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorCustomersApi();
final String search = search_example; // String |
final String filter = filter_example; // String |
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.customersControllerList(search, filter, limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorCustomersApi->customersControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**|  | [optional]
 **filter** | **String**|  | [optional] [default to 'ALL']
 **limit** | **int**|  | [optional] [default to 50]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**CustomerList**](CustomerList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customersControllerPatch**
> CustomerResponse customersControllerPatch(id, idempotencyKey, customerPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorCustomersApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final CustomerPatch customerPatch = ; // CustomerPatch |

try {
    final response = api.customersControllerPatch(id, idempotencyKey, customerPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorCustomersApi->customersControllerPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **customerPatch** | [**CustomerPatch**](CustomerPatch.md)|  |

### Return type

[**CustomerResponse**](CustomerResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

