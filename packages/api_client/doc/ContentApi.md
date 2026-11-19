# supplybiz_api_client.api.ContentApi

## Load the API package
```dart
import 'package:supplybiz_api_client/api.dart';
```

All URIs are relative to *http://localhost:3000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**contentControllerFaqs**](ContentApi.md#contentcontrollerfaqs) | **GET** /api/v1/content/faqs |
[**contentControllerLegal**](ContentApi.md#contentcontrollerlegal) | **GET** /api/v1/content/legal/{type} |


# **contentControllerFaqs**
> FaqList contentControllerFaqs(offset, topic)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getContentApi();
final int offset = 56; // int |
final String topic = topic_example; // String |

try {
    final response = api.contentControllerFaqs(offset, topic);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->contentControllerFaqs: $e\n');
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

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **contentControllerLegal**
> LegalRow contentControllerLegal(type, version)



### Example
```dart
import 'package:supplybiz_api_client/api.dart';

final api = SupplybizApiClient().getContentApi();
final String type = type_example; // String |
final String version = version_example; // String |

try {
    final response = api.contentControllerLegal(type, version);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ContentApi->contentControllerLegal: $e\n');
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

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

