# supplybiz_api_client.api.VendorPlansApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorPlansControllerCatalog**](VendorPlansApi.md#vendorplanscontrollercatalog) | **GET** /api/v1/vendor/plans |
[**vendorPlansControllerCurrent**](VendorPlansApi.md#vendorplanscontrollercurrent) | **GET** /api/v1/vendor/plan |


# **vendorPlansControllerCatalog**
> PlanCatalogResponse vendorPlansControllerCatalog()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorPlansApi();

try {
    final response = api.vendorPlansControllerCatalog();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorPlansApi->vendorPlansControllerCatalog: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PlanCatalogResponse**](PlanCatalogResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorPlansControllerCurrent**
> CurrentPlanResponse vendorPlansControllerCurrent()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorPlansApi();

try {
    final response = api.vendorPlansControllerCurrent();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorPlansApi->vendorPlansControllerCurrent: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CurrentPlanResponse**](CurrentPlanResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

