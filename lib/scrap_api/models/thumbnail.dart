class Thumbnail {
  String? url;
  int? width, height;
  Thumbnail({this.url, this.width, this.height});
  // Add this method in your Thumbnail class as well
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'width': width,
      'height': height,
    };
  }
}
