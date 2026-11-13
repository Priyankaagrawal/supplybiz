# supplybiz_api_client.api.CustomerOrdersApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**customerOrdersControllerCancel**](CustomerOrdersApi.md#customerorderscontrollercancel) | **POST** /api/v1/customer/orders/{id}/cancel |
[**customerOrdersControllerDetail**](CustomerOrdersApi.md#customerorderscontrollerdetail) | **GET** /api/v1/customer/orders/{id} |
[**customerOrdersControllerList**](CustomerOrdersApi.md#customerorderscontrollerlist) | **GET** /api/v1/customer/orders |
[**customerOrdersControllerPlace**](CustomerOrdersApi.md#customerorderscontrollerplace) | **POST** /api/v1/customer/orders |
[**customerOrdersControllerQuote**](CustomerOrdersApi.md#customerorderscontrollerquote) | **POST** /api/v1/customer/orders/quote |


# **customerOrdersControllerCancel**
> OrderResult customerOrdersControllerCancel(id, idempotencyKey, orderCancelInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerOrdersApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final OrderCancelInput orderCancelInput = ; // OrderCancelInput |

try {
    final response = api.customerOrdersControllerCancel(id, idempotencyKey, orderCancelInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerOrdersApi->customerOrdersControllerCancel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **orderCancelInput** | [**OrderCancelInput**](OrderCancelInput.md)|  |

### Return type

[**OrderResult**](OrderResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerOrdersControllerDetail**
> OrderDetail customerOrdersControllerDetail(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerOrdersApi();
final String id = id_example; // String |

try {
    final response = api.customerOrdersControllerDetail(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerOrdersApi->customerOrdersControllerDetail: $e\n');
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

# **customerOrdersControllerList**
> OrderList customerOrdersControllerList(status, tab, q, date, limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerOrdersApi();
final String status = status_example; // String |
final String tab = tab_example; // String |
final String q = q_example; // String |
final DateTime date = 2013-10-20; // DateTime |
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.customerOrdersControllerList(status, tab, q, date, limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerOrdersApi->customerOrdersControllerList: $e\n');
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

# **customerOrdersControllerPlace**
> OrderResult customerOrdersControllerPlace(idempotencyKey, orderPlaceInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerOrdersApi();
final String idempotencyKey = idempotencyKey_example; // String |
final OrderPlaceInput orderPlaceInput = ; // OrderPlaceInput |

try {
    final response = api.customerOrdersControllerPlace(idempotencyKey, orderPlaceInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerOrdersApi->customerOrdersControllerPlace: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **orderPlaceInput** | [**OrderPlaceInput**](OrderPlaceInput.md)|  |

### Return type

[**OrderResult**](OrderResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerOrdersControllerQuote**
> OrderQuote customerOrdersControllerQuote(orderQuoteInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerOrdersApi();
final OrderQuoteInput orderQuoteInput = ; // OrderQuoteInput |

try {
    final response = api.customerOrdersControllerQuote(orderQuoteInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerOrdersApi->customerOrdersControllerQuote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderQuoteInput** | [**OrderQuoteInput**](OrderQuoteInput.md)|  |

### Return type

[**OrderQuote**](OrderQuote.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

