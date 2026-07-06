import 'package:dio/dio.dart';

/// 后端业务异常（对应 {ok:false, error:{code,message}}）。
class ApiException implements Exception {
  ApiException(this.statusCode, this.code, this.message);
  final int statusCode;
  final String code;
  final String message;
  @override
  String toString() => '[$statusCode] $code · $message';
}

/// 光屿 node-server 的 HTTP 客户端（dio 封装）。
///
/// 架构说明：App 只跟 node-server 的接口对话，**不直连数据库**。
/// baseUrl 默认 iOS 模拟器可达 Mac 本机的 localhost；
/// 真机/Android 模拟器需改成局域网 IP（如 http://192.168.x.x:3000）。
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String baseUrl = 'http://localhost:3000';
  String? _token;
  String? get token => _token;
  bool get isLoggedIn => _token != null;
  void setToken(String? t) => _token = t;
  void logout() => _token = null;

  late final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      // 业务错误码（4xx）由我们自己解析，不让 dio 直接抛网络异常
      validateStatus: (s) => s != null && s < 500,
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = baseUrl;
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );

  /// 统一解包 {ok,data}；非 ok 抛 ApiException。
  Future<dynamic> _unwrap(Future<Response<dynamic>> req) async {
    try {
      final resp = await req;
      final body = resp.data;
      if (body is Map && body['ok'] == true) return body['data'];
      if (body is Map && body['error'] is Map) {
        final e = body['error'] as Map;
        throw ApiException(
          resp.statusCode ?? 0,
          '${e['code'] ?? 'ERROR'}',
          '${e['message'] ?? '请求失败'}',
        );
      }
      throw ApiException(resp.statusCode ?? 0, 'BAD_RESPONSE', '响应格式异常');
    } on DioException catch (e) {
      throw ApiException(
        e.response?.statusCode ?? 0,
        'NETWORK',
        e.message ?? '网络错误（server 没起？baseUrl 对吗？）',
      );
    }
  }

  Future<Map<String, dynamic>> _map(Future<Response<dynamic>> req) async =>
      Map<String, dynamic>.from(await _unwrap(req) as Map);

  // ---- 接口 ----
  Future<Map<String, dynamic>> health() => _map(_dio.get('/health'));

  Future<Map<String, dynamic>> registerWithPassword(
      String phone, String password) async {
    final data = await _map(
      _dio.post('/auth/phone/register',
          data: {'phone': phone, 'password': password}),
    );
    _token = data['token'] as String?;
    return data;
  }

  Future<Map<String, dynamic>> loginWithPassword(
      String phone, String password) async {
    final data = await _map(
      _dio.post('/auth/phone/password-login',
          data: {'phone': phone, 'password': password}),
    );
    _token = data['token'] as String?;
    return data;
  }

  /// 短信验证码登录（预留，短信服务接入后启用）
  Future<Map<String, dynamic>> sendPhoneCode(String phone) =>
      _map(_dio.post('/auth/phone/code', data: {'phone': phone}));

  /// 短信验证码登录（预留，短信服务接入后启用）
  Future<Map<String, dynamic>> phoneLogin(String phone, String code) async {
    final data = await _map(
      _dio.post('/auth/phone/login', data: {'phone': phone, 'code': code}),
    );
    _token = data['token'] as String?;
    return data;
  }

  Future<Map<String, dynamic>> wechatLogin(String code) async {
    final data = await _map(_dio.post('/auth/wechat', data: {'code': code}));
    _token = data['token'] as String?;
    return data;
  }

  Future<Map<String, dynamic>> usage() => _map(_dio.get('/usage/me'));

  Future<Map<String, dynamic>> consume() => _map(_dio.post('/usage/consume'));

  Future<List<dynamic>> plans() async =>
      (await _map(_dio.get('/billing/plans')))['plans'] as List<dynamic>;

  Future<Map<String, dynamic>> createOrder(String planId) =>
      _map(_dio.post('/billing/orders', data: {'planId': planId}));

  Future<Map<String, dynamic>> mockPay(String orderId) =>
      _map(_dio.post('/billing/orders/$orderId/mock-pay'));
}
