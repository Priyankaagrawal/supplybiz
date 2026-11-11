# supplybiz_api_client.api.NotificationsApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**notificationsControllerClear**](NotificationsApi.md#notificationscontrollerclear) | **DELETE** /api/v1/notifications |
[**notificationsControllerDevice**](NotificationsApi.md#notificationscontrollerdevice) | **PUT** /api/v1/me/devices/current |
[**notificationsControllerList**](NotificationsApi.md#notificationscontrollerlist) | **GET** /api/v1/notifications |
[**notificationsControllerPreferences**](NotificationsApi.md#notificationscontrollerpreferences) | **GET** /api/v1/me/notification-prefs |
[**notificationsControllerRead**](NotificationsApi.md#notificationscontrollerread) | **POST** /api/v1/notifications/read |
[**notificationsControllerSavePreferences**](NotificationsApi.md#notificationscontrollersavepreferences) | **PUT** /api/v1/me/notification-prefs |


# **notificationsControllerClear**
> NotificationMutationResponse notificationsControllerClear(idempotencyKey, role)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getNotificationsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final String role = role_example; // String |

try {
    final response = api.notificationsControllerClear(idempotencyKey, role);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerClear: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **role** | **String**|  | [optional]

### Return type

[**NotificationMutationResponse**](NotificationMutationResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerDevice**
> DevicePushResponse notificationsControllerDevice(idempotencyKey, devicePushInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getNotificationsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final DevicePushInput devicePushInput = ; // DevicePushInput |

try {
    final response = api.notificationsControllerDevice(idempotencyKey, devicePushInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **devicePushInput** | [**DevicePushInput**](DevicePushInput.md)|  |

### Return type

[**DevicePushResponse**](DevicePushResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerList**
> InboxResponse notificationsControllerList(role, category, limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getNotificationsApi();
final String role = role_example; // String |
final String category = category_example; // String |
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.notificationsControllerList(role, category, limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **role** | **String**|  | [optional]
 **category** | **String**|  | [optional]
 **limit** | **int**|  | [optional] [default to 50]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**InboxResponse**](InboxResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerPreferences**
> NotificationPreferences notificationsControllerPreferences()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getNotificationsApi();

try {
    final response = api.notificationsControllerPreferences();
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerPreferences: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**NotificationPreferences**](NotificationPreferences.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerRead**
> NotificationMutationResponse notificationsControllerRead(idempotencyKey, readNotifications)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getNotificationsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final ReadNotifications readNotifications = ; // ReadNotifications |

try {
    final response = api.notificationsControllerRead(idempotencyKey, readNotifications);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **readNotifications** | [**ReadNotifications**](ReadNotifications.md)|  |

### Return type

[**NotificationMutationResponse**](NotificationMutationResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerSavePreferences**
> NotificationPreferences notificationsControllerSavePreferences(idempotencyKey, notificationPreferences)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getNotificationsApi();
final String idempotencyKey = idempotencyKey_example; // String |
final NotificationPreferences notificationPreferences = ; // NotificationPreferences |

try {
    final response = api.notificationsControllerSavePreferences(idempotencyKey, notificationPreferences);
    print(response);
} on DioException catch (e) {
    print('Exception when calling NotificationsApi->notificationsControllerSavePreferences: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **notificationPreferences** | [**NotificationPreferences**](NotificationPreferences.md)|  |

### Return type

[**NotificationPreferences**](NotificationPreferences.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

