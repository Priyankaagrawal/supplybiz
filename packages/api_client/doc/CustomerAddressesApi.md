# supplybiz_api_client.api.CustomerAddressesApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addressesControllerCreate**](CustomerAddressesApi.md#addressescontrollercreate) | **POST** /api/v1/customer/addresses |
[**addressesControllerGet**](CustomerAddressesApi.md#addressescontrollerget) | **GET** /api/v1/customer/addresses/{id} |
[**addressesControllerList**](CustomerAddressesApi.md#addressescontrollerlist) | **GET** /api/v1/customer/addresses |
[**addressesControllerPatch**](CustomerAddressesApi.md#addressescontrollerpatch) | **PATCH** /api/v1/customer/addresses/{id} |
[**addressesControllerRemove**](CustomerAddressesApi.md#addressescontrollerremove) | **DELETE** /api/v1/customer/addresses/{id} |


# **addressesControllerCreate**
> AddressResponse addressesControllerCreate(idempotencyKey, addressInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerAddressesApi();
final String idempotencyKey = idempotencyKey_example; // String |
final AddressInput addressInput = ; // AddressInput |

try {
    final response = api.addressesControllerCreate(idempotencyKey, addressInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerAddressesApi->addressesControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **addressInput** | [**AddressInput**](AddressInput.md)|  |

### Return type

[**AddressResponse**](AddressResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addressesControllerGet**
> AddressResponse addressesControllerGet(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerAddressesApi();
final String id = id_example; // String |

try {
    final response = api.addressesControllerGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerAddressesApi->addressesControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**AddressResponse**](AddressResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addressesControllerList**
> AddressList addressesControllerList()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerAddressesApi();

try {
    final response = api.addressesControllerList();
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerAddressesApi->addressesControllerList: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AddressList**](AddressList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addressesControllerPatch**
> AddressResponse addressesControllerPatch(id, idempotencyKey, addressPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerAddressesApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final AddressPatch addressPatch = ; // AddressPatch |

try {
    final response = api.addressesControllerPatch(id, idempotencyKey, addressPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerAddressesApi->addressesControllerPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **addressPatch** | [**AddressPatch**](AddressPatch.md)|  |

### Return type

[**AddressResponse**](AddressResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addressesControllerRemove**
> AddressDeleted addressesControllerRemove(id, idempotencyKey)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerAddressesApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |

try {
    final response = api.addressesControllerRemove(id, idempotencyKey);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerAddressesApi->addressesControllerRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |

### Return type

[**AddressDeleted**](AddressDeleted.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

