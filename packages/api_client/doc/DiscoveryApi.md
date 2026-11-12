# supplybiz_api_client.api.DiscoveryApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**discoveryControllerAbout**](DiscoveryApi.md#discoverycontrollerabout) | **GET** /api/v1/customer/vendors/{id} |
[**discoveryControllerAdd**](DiscoveryApi.md#discoverycontrolleradd) | **PUT** /api/v1/customer/favorites/{id} |
[**discoveryControllerFavorites**](DiscoveryApi.md#discoverycontrollerfavorites) | **GET** /api/v1/customer/favorites |
[**discoveryControllerImage**](DiscoveryApi.md#discoverycontrollerimage) | **GET** /api/v1/customer/vendors/{id}/media/{mediaId}/content |
[**discoveryControllerList**](DiscoveryApi.md#discoverycontrollerlist) | **GET** /api/v1/customer/vendors |
[**discoveryControllerProduct**](DiscoveryApi.md#discoverycontrollerproduct) | **GET** /api/v1/customer/vendors/{id}/products/{productId} |
[**discoveryControllerProducts**](DiscoveryApi.md#discoverycontrollerproducts) | **GET** /api/v1/customer/vendors/{id}/products |
[**discoveryControllerRemove**](DiscoveryApi.md#discoverycontrollerremove) | **DELETE** /api/v1/customer/favorites/{id} |
[**discoveryControllerSearch**](DiscoveryApi.md#discoverycontrollersearch) | **GET** /api/v1/customer/search |


# **discoveryControllerAbout**
> VendorAbout discoveryControllerAbout(id, lat, lng, pincode, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final String id = id_example; // String |
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerAbout(id, lat, lng, pincode, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerAbout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**VendorAbout**](VendorAbout.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **discoveryControllerAdd**
> FavoriteResult discoveryControllerAdd(id, lat, lng, pincode, idempotencyKey, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final String id = id_example; // String |
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerAdd(id, lat, lng, pincode, idempotencyKey, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerAdd: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **idempotencyKey** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**FavoriteResult**](FavoriteResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **discoveryControllerFavorites**
> DiscoveryPage discoveryControllerFavorites(lat, lng, pincode, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerFavorites(lat, lng, pincode, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerFavorites: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**DiscoveryPage**](DiscoveryPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **discoveryControllerImage**
> Uint8List discoveryControllerImage(id, mediaId, lat, lng, pincode, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final String id = id_example; // String |
final String mediaId = mediaId_example; // String |
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerImage(id, mediaId, lat, lng, pincode, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerImage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **mediaId** | **String**|  |
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **discoveryControllerList**
> DiscoveryPage discoveryControllerList(lat, lng, pincode, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerList(lat, lng, pincode, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**DiscoveryPage**](DiscoveryPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **discoveryControllerProduct**
> ProductList discoveryControllerProduct(id, productId, lat, lng, pincode, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final String id = id_example; // String |
final String productId = productId_example; // String |
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerProduct(id, productId, lat, lng, pincode, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerProduct: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **productId** | **String**|  |
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**ProductList**](ProductList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **discoveryControllerProducts**
> ProductList discoveryControllerProducts(id, lat, lng, pincode, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final String id = id_example; // String |
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerProducts(id, lat, lng, pincode, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerProducts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**ProductList**](ProductList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **discoveryControllerRemove**
> FavoriteResult discoveryControllerRemove(id, lat, lng, pincode, idempotencyKey, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final String id = id_example; // String |
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerRemove(id, lat, lng, pincode, idempotencyKey, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **idempotencyKey** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**FavoriteResult**](FavoriteResult.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **discoveryControllerSearch**
> DiscoveryPage discoveryControllerSearch(lat, lng, pincode, category, sort, q, limit, cursor)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getDiscoveryApi();
final num lat = 8.14; // num |
final num lng = 8.14; // num |
final String pincode = pincode_example; // String |
final String category = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String sort = sort_example; // String |
final String q = q_example; // String |
final num limit = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.discoveryControllerSearch(lat, lng, pincode, category, sort, q, limit, cursor);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DiscoveryApi->discoveryControllerSearch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **lat** | **num**|  |
 **lng** | **num**|  |
 **pincode** | **String**|  |
 **category** | **String**|  | [optional]
 **sort** | **String**|  | [optional]
 **q** | **String**|  | [optional]
 **limit** | **num**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional]

### Return type

[**DiscoveryPage**](DiscoveryPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

