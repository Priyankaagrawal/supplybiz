# supplybiz_api_client.api.CustomerLinksApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**customerLinksControllerAccept**](CustomerLinksApi.md#customerlinkscontrolleraccept) | **POST** /api/v1/customer/link-requests/{id}/accept |
[**customerLinksControllerDecline**](CustomerLinksApi.md#customerlinkscontrollerdecline) | **POST** /api/v1/customer/link-requests/{id}/decline |
[**customerLinksControllerList**](CustomerLinksApi.md#customerlinkscontrollerlist) | **GET** /api/v1/customer/link-requests |


# **customerLinksControllerAccept**
> LinkDecisionResponse customerLinksControllerAccept(id, idempotencyKey)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerLinksApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |

try {
    final response = api.customerLinksControllerAccept(id, idempotencyKey);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerLinksApi->customerLinksControllerAccept: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |

### Return type

[**LinkDecisionResponse**](LinkDecisionResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerLinksControllerDecline**
> LinkDecisionResponse customerLinksControllerDecline(id, idempotencyKey)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerLinksApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |

try {
    final response = api.customerLinksControllerDecline(id, idempotencyKey);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerLinksApi->customerLinksControllerDecline: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |

### Return type

[**LinkDecisionResponse**](LinkDecisionResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerLinksControllerList**
> LinkRequestList customerLinksControllerList(limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerLinksApi();
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.customerLinksControllerList(limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerLinksApi->customerLinksControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 50]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**LinkRequestList**](LinkRequestList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

