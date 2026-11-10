# supplybiz_api_client.api.CatalogApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**catalogControllerAdjust**](CatalogApi.md#catalogcontrolleradjust) | **POST** /api/v1/vendor/products/{id}/stock-adjustments |
[**catalogControllerCreate**](CatalogApi.md#catalogcontrollercreate) | **POST** /api/v1/vendor/products |
[**catalogControllerGet**](CatalogApi.md#catalogcontrollerget) | **GET** /api/v1/vendor/products/{id} |
[**catalogControllerList**](CatalogApi.md#catalogcontrollerlist) | **GET** /api/v1/vendor/products |
[**catalogControllerPatch**](CatalogApi.md#catalogcontrollerpatch) | **PATCH** /api/v1/vendor/products/{id} |
[**catalogControllerRemove**](CatalogApi.md#catalogcontrollerremove) | **DELETE** /api/v1/vendor/products/{id} |


# **catalogControllerAdjust**
> ProductResponse catalogControllerAdjust(id, idempotencyKey, stockAdjustment)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCatalogApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final StockAdjustment stockAdjustment = ; // StockAdjustment |

try {
    final response = api.catalogControllerAdjust(id, idempotencyKey, stockAdjustment);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->catalogControllerAdjust: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **stockAdjustment** | [**StockAdjustment**](StockAdjustment.md)|  |

### Return type

[**ProductResponse**](ProductResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **catalogControllerCreate**
> ProductResponse catalogControllerCreate(idempotencyKey, productInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCatalogApi();
final String idempotencyKey = idempotencyKey_example; // String |
final ProductInput productInput = ; // ProductInput |

try {
    final response = api.catalogControllerCreate(idempotencyKey, productInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->catalogControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **productInput** | [**ProductInput**](ProductInput.md)|  |

### Return type

[**ProductResponse**](ProductResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **catalogControllerGet**
> ProductResponse catalogControllerGet(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCatalogApi();
final String id = id_example; // String |

try {
    final response = api.catalogControllerGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->catalogControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**ProductResponse**](ProductResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **catalogControllerList**
> ProductList catalogControllerList(search, productType, limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCatalogApi();
final String search = search_example; // String |
final String productType = productType_example; // String |
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.catalogControllerList(search, productType, limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->catalogControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**|  | [optional]
 **productType** | **String**|  | [optional]
 **limit** | **int**|  | [optional] [default to 50]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**ProductList**](ProductList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **catalogControllerPatch**
> ProductResponse catalogControllerPatch(id, idempotencyKey, productPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCatalogApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final ProductPatch productPatch = ; // ProductPatch |

try {
    final response = api.catalogControllerPatch(id, idempotencyKey, productPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->catalogControllerPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **productPatch** | [**ProductPatch**](ProductPatch.md)|  |

### Return type

[**ProductResponse**](ProductResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **catalogControllerRemove**
> ProductDeleted catalogControllerRemove(id, idempotencyKey)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCatalogApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |

try {
    final response = api.catalogControllerRemove(id, idempotencyKey);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CatalogApi->catalogControllerRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |

### Return type

[**ProductDeleted**](ProductDeleted.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

