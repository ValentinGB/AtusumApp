class PlacePrediction {
  String description;
  String placeId;
  String reference;
  String mainText;
  String secondaryText;

  PlacePrediction({this.description, this.placeId, this.reference});

  PlacePrediction.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    placeId = json['place_id'];
    reference = json['reference'];

    if (json['structured_formatting'] != null) {
      mainText = json['structured_formatting']['main_text'];
      secondaryText = json['structured_formatting']['secondary_text'];
    }
  }
}
