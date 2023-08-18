import 'package:atusum/models/places/place_prediction.dart';

class AutoCompleteResponse {
  String status;
  List<PlacePrediction> predictions;

  AutoCompleteResponse({this.status, this.predictions});

  AutoCompleteResponse.fromJson(Map<String, dynamic> json) {
    status = json['active'];
    predictions = [];

    if (json['predictions'] != null) {
      var rawPredictions = json['predictions'];
      for (var rp in rawPredictions) {
        predictions.add(PlacePrediction.fromJson(rp));
      }
    }
  }
}
