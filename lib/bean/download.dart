class DownloadBean {
  String preview;
  String desc;
  String? videoUrl;
  List<String>? galleryUrlList;

  bool get isGallery => galleryUrlList != null && galleryUrlList!.isNotEmpty;

  bool get isVideo => videoUrl != null && videoUrl!.isNotEmpty;

  DownloadBean({
    required this.preview,
    required this.desc,
    this.videoUrl,
    this.galleryUrlList,
  });
}
