# supplybiz_api_client.api.CustomerSubscriptionsApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**customerSubscriptionsControllerCancel**](CustomerSubscriptionsApi.md#customersubscriptionscontrollercancel) | **POST** /api/v1/customer/subscriptions/{id}/cancel |
[**customerSubscriptionsControllerCreate**](CustomerSubscriptionsApi.md#customersubscriptionscontrollercreate) | **POST** /api/v1/customer/subscriptions |
[**customerSubscriptionsControllerEdit**](CustomerSubscriptionsApi.md#customersubscriptionscontrolleredit) | **PATCH** /api/v1/customer/subscriptions/{id} |
[**customerSubscriptionsControllerGet**](CustomerSubscriptionsApi.md#customersubscriptionscontrollerget) | **GET** /api/v1/customer/subscriptions/{id} |
[**customerSubscriptionsControllerList**](CustomerSubscriptionsApi.md#customersubscriptionscontrollerlist) | **GET** /api/v1/customer/subscriptions |
[**customerSubscriptionsControllerPause**](CustomerSubscriptionsApi.md#customersubscriptionscontrollerpause) | **POST** /api/v1/customer/subscriptions/{id}/pause |
[**customerSubscriptionsControllerResume**](CustomerSubscriptionsApi.md#customersubscriptionscontrollerresume) | **POST** /api/v1/customer/subscriptions/{id}/resume |
[**customerSubscriptionsControllerSkip**](CustomerSubscriptionsApi.md#customersubscriptionscontrollerskip) | **POST** /api/v1/customer/subscriptions/{id}/skip |
[**subscriptionPlansControllerPlans**](CustomerSubscriptionsApi.md#subscriptionplanscontrollerplans) | **GET** /api/v1/customer/vendors/{id}/subscription-plans |


# **customerSubscriptionsControllerCancel**
> SubscriptionMutation customerSubscriptionsControllerCancel(id, idempotencyKey, subscriptionVersion)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionVersion subscriptionVersion = ; // SubscriptionVersion |

try {
    final response = api.customerSubscriptionsControllerCancel(id, idempotencyKey, subscriptionVersion);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->customerSubscriptionsControllerCancel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **subscriptionVersion** | [**SubscriptionVersion**](SubscriptionVersion.md)|  |

### Return type

[**SubscriptionMutation**](SubscriptionMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerSubscriptionsControllerCreate**
> SubscriptionMutation customerSubscriptionsControllerCreate(idempotencyKey, customerSubscriptionInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final CustomerSubscriptionInput customerSubscriptionInput = ; // CustomerSubscriptionInput |

try {
    final response = api.customerSubscriptionsControllerCreate(idempotencyKey, customerSubscriptionInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->customerSubscriptionsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **customerSubscriptionInput** | [**CustomerSubscriptionInput**](CustomerSubscriptionInput.md)|  |

### Return type

[**SubscriptionMutation**](SubscriptionMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerSubscriptionsControllerEdit**
> SubscriptionMutation customerSubscriptionsControllerEdit(id, idempotencyKey, subscriptionPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionPatch subscriptionPatch = ; // SubscriptionPatch |

try {
    final response = api.customerSubscriptionsControllerEdit(id, idempotencyKey, subscriptionPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->customerSubscriptionsControllerEdit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **subscriptionPatch** | [**SubscriptionPatch**](SubscriptionPatch.md)|  |

### Return type

[**SubscriptionMutation**](SubscriptionMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerSubscriptionsControllerGet**
> SubscriptionRecord customerSubscriptionsControllerGet(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final String id = id_example; // String |

try {
    final response = api.customerSubscriptionsControllerGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->customerSubscriptionsControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**SubscriptionRecord**](SubscriptionRecord.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerSubscriptionsControllerList**
> SubscriptionList customerSubscriptionsControllerList(limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.customerSubscriptionsControllerList(limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->customerSubscriptionsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**SubscriptionList**](SubscriptionList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerSubscriptionsControllerPause**
> SubscriptionMutation customerSubscriptionsControllerPause(id, idempotencyKey, subscriptionPause)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionPause subscriptionPause = ; // SubscriptionPause |

try {
    final response = api.customerSubscriptionsControllerPause(id, idempotencyKey, subscriptionPause);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->customerSubscriptionsControllerPause: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **subscriptionPause** | [**SubscriptionPause**](SubscriptionPause.md)|  |

### Return type

[**SubscriptionMutation**](SubscriptionMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerSubscriptionsControllerResume**
> SubscriptionMutation customerSubscriptionsControllerResume(id, idempotencyKey, subscriptionVersion)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionVersion subscriptionVersion = ; // SubscriptionVersion |

try {
    final response = api.customerSubscriptionsControllerResume(id, idempotencyKey, subscriptionVersion);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->customerSubscriptionsControllerResume: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **subscriptionVersion** | [**SubscriptionVersion**](SubscriptionVersion.md)|  |

### Return type

[**SubscriptionMutation**](SubscriptionMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerSubscriptionsControllerSkip**
> SubscriptionMutation customerSubscriptionsControllerSkip(id, idempotencyKey, subscriptionSkip)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionSkip subscriptionSkip = ; // SubscriptionSkip |

try {
    final response = api.customerSubscriptionsControllerSkip(id, idempotencyKey, subscriptionSkip);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->customerSubscriptionsControllerSkip: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **subscriptionSkip** | [**SubscriptionSkip**](SubscriptionSkip.md)|  |

### Return type

[**SubscriptionMutation**](SubscriptionMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subscriptionPlansControllerPlans**
> SubscriptionPlans subscriptionPlansControllerPlans(id, addressId)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerSubscriptionsApi();
final String id = id_example; // String |
final String addressId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |

try {
    final response = api.subscriptionPlansControllerPlans(id, addressId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerSubscriptionsApi->subscriptionPlansControllerPlans: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **addressId** | **String**|  |

### Return type

[**SubscriptionPlans**](SubscriptionPlans.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

