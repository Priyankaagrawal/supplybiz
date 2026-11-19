# supplybiz_api_client.api.AdminContentApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminContentControllerConfig**](AdminContentApi.md#admincontentcontrollerconfig) | **GET** /api/v1/admin/config |
[**adminContentControllerFaq**](AdminContentApi.md#admincontentcontrollerfaq) | **PUT** /api/v1/admin/faqs/{id} |
[**adminContentControllerFaqs**](AdminContentApi.md#admincontentcontrollerfaqs) | **GET** /api/v1/admin/faqs |
[**adminContentControllerHistory**](AdminContentApi.md#admincontentcontrollerhistory) | **GET** /api/v1/admin/legal |
[**adminContentControllerLegal**](AdminContentApi.md#admincontentcontrollerlegal) | **GET** /api/v1/admin/legal/{type} |
[**adminContentControllerPublish**](AdminContentApi.md#admincontentcontrollerpublish) | **PUT** /api/v1/admin/legal/{type} |
[**adminContentControllerSaveConfig**](AdminContentApi.md#admincontentcontrollersaveconfig) | **PUT** /api/v1/admin/config |


# **adminContentControllerConfig**
> AdminConfigResponse adminContentControllerConfig()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminContentApi();

try {
    final response = api.adminContentControllerConfig();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminContentControllerConfig: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AdminConfigResponse**](AdminConfigResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminContentControllerFaq**
> FaqRow adminContentControllerFaq(id, idempotencyKey, xCSRFToken, faqInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminContentApi();
final String id = id_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final FaqInput faqInput = ; // FaqInput |

try {
    final response = api.adminContentControllerFaq(id, idempotencyKey, xCSRFToken, faqInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminContentControllerFaq: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **faqInput** | [**FaqInput**](FaqInput.md)|  |

### Return type

[**FaqRow**](FaqRow.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminContentControllerFaqs**
> FaqList adminContentControllerFaqs(offset, topic)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminContentApi();
final int offset = 56; // int |
final String topic = topic_example; // String |

try {
    final response = api.adminContentControllerFaqs(offset, topic);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminContentControllerFaqs: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **offset** | **int**|  | [optional] [default to 0]
 **topic** | **String**|  | [optional]

### Return type

[**FaqList**](FaqList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminContentControllerHistory**
> LegalList adminContentControllerHistory()



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminContentApi();

try {
    final response = api.adminContentControllerHistory();
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminContentControllerHistory: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**LegalList**](LegalList.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminContentControllerLegal**
> LegalRow adminContentControllerLegal(type, version)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminContentApi();
final String type = type_example; // String |
final String version = version_example; // String |

try {
    final response = api.adminContentControllerLegal(type, version);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminContentControllerLegal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String**|  |
 **version** | **String**|  | [optional]

### Return type

[**LegalRow**](LegalRow.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminContentControllerPublish**
> LegalRow adminContentControllerPublish(type, idempotencyKey, xCSRFToken, legalInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminContentApi();
final String type = type_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final LegalInput legalInput = ; // LegalInput |

try {
    final response = api.adminContentControllerPublish(type, idempotencyKey, xCSRFToken, legalInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminContentControllerPublish: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String**|  |
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **legalInput** | [**LegalInput**](LegalInput.md)|  |

### Return type

[**LegalRow**](LegalRow.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminContentControllerSaveConfig**
> AdminConfigResponse adminContentControllerSaveConfig(idempotencyKey, xCSRFToken, configInput)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getAdminContentApi();
final String idempotencyKey = idempotencyKey_example; // String |
final String xCSRFToken = xCSRFToken_example; // String |
final ConfigInput configInput = ; // ConfigInput |

try {
    final response = api.adminContentControllerSaveConfig(idempotencyKey, xCSRFToken, configInput);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminContentApi->adminContentControllerSaveConfig: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**|  |
 **xCSRFToken** | **String**|  |
 **configInput** | [**ConfigInput**](ConfigInput.md)|  |

### Return type

[**AdminConfigResponse**](AdminConfigResponse.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

