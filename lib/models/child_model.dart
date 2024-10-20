class ChildModel {
  final String childName;
  final String securtiyCode;
  final String imageUrl;
  final List<String> videos;
  final List<String> channels;
  final String uid;

  ChildModel({
    required this.childName,
    required this.securtiyCode,
    required this.imageUrl,
    required this.videos,
    required this.channels,
    required this.uid,
  });
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      childName: json['childname'],
      securtiyCode: json['securityCode'],
      imageUrl: json['imageUrl'],
      uid: json['uid'],
      videos: List<String>.from(json['videos']),
      channels: List<String>.from(json['channels']),
    );
  }

  // to json
  Map<String, dynamic> toJson() => {
        'childname': childName,
        'securityCode': securtiyCode,
        'imageUrl': imageUrl,
        'videos': videos,
        'channels': channels,
        'uid': uid,
      };
}
