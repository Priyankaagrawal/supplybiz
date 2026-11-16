# supplybiz_api_client.api.VendorSubscriptionSettingsApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**subscriptionSettingsControllerCustomers**](VendorSubscriptionSettingsApi.md#subscriptionsettingscontrollercustomers) | **GET** /api/v1/vendor/settings/subscription-customers |
[**subscriptionSettingsControllerGet**](VendorSubscriptionSettingsApi.md#subscriptionsettingscontrollerget) | **GET** /api/v1/vendor/settings |
[**subscriptionSettingsControllerPatch**](VendorSubscriptionSettingsApi.md#subscriptionsettingscontrollerpatch) | **PATCH** /api/v1/vendor/settings |


# **subscriptionSettingsControllerCustomers**
> SubscriptionCustomerList subscriptionSettingsControllerCustomers(limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionSettingsApi();
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.subscriptionSettingsControllerCustomers(limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionSettingsApi->subscriptionSettingsControllerCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**SubscriptionCustomerList**](SubscriptionCustomerList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subscriptionSettingsControllerGet**
> SubscriptionSettingsResponse subscriptionSettingsControllerGet()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionSettingsApi();

try {
    final response = api.subscriptionSettingsControllerGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionSettingsApi->subscriptionSettingsControllerGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SubscriptionSettingsResponse**](SubscriptionSettingsResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subscriptionSettingsControllerPatch**
> SubscriptionSettingsResponse subscriptionSettingsControllerPatch(idempotencyKey, subscriptionSettingsPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionSettingsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionSettingsPatch subscriptionSettingsPatch = ; // SubscriptionSettingsPatch |

try {
    final response = api.subscriptionSettingsControllerPatch(idempotencyKey, subscriptionSettingsPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionSettingsApi->subscriptionSettingsControllerPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **subscriptionSettingsPatch** | [**SubscriptionSettingsPatch**](SubscriptionSettingsPatch.md)|  |

### Return type

[**SubscriptionSettingsResponse**](SubscriptionSettingsResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

