# supplybiz_api_client.api.VendorSalesApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**salesControllerComplete**](VendorSalesApi.md#salescontrollercomplete) | **POST** /api/v1/vendor/sales |
[**salesControllerGet**](VendorSalesApi.md#salescontrollerget) | **GET** /api/v1/vendor/sales/{id} |
[**salesControllerList**](VendorSalesApi.md#salescontrollerlist) | **GET** /api/v1/vendor/sales |


# **salesControllerComplete**
> SaleResponse salesControllerComplete(idempotencyKey, completeSaleInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSalesApi();
final String idempotencyKey = idempotencyKey_example; // String |
final CompleteSaleInput completeSaleInput = ; // CompleteSaleInput |

try {
    final response = api.salesControllerComplete(idempotencyKey, completeSaleInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSalesApi->salesControllerComplete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **completeSaleInput** | [**CompleteSaleInput**](CompleteSaleInput.md)|  |

### Return type

[**SaleResponse**](SaleResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **salesControllerGet**
> SaleResponse salesControllerGet(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSalesApi();
final String id = id_example; // String |

try {
    final response = api.salesControllerGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSalesApi->salesControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**SaleResponse**](SaleResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **salesControllerList**
> SaleList salesControllerList(date, vendorCustomerId, limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSalesApi();
final String date = date_example; // String | Server IST sale date YYYY-MM-DD.
final String vendorCustomerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.salesControllerList(date, vendorCustomerId, limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSalesApi->salesControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **String**| Server IST sale date YYYY-MM-DD. | [optional]
 **vendorCustomerId** | **String**|  | [optional]
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**SaleList**](SaleList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

