import 'dart:async';
import 'dart:convert';
import 'package:atusum/helpers/exception_helper.dart';
import 'package:atusum/helpers/loader.helper.dart';
import 'package:atusum/models/bus_route.dart';
import 'package:atusum/models/publicity.dart';
import 'package:atusum/widgets/timer_button.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class PublicityService {
  Future<Publicity> getPublicityForRoute(BusRoute route) async {
    try {
      var body = <String, String>{'routeId': route.id};
      final response = await http.post(
          Uri.parse(Config.url + 'publicity/findByRoute'),
          headers: Config.httpDefaultHeaders,
          body: jsonEncode(body));

      if (response.body == "null") return null;
      return Publicity.fromJson(jsonDecode(response.body));
    } catch (ex) {
      ExceptionHelper.handleException(ex);
    }
    return null;
  }

  Future<void> showPublicityForRoute(
      BusRoute route, BuildContext context) async {
    LoaderHelper.showLoader(context);
    Publicity routePublicity = await getPublicityForRoute(route);
    Navigator.of(context).pop();
    if (routePublicity == null) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          backgroundColor: const Color.fromRGBO(0, 0, 0, 0.2),
          child: WillPopScope(
            onWillPop: () => Future.value(false),
            child: _contentBox(context, routePublicity),
          ),
        );
      },
    );
  }

  Stack _contentBox(context, Publicity publicity) {
    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.network(
                  Config.url + 'public/publicity/${publicity.imgName}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      publicity.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primaryBase,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      publicity.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: ColorPalette.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TimerButton(
                        resetTimerOnPressed: true,
                        label: 'Continuar',
                        timeOutInSeconds: 5,
                        disabledColor: Colors.white,
                        activeTextStyle: const TextStyle(
                          color: Colors.white,
                        ),
                        disabledTextStyle: const TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.5),
                        ),
                        color: ColorPalette.primaryBase,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
