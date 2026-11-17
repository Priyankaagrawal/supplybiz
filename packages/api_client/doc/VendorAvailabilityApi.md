# supplybiz_api_client.api.VendorAvailabilityApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**availabilityControllerCreate**](VendorAvailabilityApi.md#availabilitycontrollercreate) | **POST** /api/v1/vendor/holidays |
[**availabilityControllerDelete**](VendorAvailabilityApi.md#availabilitycontrollerdelete) | **DELETE** /api/v1/vendor/holidays/{id} |
[**availabilityControllerGet**](VendorAvailabilityApi.md#availabilitycontrollerget) | **GET** /api/v1/vendor/availability |
[**availabilityControllerImpact**](VendorAvailabilityApi.md#availabilitycontrollerimpact) | **GET** /api/v1/vendor/holidays/impact |
[**availabilityControllerList**](VendorAvailabilityApi.md#availabilitycontrollerlist) | **GET** /api/v1/vendor/holidays |
[**availabilityControllerPatch**](VendorAvailabilityApi.md#availabilitycontrollerpatch) | **PATCH** /api/v1/vendor/availability |
[**availabilityControllerPauseImpact**](VendorAvailabilityApi.md#availabilitycontrollerpauseimpact) | **GET** /api/v1/vendor/availability/impact |


# **availabilityControllerCreate**
> HolidayMutation availabilityControllerCreate(idempotencyKey, holidayInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorAvailabilityApi();
final String idempotencyKey = idempotencyKey_example; // String |
final HolidayInput holidayInput = ; // HolidayInput |

try {
    final response = api.availabilityControllerCreate(idempotencyKey, holidayInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorAvailabilityApi->availabilityControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **holidayInput** | [**HolidayInput**](HolidayInput.md)|  |

### Return type

[**HolidayMutation**](HolidayMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **availabilityControllerDelete**
> HolidayDeleted availabilityControllerDelete(idempotencyKey, id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorAvailabilityApi();
final String idempotencyKey = idempotencyKey_example; // String |
final String id = id_example; // String |

try {
    final response = api.availabilityControllerDelete(idempotencyKey, id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorAvailabilityApi->availabilityControllerDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **id** | **String**|  |

### Return type

[**HolidayDeleted**](HolidayDeleted.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **availabilityControllerGet**
> AvailabilityResponse availabilityControllerGet()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorAvailabilityApi();

try {
    final response = api.availabilityControllerGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorAvailabilityApi->availabilityControllerGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AvailabilityResponse**](AvailabilityResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **availabilityControllerImpact**
> DeliveryImpact availabilityControllerImpact(date)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorAvailabilityApi();
final String date = date_example; // String | IST calendar date YYYY-MM-DD.

try {
    final response = api.availabilityControllerImpact(date);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorAvailabilityApi->availabilityControllerImpact: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **String**| IST calendar date YYYY-MM-DD. |

### Return type

[**DeliveryImpact**](DeliveryImpact.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **availabilityControllerList**
> HolidayList availabilityControllerList(limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorAvailabilityApi();
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.availabilityControllerList(limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorAvailabilityApi->availabilityControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**HolidayList**](HolidayList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **availabilityControllerPatch**
> AvailabilityMutation availabilityControllerPatch(idempotencyKey, availabilityPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorAvailabilityApi();
final String idempotencyKey = idempotencyKey_example; // String |
final AvailabilityPatch availabilityPatch = ; // AvailabilityPatch |

try {
    final response = api.availabilityControllerPatch(idempotencyKey, availabilityPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorAvailabilityApi->availabilityControllerPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **availabilityPatch** | [**AvailabilityPatch**](AvailabilityPatch.md)|  |

### Return type

[**AvailabilityMutation**](AvailabilityMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **availabilityControllerPauseImpact**
> DeliveryImpact availabilityControllerPauseImpact()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorAvailabilityApi();

try {
    final response = api.availabilityControllerPauseImpact();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorAvailabilityApi->availabilityControllerPauseImpact: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DeliveryImpact**](DeliveryImpact.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

