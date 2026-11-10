# supplybiz_api_client.api.VendorOnboardingApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorsControllerBusiness**](VendorOnboardingApi.md#vendorscontrollerbusiness) | **PUT** /api/v1/vendor/onboarding/business |
[**vendorsControllerCategories**](VendorOnboardingApi.md#vendorscontrollercategories) | **GET** /api/v1/vendor/onboarding/categories |
[**vendorsControllerCategory**](VendorOnboardingApi.md#vendorscontrollercategory) | **POST** /api/v1/vendor/onboarding/category |
[**vendorsControllerProfile**](VendorOnboardingApi.md#vendorscontrollerprofile) | **GET** /api/v1/vendor/onboarding |
[**vendorsControllerSaveServiceArea**](VendorOnboardingApi.md#vendorscontrollersaveservicearea) | **PUT** /api/v1/vendor/settings/service-area |
[**vendorsControllerServiceArea**](VendorOnboardingApi.md#vendorscontrollerservicearea) | **GET** /api/v1/vendor/settings/service-area |


# **vendorsControllerBusiness**
> VendorProfileResponse vendorsControllerBusiness(idempotencyKey, vendorBusinessDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOnboardingApi();
final String idempotencyKey = idempotencyKey_example; // String |
final VendorBusinessDto vendorBusinessDto = ; // VendorBusinessDto |

try {
    final response = api.vendorsControllerBusiness(idempotencyKey, vendorBusinessDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOnboardingApi->vendorsControllerBusiness: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **vendorBusinessDto** | [**VendorBusinessDto**](VendorBusinessDto.md)|  |

### Return type

[**VendorProfileResponse**](VendorProfileResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerCategories**
> List<VendorCategoryResponse> vendorsControllerCategories()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOnboardingApi();

try {
    final response = api.vendorsControllerCategories();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOnboardingApi->vendorsControllerCategories: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;VendorCategoryResponse&gt;**](VendorCategoryResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerCategory**
> VendorProfileResponse vendorsControllerCategory(idempotencyKey, vendorCategoryDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOnboardingApi();
final String idempotencyKey = idempotencyKey_example; // String |
final VendorCategoryDto vendorCategoryDto = ; // VendorCategoryDto |

try {
    final response = api.vendorsControllerCategory(idempotencyKey, vendorCategoryDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOnboardingApi->vendorsControllerCategory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **vendorCategoryDto** | [**VendorCategoryDto**](VendorCategoryDto.md)|  |

### Return type

[**VendorProfileResponse**](VendorProfileResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerProfile**
> VendorProfileResponse vendorsControllerProfile()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOnboardingApi();

try {
    final response = api.vendorsControllerProfile();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOnboardingApi->vendorsControllerProfile: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**VendorProfileResponse**](VendorProfileResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerSaveServiceArea**
> VendorProfileResponse vendorsControllerSaveServiceArea(idempotencyKey, serviceAreaDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOnboardingApi();
final String idempotencyKey = idempotencyKey_example; // String |
final ServiceAreaDto serviceAreaDto = ; // ServiceAreaDto |

try {
    final response = api.vendorsControllerSaveServiceArea(idempotencyKey, serviceAreaDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOnboardingApi->vendorsControllerSaveServiceArea: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **serviceAreaDto** | [**ServiceAreaDto**](ServiceAreaDto.md)|  |

### Return type

[**VendorProfileResponse**](VendorProfileResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorsControllerServiceArea**
> VendorProfileResponse vendorsControllerServiceArea()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorOnboardingApi();

try {
    final response = api.vendorsControllerServiceArea();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorOnboardingApi->vendorsControllerServiceArea: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**VendorProfileResponse**](VendorProfileResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

