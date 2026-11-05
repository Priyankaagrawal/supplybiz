# supplybiz_api_client.api.KycApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminKycControllerDecide**](KycApi.md#adminkyccontrollerdecide) | **POST** /api/v1/admin/kyc/{id}/decision |
[**adminKycControllerDetail**](KycApi.md#adminkyccontrollerdetail) | **GET** /api/v1/admin/kyc/{id} |
[**adminKycControllerQueue**](KycApi.md#adminkyccontrollerqueue) | **GET** /api/v1/admin/kyc |
[**kycControllerNotices**](KycApi.md#kyccontrollernotices) | **GET** /api/v1/vendor/kyc/notices |
[**kycControllerStatus**](KycApi.md#kyccontrollerstatus) | **GET** /api/v1/vendor/kyc |
[**kycControllerSubmit**](KycApi.md#kyccontrollersubmit) | **POST** /api/v1/vendor/kyc |


# **adminKycControllerDecide**
> KycResponse adminKycControllerDecide(id, idempotencyKey, xCSRFToken, kycDecisionDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getKycApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final KycDecisionDto kycDecisionDto = ; // KycDecisionDto |

try {
    final response = api.adminKycControllerDecide(id, idempotencyKey, xCSRFToken, kycDecisionDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling KycApi->adminKycControllerDecide: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **kycDecisionDto** | [**KycDecisionDto**](KycDecisionDto.md)|  |

### Return type

[**KycResponse**](KycResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminKycControllerDetail**
> KycResponse adminKycControllerDetail(id)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getKycApi();
final String id = id_example; // String |

try {
    final response = api.adminKycControllerDetail(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling KycApi->adminKycControllerDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**KycResponse**](KycResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminKycControllerQueue**
> KycPage adminKycControllerQueue(beforeId)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getKycApi();
final String beforeId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |

try {
    final response = api.adminKycControllerQueue(beforeId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling KycApi->adminKycControllerQueue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **beforeId** | **String**|  | [optional]

### Return type

[**KycPage**](KycPage.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **kycControllerNotices**
> List<KycNotice> kycControllerNotices()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getKycApi();

try {
    final response = api.kycControllerNotices();
    print(response);
} on DioException catch (e) {
    print('Exception when calling KycApi->kycControllerNotices: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List&lt;KycNotice&gt;**](KycNotice.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **kycControllerStatus**
> KycResponse kycControllerStatus()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getKycApi();

try {
    final response = api.kycControllerStatus();
    print(response);
} on DioException catch (e) {
    print('Exception when calling KycApi->kycControllerStatus: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**KycResponse**](KycResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **kycControllerSubmit**
> KycResponse kycControllerSubmit(idempotencyKey, kycSubmissionDto)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getKycApi();
final String idempotencyKey = idempotencyKey_example; // String |
final KycSubmissionDto kycSubmissionDto = ; // KycSubmissionDto |

try {
    final response = api.kycControllerSubmit(idempotencyKey, kycSubmissionDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling KycApi->kycControllerSubmit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **kycSubmissionDto** | [**KycSubmissionDto**](KycSubmissionDto.md)|  |

### Return type

[**KycResponse**](KycResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

