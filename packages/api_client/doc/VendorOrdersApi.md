# supplybiz_api_client.api.VendorOrdersApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorOrdersControllerDetail**](VendorOrdersApi.md#vendororderscontrollerdetail) | **GET** /api/v1/vendor/orders/{id} |
[**vendorOrdersControllerList**](VendorOrdersApi.md#vendororderscontrollerlist) | **GET** /api/v1/vendor/orders |
[**vendorOrdersControllerTransition**](VendorOrdersApi.md#vendororderscontrollertransition) | **POST** /api/v1/vendor/orders/{id}/transitions |


# **vendorOrdersControllerDetail**
> OrderDetail vendorOrdersControllerDetail(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOrdersApi();
final String id = id_example; // String |

try {
    final response = api.vendorOrdersControllerDetail(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOrdersApi->vendorOrdersControllerDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**OrderDetail**](OrderDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorOrdersControllerList**
> OrderList vendorOrdersControllerList(status, tab, q, date, limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOrdersApi();
final String status = status_example; // String |
final String tab = tab_example; // String |
final String q = q_example; // String |
final DateTime date = 2013-10-20; // DateTime |
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.vendorOrdersControllerList(status, tab, q, date, limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOrdersApi->vendorOrdersControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional]
 **tab** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **date** | **DateTime**|  | [optional]
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**OrderList**](OrderList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorOrdersControllerTransition**
> OrderResult vendorOrdersControllerTransition(id, idempotencyKey, orderTransitionInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOrdersApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final OrderTransitionInput orderTransitionInput = ; // OrderTransitionInput |

try {
    final response = api.vendorOrdersControllerTransition(id, idempotencyKey, orderTransitionInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOrdersApi->vendorOrdersControllerTransition: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **orderTransitionInput** | [**OrderTransitionInput**](OrderTransitionInput.md)|  |

### Return type

[**OrderResult**](OrderResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

