import 'dart:developer';

import 'general_api_service.dart';

class AuthService {
  // Future<LoginResponse> login(LoginRequest requestModel) async {
  //   try {
  //     final response =
  //         await httpService.post(Global.loginUrl, body: requestModel.toJson());
  //     LoginResponse loginResponse = LoginResponse.fromJson(response);
  //     return loginResponse;
  //   } on Exception catch (e) {
  //     log(e.toString());
  //     return LoginResponse();
  //   }
  // }

  // Future<String> resetPassword(ResetPasswordRequest requestModel) async {
  //   try {
  //     final response = await httpService.post(Global.resetPasswordUrl,
  //         body: requestModel.toJson());
  //     if (response[fActionResult] == "OK") {
  //       return response[fActionResult];
  //     } else {
  //       return response[fErrorMessage];
  //     }
  //   } on Exception catch (e) {
  //     log(e.toString());
  //     return "FAIL";
  //   }
  // }
}
