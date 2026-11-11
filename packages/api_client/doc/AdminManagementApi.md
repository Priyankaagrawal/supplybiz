# supplybiz_api_client.api.AdminManagementApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**managementControllerBadges**](AdminManagementApi.md#managementcontrollerbadges) | **PATCH** /api/v1/admin/vendors/{id} |
[**managementControllerBlock**](AdminManagementApi.md#managementcontrollerblock) | **POST** /api/v1/admin/customers/{id}/block |
[**managementControllerCustomer**](AdminManagementApi.md#managementcontrollercustomer) | **GET** /api/v1/admin/customers/{id} |
[**managementControllerCustomers**](AdminManagementApi.md#managementcontrollercustomers) | **GET** /api/v1/admin/customers |
[**managementControllerReinstate**](AdminManagementApi.md#managementcontrollerreinstate) | **POST** /api/v1/admin/vendors/{id}/reinstate |
[**managementControllerSuspend**](AdminManagementApi.md#managementcontrollersuspend) | **POST** /api/v1/admin/vendors/{id}/suspend |
[**managementControllerUnblock**](AdminManagementApi.md#managementcontrollerunblock) | **POST** /api/v1/admin/customers/{id}/unblock |
[**managementControllerVendor**](AdminManagementApi.md#managementcontrollervendor) | **GET** /api/v1/admin/vendors/{id} |
[**managementControllerVendors**](AdminManagementApi.md#managementcontrollervendors) | **GET** /api/v1/admin/vendors |


# **managementControllerBadges**
> ManagementResponse managementControllerBadges(id, idempotencyKey, xCSRFToken, badgeInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final BadgeInput badgeInput = ; // BadgeInput |

try {
    final response = api.managementControllerBadges(id, idempotencyKey, xCSRFToken, badgeInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerBadges: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **badgeInput** | [**BadgeInput**](BadgeInput.md)|  |

### Return type

[**ManagementResponse**](ManagementResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **managementControllerBlock**
> ManagementResponse managementControllerBlock(id, idempotencyKey, xCSRFToken, managementInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final ManagementInput managementInput = ; // ManagementInput |

try {
    final response = api.managementControllerBlock(id, idempotencyKey, xCSRFToken, managementInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerBlock: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **managementInput** | [**ManagementInput**](ManagementInput.md)|  |

### Return type

[**ManagementResponse**](ManagementResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **managementControllerCustomer**
> ManagedCustomer managementControllerCustomer(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String id = id_example; // String |

try {
    final response = api.managementControllerCustomer(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerCustomer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**ManagedCustomer**](ManagedCustomer.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **managementControllerCustomers**
> ManagedCustomerList managementControllerCustomers(search, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String search = search_example; // String |
final int offset = 56; // int |

try {
    final response = api.managementControllerCustomers(search, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**|  | [optional]
 **offset** | **int**|  | [optional]

### Return type

[**ManagedCustomerList**](ManagedCustomerList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **managementControllerReinstate**
> ManagementResponse managementControllerReinstate(id, idempotencyKey, xCSRFToken, managementInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final ManagementInput managementInput = ; // ManagementInput |

try {
    final response = api.managementControllerReinstate(id, idempotencyKey, xCSRFToken, managementInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerReinstate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **managementInput** | [**ManagementInput**](ManagementInput.md)|  |

### Return type

[**ManagementResponse**](ManagementResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **managementControllerSuspend**
> ManagementResponse managementControllerSuspend(id, idempotencyKey, xCSRFToken, managementInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final ManagementInput managementInput = ; // ManagementInput |

try {
    final response = api.managementControllerSuspend(id, idempotencyKey, xCSRFToken, managementInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerSuspend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **managementInput** | [**ManagementInput**](ManagementInput.md)|  |

### Return type

[**ManagementResponse**](ManagementResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **managementControllerUnblock**
> ManagementResponse managementControllerUnblock(id, idempotencyKey, xCSRFToken, managementInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final ManagementInput managementInput = ; // ManagementInput |

try {
    final response = api.managementControllerUnblock(id, idempotencyKey, xCSRFToken, managementInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerUnblock: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **managementInput** | [**ManagementInput**](ManagementInput.md)|  |

### Return type

[**ManagementResponse**](ManagementResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **managementControllerVendor**
> ManagedVendorDetail managementControllerVendor(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String id = id_example; // String |

try {
    final response = api.managementControllerVendor(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerVendor: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**ManagedVendorDetail**](ManagedVendorDetail.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **managementControllerVendors**
> ManagedVendorList managementControllerVendors(search, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminManagementApi();
final String search = search_example; // String |
final int offset = 56; // int |

try {
    final response = api.managementControllerVendors(search, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminManagementApi->managementControllerVendors: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**|  | [optional]
 **offset** | **int**|  | [optional]

### Return type

[**ManagedVendorList**](ManagedVendorList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

