import 'dart:convert';

import 'package:http/http.dart' as http;

final GeneralApiService httpService = GeneralApiService();

class GeneralApiService {
  final JsonDecoder _decoder = const JsonDecoder();
  final JsonEncoder _encoder = const JsonEncoder();

  Map<String, String> headers = {"Content-Type": "application/json"};
  Map<String, String> urlEncodedHeaders = {
    "Content-Type": "application/x-www-form-urlencoded"
  };
  Map<String, String> formDataHeaders = {"Content-Type": "multipart/form-data"};
  Map<String, String> cookies = {};

  void _updateCookie(http.Response response) {
    String? allSetCookie = response.headers['set-cookie'];

    if (allSetCookie != null) {
      var setCookies = allSetCookie.split(',');

      for (var setCookie in setCookies) {
        var cookies = setCookie.split(';');

        for (var cookie in cookies) {
          _setCookie(cookie);
        }
      }

      headers['cookie'] = _generateCookieHeader();
      // downloadingHeaders["cookie"] = _generateCookieHeader();
      urlEncodedHeaders['cookie'] = _generateCookieHeader();
      formDataHeaders['cookie'] = _generateCookieHeader();
    }
  }

  void _setCookie(String? rawCookie) {
    if (rawCookie != null) {
      var keyValue = rawCookie.split('=');
      if (keyValue.length == 2) {
        var key = keyValue[0].trim();
        var value = keyValue[1];

        // ignore keys that aren't cookies
        if (key == 'path' || key == 'expires') return;

        cookies[key] = value;
        // defaultCookies[key] = value;
      }
    }
  }

  String _generateCookieHeader() {
    String cookie = "";

    for (var key in cookies.keys) {
      if (cookie.isNotEmpty) cookie += ";";
      cookie += "$key=${cookies[key]!}";
    }

    return cookie;
  }

  Future<dynamic> get(String url) {
    return http
        .get(Uri.parse(url), headers: headers)
        .then((http.Response response) {
      final String res = utf8.decode(response.bodyBytes);
      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode == 200 || statusCode == 400) {
        return _decoder.convert(res);
      } else {
        throw Exception("Error while fetching data");
      }
    });
  }

  Future<dynamic> getHtml(String url) {
    return http
        .get(Uri.parse(url), headers: headers)
        .then((http.Response response) {
      // final String res = utf8.decode(response.bodyBytes);
      final int statusCode = response.statusCode;
      _updateCookie(response);

      if (statusCode == 200 || statusCode == 400) {
        return response.headers["content-location"];
      } else {
        throw Exception("Error while fetching data");
      }
    });
  }

  Future<dynamic> post(String url, {body, encoding}) {
    String msg = body == null ? "{}" : _encoder.convert(body);
    //print(headers);
    return http
        .post(Uri.parse(url), body: msg, headers: headers, encoding: encoding)
        .then((http.Response response) {
      final String res = utf8.decode(response.bodyBytes);

      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode == 200 || statusCode == 400) {
        return _decoder.convert(res);
      } else {
        print(statusCode);
        throw Exception("Error while fetching data");
      }
    });
  }

  Future<dynamic> postURLEncoded(String url, {body, encoding}) {
    String msg = body == null ? "{}" : _encoder.convert(body);
    // print(msg);
    //print(urlEncodedHeaders);
    return http
        .post(Uri.parse(url),
            body: msg, headers: urlEncodedHeaders, encoding: encoding)
        .then((http.Response response) {
      final String res = utf8.decode(response.bodyBytes);

      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode == 200 || statusCode == 400) {
        return _decoder.convert(res);
      } else {
        print(statusCode);
        throw Exception("Error while fetching data");
      }
    });
  }

  Future<dynamic> put(String url, {body, encoding}) {
    return http
        .put(Uri.parse(url),
            body: _encoder.convert(body), headers: headers, encoding: encoding)
        .then((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode < 200 || statusCode > 400) {
        throw Exception("Error while fetching data");
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> postForm(String url,
      {Map<String, dynamic>? body,
      List<http.MultipartFile>? s,
      encoding}) async {
    // print("POST $url with body $body and headers $headers");
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    )..headers.addAll(formDataHeaders);
    if (body != null) {
      for (var key in body.keys) {
        request.fields[key] = body[key].toString();
      }
    }
    if (s != null) {
      for (var e in s) {
        request.files.add(e);
      }
    }
    var streamedResponse = await request.send();
    var result = await http.Response.fromStream(streamedResponse);

    final String res = utf8.decode(result.bodyBytes);
    final int statusCode = result.statusCode;

    _updateCookie(result);

    if (statusCode < 200 || statusCode > 400) {
      throw Exception("Error while fetching data");
    }
    return _decoder.convert(res);
  }
}
