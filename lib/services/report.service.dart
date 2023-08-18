import 'dart:convert';
import 'dart:io';
import 'package:atusum/config.dart';
import 'package:atusum/helpers/exception_helper.dart';
import 'package:atusum/models/report.dart';
import 'package:device_info/device_info.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:mobile_number/mobile_number.dart';

class ReportService {
  String _phoneUniqueIdentifier;
  String _mobileNumber;

  Future<List<Report>> getMyReports() async {
    try {
      _phoneUniqueIdentifier ??= await _getDeviceUniqueIdentifier();
      var body = <String, String>{'phoneId': _phoneUniqueIdentifier};
      final response = await http.post(Uri.parse(Config.url + 'report/find'),
          headers: Config.httpDefaultHeaders, body: jsonEncode(body));

      var rawReportList = jsonDecode(response.body) as List<dynamic>;
      List<Report> reportList = [];
      for (var r in rawReportList) {
        reportList.add(Report.fromJson(r));
      }

      reportList.sort((a, b) => b.date.compareTo(a.date));
      return reportList;
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }
    return [];
  }

  Future<String> _getDeviceUniqueIdentifier() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else {
      return null;
    }
  }

  Future<String> _getMobileNumber() async {
    if (Platform.isAndroid) {
      MobileNumber.listenPhonePermission((isPermissionGranted) async {
        if (isPermissionGranted) {
          _mobileNumber = await MobileNumber.mobileNumber;
          return _mobileNumber;
        } else {
          return "";
        }
      });
    }
    return "";
  }

  Future<bool> sendReport(Report r) async {
    try {
      _mobileNumber ??= await _getMobileNumber();
      r.phoneId = await _getDeviceUniqueIdentifier();
      var file = MultipartFile.fromBytes(
        await r.pickedImage.readAsBytes(),
        filename: "imagen",
      );

      var body = FormData.fromMap({
        'title': '',
        'bus': r.busId,
        "phoneId": r.phoneId,
        "description": r.description,
        "contactPhoneNumber": _mobileNumber,
        "img": file
      });

      var response = await Dio().post(Config.url + 'report', data: body);
      return response.statusCode == 200;
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }

    return false;
  }
}
