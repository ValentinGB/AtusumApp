import 'dart:async';
// import 'dart:convert';
import 'package:atusum/config.dart';
// import 'package:atusum/helpers/exception_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
// import 'package:http/http.dart' as http;

class PlacesService {
  // final _authority = 'maps.googleapis.com';
  // final _unencodedPath = 'maps/api/place/queryautocomplete/json';
  // String _sessionToken = "ABCD";
  // DateTime _tokenLastUse = DateTime.now();

  // void _refreshToken() {
  // _sessionToken = "";
  // }
  Future<LatLng> getPlaceLatLng(String placeId) async {
    try {
      var gPlace = GooglePlace(Config.mapsApiKey);
      var result = await gPlace.details.get(placeId, fields: "name,geometry");
      if (result?.result?.geometry?.location != null) {
        return LatLng(result.result.geometry.location.lat,
            result.result.geometry.location.lng);
      }
      return null;
    } catch (ex) {
      return null;
    }
  }

  Future<AutocompleteResponse> searchPlace(
      String searchText, LatLng userLocation) async {
    var gPlace = GooglePlace(Config.mapsApiKey);
    var result = await gPlace.autocomplete.get(searchText,
        location: LatLon(userLocation.latitude, userLocation.longitude),
        radius: 8000,
        strictbounds: true);

    return result;
    //   try {
    //     if (_tokenLastUse.difference(DateTime.now()).inSeconds < -10) {
    //       _refreshToken();
    //     }

    //     _tokenLastUse = DateTime.now();

    //     searchText = searchText.trimRight().trimLeft();
    //     Map<String, String> queryParameters = {
    //       'input': searchText,
    //       'key': Config.mapsApiKey,
    //       'sessionToken': _sessionToken
    //     };
    //     if (userLocation != null) {
    //       queryParameters['latitude'] = userLocation.latitude.toString();
    //       queryParameters['longitude'] = userLocation.longitude.toString();
    //       queryParameters['radius'] = '5000';
    //       queryParameters['strictbounds'] = '1';
    //     }

    //     var uri = Uri.https(_authority, _unencodedPath, queryParameters);
    //     var headers = <String, String>{};
    //     final response = await http
    //         .get(uri, headers: headers)
    //         .timeout(const Duration(milliseconds: 1500));
    //     return AutoCompleteResponse.fromJson(jsonDecode(response.body));
    //   } catch (ex) {
    //     ExceptionHelper.handleException(ex);
    //     return null;
    //   }
  }
}
