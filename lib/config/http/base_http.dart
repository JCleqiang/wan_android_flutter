import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';
import 'package:wan_android_flutter/config/http/http_exception.dart';
import 'package:wan_android_flutter/config/http/response_data.dart';
import 'package:wan_android_flutter/util/PlatformUtils.dart';

class BaseHttp extends DioForNative {
  BaseHttp([BaseOptions options]):super(options){
    // 添加拦截器
    interceptors.add(HeaderInterceptor());
  }
}

// 每个 Dio 实例都可以添加任意多个拦截器，他们组成一个队列，拦截
// 器队列的执行顺序是FIFO。通过拦截器你可以在请求之前或响应之后(但还
// 没有被 then 或 catchError处理)做一些统一的预处理操作
class HeaderInterceptor extends InterceptorsWrapper {
  @override
  onRequest(RequestOptions options) async {
    options.connectTimeout = 1000 * 45;
    options.receiveTimeout = 1000 * 45;

    var appVersion = await PlatformUtils.getAppVersion();
    var version = Map()
      ..addAll({
        'appVerison': appVersion,
      });
    options.headers['version'] = version;
    options.headers['platform'] = Platform.operatingSystem;

    // 在请求被发送之前做一些事情
    return options;
  }

  @override
  Future onResponse(Response response) async {
    print('---api-response--->resp2----->${response.data}');
    BaseResponseData respData = ResponseData.fromJson(response.data);
    if (respData.success) {
      response.data = respData.data;
      return BaseHttp().resolve(response);
    }

    if (respData.code == -1001) {
      // 如果cookie过期,需要清除本地存储的登录信息
      // StorageManager.localStorage.deleteItem(UserModel.keyUser);
      throw const UnAuthorizedException(); // 需要登录
    }

    throw NotSuccessException.fromRespData(respData);
  }
}

