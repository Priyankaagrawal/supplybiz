# supplybiz_api_client.api.CustomerKhataApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**customerKhataControllerClaim**](CustomerKhataApi.md#customerkhatacontrollerclaim) | **POST** /api/v1/customer/khata/vendors/{id}/claims |
[**customerKhataControllerClaimList**](CustomerKhataApi.md#customerkhatacontrollerclaimlist) | **GET** /api/v1/customer/khata/vendors/{id}/claims |
[**customerKhataControllerContactCreate**](CustomerKhataApi.md#customerkhatacontrollercontactcreate) | **POST** /api/v1/customer/personal-contacts |
[**customerKhataControllerContactDelete**](CustomerKhataApi.md#customerkhatacontrollercontactdelete) | **DELETE** /api/v1/customer/personal-contacts/{id} |
[**customerKhataControllerContactGet**](CustomerKhataApi.md#customerkhatacontrollercontactget) | **GET** /api/v1/customer/personal-contacts/{id} |
[**customerKhataControllerContactPatch**](CustomerKhataApi.md#customerkhatacontrollercontactpatch) | **PATCH** /api/v1/customer/personal-contacts/{id} |
[**customerKhataControllerContacts**](CustomerKhataApi.md#customerkhatacontrollercontacts) | **GET** /api/v1/customer/personal-contacts |
[**customerKhataControllerEntries**](CustomerKhataApi.md#customerkhatacontrollerentries) | **GET** /api/v1/customer/khata/vendors/{id}/entries |
[**customerKhataControllerEntryCreate**](CustomerKhataApi.md#customerkhatacontrollerentrycreate) | **POST** /api/v1/customer/personal-entries |
[**customerKhataControllerEntryDelete**](CustomerKhataApi.md#customerkhatacontrollerentrydelete) | **DELETE** /api/v1/customer/personal-entries/{id} |
[**customerKhataControllerEntryGet**](CustomerKhataApi.md#customerkhatacontrollerentryget) | **GET** /api/v1/customer/personal-entries/{id} |
[**customerKhataControllerEntryPatch**](CustomerKhataApi.md#customerkhatacontrollerentrypatch) | **PATCH** /api/v1/customer/personal-entries/{id} |
[**customerKhataControllerOptions**](CustomerKhataApi.md#customerkhatacontrolleroptions) | **GET** /api/v1/customer/khata/vendors/{id}/settlement-options |
[**customerKhataControllerPersonalEntries**](CustomerKhataApi.md#customerkhatacontrollerpersonalentries) | **GET** /api/v1/customer/personal-entries |
[**customerKhataControllerSummary**](CustomerKhataApi.md#customerkhatacontrollersummary) | **GET** /api/v1/customer/khata/summary |


# **customerKhataControllerClaim**
> ClaimMutation customerKhataControllerClaim(id, idempotencyKey, paymentClaimInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final PaymentClaimInput paymentClaimInput = ; // PaymentClaimInput |

try {
    final response = api.customerKhataControllerClaim(id, idempotencyKey, paymentClaimInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerClaim: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **paymentClaimInput** | [**PaymentClaimInput**](PaymentClaimInput.md)|  |

### Return type

[**ClaimMutation**](ClaimMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerClaimList**
> PaymentClaimList customerKhataControllerClaimList(id, limit, offset, status)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |
final int limit = 56; // int |
final int offset = 56; // int |
final String status = status_example; // String |

try {
    final response = api.customerKhataControllerClaimList(id, limit, offset, status);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerClaimList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]
 **status** | **String**|  | [optional]

### Return type

[**PaymentClaimList**](PaymentClaimList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerContactCreate**
> PersonalMutation customerKhataControllerContactCreate(idempotencyKey, personalContactInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String idempotencyKey = idempotencyKey_example; // String |
final PersonalContactInput personalContactInput = ; // PersonalContactInput |

try {
    final response = api.customerKhataControllerContactCreate(idempotencyKey, personalContactInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerContactCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **personalContactInput** | [**PersonalContactInput**](PersonalContactInput.md)|  |

### Return type

[**PersonalMutation**](PersonalMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerContactDelete**
> PersonalMutation customerKhataControllerContactDelete(id, idempotencyKey, khataVersion)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final KhataVersion khataVersion = ; // KhataVersion |

try {
    final response = api.customerKhataControllerContactDelete(id, idempotencyKey, khataVersion);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerContactDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **khataVersion** | [**KhataVersion**](KhataVersion.md)|  |

### Return type

[**PersonalMutation**](PersonalMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerContactGet**
> PersonalContactRecord customerKhataControllerContactGet(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |

try {
    final response = api.customerKhataControllerContactGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerContactGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**PersonalContactRecord**](PersonalContactRecord.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerContactPatch**
> PersonalMutation customerKhataControllerContactPatch(id, idempotencyKey, personalContactPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final PersonalContactPatch personalContactPatch = ; // PersonalContactPatch |

try {
    final response = api.customerKhataControllerContactPatch(id, idempotencyKey, personalContactPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerContactPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **personalContactPatch** | [**PersonalContactPatch**](PersonalContactPatch.md)|  |

### Return type

[**PersonalMutation**](PersonalMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerContacts**
> PersonalContactList customerKhataControllerContacts(limit, offset)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final int limit = 56; // int |
final int offset = 56; // int |

try {
    final response = api.customerKhataControllerContacts(limit, offset);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerContacts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]

### Return type

[**PersonalContactList**](PersonalContactList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerEntries**
> KhataVendorEntries customerKhataControllerEntries(id, limit, offset, month)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |
final int limit = 56; // int |
final int offset = 56; // int |
final String month = month_example; // String | Calendar month YYYY-MM; defaults to server IST current month.

try {
    final response = api.customerKhataControllerEntries(id, limit, offset, month);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerEntries: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]
 **month** | **String**| Calendar month YYYY-MM; defaults to server IST current month. | [optional]

### Return type

[**KhataVendorEntries**](KhataVendorEntries.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerEntryCreate**
> PersonalMutation customerKhataControllerEntryCreate(idempotencyKey, personalEntryInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String idempotencyKey = idempotencyKey_example; // String |
final PersonalEntryInput personalEntryInput = ; // PersonalEntryInput |

try {
    final response = api.customerKhataControllerEntryCreate(idempotencyKey, personalEntryInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerEntryCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **personalEntryInput** | [**PersonalEntryInput**](PersonalEntryInput.md)|  |

### Return type

[**PersonalMutation**](PersonalMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerEntryDelete**
> PersonalMutation customerKhataControllerEntryDelete(id, idempotencyKey, khataVersion)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final KhataVersion khataVersion = ; // KhataVersion |

try {
    final response = api.customerKhataControllerEntryDelete(id, idempotencyKey, khataVersion);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerEntryDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **khataVersion** | [**KhataVersion**](KhataVersion.md)|  |

### Return type

[**PersonalMutation**](PersonalMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerEntryGet**
> PersonalEntryRecord customerKhataControllerEntryGet(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |

try {
    final response = api.customerKhataControllerEntryGet(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerEntryGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**PersonalEntryRecord**](PersonalEntryRecord.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerEntryPatch**
> PersonalMutation customerKhataControllerEntryPatch(id, idempotencyKey, personalEntryPatch)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final PersonalEntryPatch personalEntryPatch = ; // PersonalEntryPatch |

try {
    final response = api.customerKhataControllerEntryPatch(id, idempotencyKey, personalEntryPatch);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerEntryPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **personalEntryPatch** | [**PersonalEntryPatch**](PersonalEntryPatch.md)|  |

### Return type

[**PersonalMutation**](PersonalMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerOptions**
> CustomerSettlementOptions customerKhataControllerOptions(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final String id = id_example; // String |

try {
    final response = api.customerKhataControllerOptions(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerOptions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**CustomerSettlementOptions**](CustomerSettlementOptions.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerPersonalEntries**
> PersonalEntryList customerKhataControllerPersonalEntries(limit, offset, contactId, month)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final int limit = 56; // int |
final int offset = 56; // int |
final String contactId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String month = month_example; // String |

try {
    final response = api.customerKhataControllerPersonalEntries(limit, offset, contactId, month);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerPersonalEntries: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]
 **contactId** | **String**|  | [optional]
 **month** | **String**|  | [optional]

### Return type

[**PersonalEntryList**](PersonalEntryList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **customerKhataControllerSummary**
> KhataSummary customerKhataControllerSummary(limit, offset, tab, q)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getCustomerKhataApi();
final int limit = 56; // int |
final int offset = 56; // int |
final String tab = tab_example; // String |
final String q = q_example; // String |

try {
    final response = api.customerKhataControllerSummary(limit, offset, tab, q);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CustomerKhataApi->customerKhataControllerSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]
 **tab** | **String**|  | [optional]
 **q** | **String**|  | [optional]

### Return type

[**KhataSummary**](KhataSummary.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

