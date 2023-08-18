class Publicity {
  String id;
  bool active;
  String title;
  String description;
  String imgName;

  Publicity({
    this.active,
    this.title,
    this.description,
    this.imgName,
  });

  Publicity.fromJson(Map<String, dynamic> json) {
    active = json['active'];
    title = json['title'];
    description = json['description'];
    imgName = json['imgName'];
  }
}
