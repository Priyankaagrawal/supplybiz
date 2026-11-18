# supplybiz_api_client.api.VendorKhataApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**vendorKhataControllerAccounts**](VendorKhataApi.md#vendorkhatacontrolleraccounts) | **GET** /api/v1/vendor/khata |
[**vendorKhataControllerCollections**](VendorKhataApi.md#vendorkhatacontrollercollections) | **GET** /api/v1/vendor/khata/collections |
[**vendorKhataControllerConfirm**](VendorKhataApi.md#vendorkhatacontrollerconfirm) | **POST** /api/v1/vendor/payment-claims/{id}/confirm |
[**vendorKhataControllerDetailsGet**](VendorKhataApi.md#vendorkhatacontrollerdetailsget) | **GET** /api/v1/vendor/khata/payment-details |
[**vendorKhataControllerDetailsPublish**](VendorKhataApi.md#vendorkhatacontrollerdetailspublish) | **PATCH** /api/v1/vendor/khata/payment-details |
[**vendorKhataControllerEntries**](VendorKhataApi.md#vendorkhatacontrollerentries) | **GET** /api/v1/vendor/khata/{id}/entries |
[**vendorKhataControllerList**](VendorKhataApi.md#vendorkhatacontrollerlist) | **GET** /api/v1/vendor/payment-claims |
[**vendorKhataControllerOpening**](VendorKhataApi.md#vendorkhatacontrolleropening) | **POST** /api/v1/vendor/khata/{id}/opening |
[**vendorKhataControllerReject**](VendorKhataApi.md#vendorkhatacontrollerreject) | **POST** /api/v1/vendor/payment-claims/{id}/reject |
[**vendorKhataControllerReverse**](VendorKhataApi.md#vendorkhatacontrollerreverse) | **POST** /api/v1/vendor/ledger-entries/{id}/reverse |


# **vendorKhataControllerAccounts**
> VendorKhataList vendorKhataControllerAccounts(limit, offset, tab, q)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final int limit = 56; // int |
final int offset = 56; // int |
final String tab = tab_example; // String |
final String q = q_example; // String |

try {
    final response = api.vendorKhataControllerAccounts(limit, offset, tab, q);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerAccounts: $e\n');
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

[**VendorKhataList**](VendorKhataList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorKhataControllerCollections**
> VendorCollectionList vendorKhataControllerCollections(limit, offset, month)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final int limit = 56; // int |
final int offset = 56; // int |
final String month = month_example; // String | Calendar month YYYY-MM; defaults to server IST current month.

try {
    final response = api.vendorKhataControllerCollections(limit, offset, month);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerCollections: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 20]
 **offset** | **int**|  | [optional] [default to 0]
 **month** | **String**| Calendar month YYYY-MM; defaults to server IST current month. | [optional]

### Return type

[**VendorCollectionList**](VendorCollectionList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorKhataControllerConfirm**
> ClaimMutation vendorKhataControllerConfirm(id, idempotencyKey, khataVersion)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final KhataVersion khataVersion = ; // KhataVersion |

try {
    final response = api.vendorKhataControllerConfirm(id, idempotencyKey, khataVersion);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerConfirm: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **khataVersion** | [**KhataVersion**](KhataVersion.md)|  |

### Return type

[**ClaimMutation**](ClaimMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorKhataControllerDetailsGet**
> VendorPaymentDetails vendorKhataControllerDetailsGet()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();

try {
    final response = api.vendorKhataControllerDetailsGet();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerDetailsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**VendorPaymentDetails**](VendorPaymentDetails.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorKhataControllerDetailsPublish**
> PaymentPublicationAck vendorKhataControllerDetailsPublish(idempotencyKey, paymentPublicationInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final String idempotencyKey = idempotencyKey_example; // String |
final PaymentPublicationInput paymentPublicationInput = ; // PaymentPublicationInput |

try {
    final response = api.vendorKhataControllerDetailsPublish(idempotencyKey, paymentPublicationInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerDetailsPublish: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **paymentPublicationInput** | [**PaymentPublicationInput**](PaymentPublicationInput.md)|  |

### Return type

[**PaymentPublicationAck**](PaymentPublicationAck.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorKhataControllerEntries**
> KhataVendorEntries vendorKhataControllerEntries(id, limit, offset, month)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final String id = id_example; // String |
final int limit = 56; // int |
final int offset = 56; // int |
final String month = month_example; // String | Calendar month YYYY-MM; defaults to server IST current month.

try {
    final response = api.vendorKhataControllerEntries(id, limit, offset, month);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerEntries: $e\n');
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

# **vendorKhataControllerList**
> PaymentClaimList vendorKhataControllerList(limit, offset, status)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final int limit = 56; // int |
final int offset = 56; // int |
final String status = status_example; // String |

try {
    final response = api.vendorKhataControllerList(limit, offset, status);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
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

# **vendorKhataControllerOpening**
> LedgerAdjustmentAck vendorKhataControllerOpening(id, idempotencyKey, ledgerOpeningInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final LedgerOpeningInput ledgerOpeningInput = ; // LedgerOpeningInput |

try {
    final response = api.vendorKhataControllerOpening(id, idempotencyKey, ledgerOpeningInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerOpening: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **ledgerOpeningInput** | [**LedgerOpeningInput**](LedgerOpeningInput.md)|  |

### Return type

[**LedgerAdjustmentAck**](LedgerAdjustmentAck.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorKhataControllerReject**
> ClaimMutation vendorKhataControllerReject(id, idempotencyKey, claimRejection)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final ClaimRejection claimRejection = ; // ClaimRejection |

try {
    final response = api.vendorKhataControllerReject(id, idempotencyKey, claimRejection);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerReject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **claimRejection** | [**ClaimRejection**](ClaimRejection.md)|  |

### Return type

[**ClaimMutation**](ClaimMutation.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vendorKhataControllerReverse**
> LedgerAdjustmentAck vendorKhataControllerReverse(id, idempotencyKey, ledgerReversalInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getVendorKhataApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final LedgerReversalInput ledgerReversalInput = ; // LedgerReversalInput |

try {
    final response = api.vendorKhataControllerReverse(id, idempotencyKey, ledgerReversalInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendorKhataApi->vendorKhataControllerReverse: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **ledgerReversalInput** | [**LedgerReversalInput**](LedgerReversalInput.md)|  |

### Return type

[**LedgerAdjustmentAck**](LedgerAdjustmentAck.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

