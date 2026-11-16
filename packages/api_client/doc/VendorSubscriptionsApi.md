# supplybiz_api_client.api.VendorSubscriptionsApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorSubscriptionsControllerApprove**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollerapprove) | **POST** /api/v1/vendor/subscriptions/{id}/approve |
[**vendorSubscriptionsControllerCancel**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollercancel) | **POST** /api/v1/vendor/subscriptions/{id}/cancel |
[**vendorSubscriptionsControllerCreate**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollercreate) | **POST** /api/v1/vendor/subscriptions |
[**vendorSubscriptionsControllerEdit**](VendorSubscriptionsApi.md#vendorsubscriptionscontrolleredit) | **PATCH** /api/v1/vendor/subscriptions/{id} |
[**vendorSubscriptionsControllerGet**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollerget) | **GET** /api/v1/vendor/subscriptions/{id} |
[**vendorSubscriptionsControllerList**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollerlist) | **GET** /api/v1/vendor/subscriptions |
[**vendorSubscriptionsControllerPause**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollerpause) | **POST** /api/v1/vendor/subscriptions/{id}/pause |
[**vendorSubscriptionsControllerReject**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollerreject) | **POST** /api/v1/vendor/subscriptions/{id}/reject |
[**vendorSubscriptionsControllerResume**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollerresume) | **POST** /api/v1/vendor/subscriptions/{id}/resume |
[**vendorSubscriptionsControllerSkip**](VendorSubscriptionsApi.md#vendorsubscriptionscontrollerskip) | **POST** /api/v1/vendor/subscriptions/{id}/skip |


# **vendorSubscriptionsControllerApprove**
> SubscriptionMutation vendorSubscriptionsControllerApprove(id, idempotencyKey, subscriptionVersion)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionVersion subscriptionVersion = ; // SubscriptionVersion |

try {
    final response = api.vendorSubscriptionsControllerApprove(id, idempotencyKey, subscriptionVersion);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerApprove: $e\n');
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

# **vendorSubscriptionsControllerCancel**
> SubscriptionMutation vendorSubscriptionsControllerCancel(id, idempotencyKey, subscriptionVersion)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionVersion subscriptionVersion = ; // SubscriptionVersion |

try {
    final response = api.vendorSubscriptionsControllerCancel(id, idempotencyKey, subscriptionVersion);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerCancel: $e\n');
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

# **vendorSubscriptionsControllerCreate**
> SubscriptionMutation vendorSubscriptionsControllerCreate(idempotencyKey, vendorSubscriptionInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final VendorSubscriptionInput vendorSubscriptionInput = ; // VendorSubscriptionInput |

try {
    final response = api.vendorSubscriptionsControllerCreate(idempotencyKey, vendorSubscriptionInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **vendorSubscriptionInput** | [**VendorSubscriptionInput**](VendorSubscriptionInput.md)|  |

### Return type

[**SubscriptionMutation**](SubscriptionMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorSubscriptionsControllerEdit**
> SubscriptionMutation vendorSubscriptionsControllerEdit(id, idempotencyKey, subscriptionPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionPatch subscriptionPatch = ; // SubscriptionPatch |

try {
    final response = api.vendorSubscriptionsControllerEdit(id, idempotencyKey, subscriptionPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerEdit: $e\n');
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

# **vendorSubscriptionsControllerGet**
> SubscriptionRecord vendorSubscriptionsControllerGet(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String id = id_example; // String |

try {
    final response = api.vendorSubscriptionsControllerGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerGet: $e\n');
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

# **vendorSubscriptionsControllerList**
> SubscriptionList vendorSubscriptionsControllerList(limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.vendorSubscriptionsControllerList(limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerList: $e\n');
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

# **vendorSubscriptionsControllerPause**
> SubscriptionMutation vendorSubscriptionsControllerPause(id, idempotencyKey, subscriptionPause)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionPause subscriptionPause = ; // SubscriptionPause |

try {
    final response = api.vendorSubscriptionsControllerPause(id, idempotencyKey, subscriptionPause);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerPause: $e\n');
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

# **vendorSubscriptionsControllerReject**
> SubscriptionMutation vendorSubscriptionsControllerReject(id, idempotencyKey, subscriptionReject)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionReject subscriptionReject = ; // SubscriptionReject |

try {
    final response = api.vendorSubscriptionsControllerReject(id, idempotencyKey, subscriptionReject);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerReject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **subscriptionReject** | [**SubscriptionReject**](SubscriptionReject.md)|  |

### Return type

[**SubscriptionMutation**](SubscriptionMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorSubscriptionsControllerResume**
> SubscriptionMutation vendorSubscriptionsControllerResume(id, idempotencyKey, subscriptionVersion)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionVersion subscriptionVersion = ; // SubscriptionVersion |

try {
    final response = api.vendorSubscriptionsControllerResume(id, idempotencyKey, subscriptionVersion);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerResume: $e\n');
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

# **vendorSubscriptionsControllerSkip**
> SubscriptionMutation vendorSubscriptionsControllerSkip(id, idempotencyKey, subscriptionSkip)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorSubscriptionsApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final SubscriptionSkip subscriptionSkip = ; // SubscriptionSkip |

try {
    final response = api.vendorSubscriptionsControllerSkip(id, idempotencyKey, subscriptionSkip);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorSubscriptionsApi->vendorSubscriptionsControllerSkip: $e\n');
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

