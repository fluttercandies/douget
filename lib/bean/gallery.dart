import 'dart:convert';
import 'dart:developer';

void tryCatch(Function? f) {
  try {
    f?.call();
  } catch (e, stack) {
    log('$e');
    log('$stack');
  }
}

class FFConvert {
  FFConvert._();

  static T? convert<T>(dynamic value) {
    if (value == null) {
      return null;
    }
    return json.decode(value.toString()) as T?;
  }
}

T? asT<T extends Object?>(dynamic value, [T? defaultValue]) {
  if (value is T) {
    return value;
  }
  try {
    if (value != null) {
      final String valueS = value.toString();
      if ('' is T) {
        return valueS as T;
      } else if (0 is T) {
        return int.parse(valueS) as T;
      } else if (0.0 is T) {
        return double.parse(valueS) as T;
      } else if (false is T) {
        if (valueS == '0' || valueS == '1') {
          return (valueS == '1') as T;
        }
        return (valueS == 'true') as T;
      } else {
        return FFConvert.convert<T>(value);
      }
    }
  } catch (e, stackTrace) {
    log('asT<$T>', error: e, stackTrace: stackTrace);
    return defaultValue;
  }

  return defaultValue;
}

class GalleryResult {
  GalleryResult({
    this.itemList,
  });

  factory GalleryResult.fromJson(Map<String, dynamic> jsonRes) {
    final List<GalleryItem>? itemList =
        jsonRes['item_list'] is List ? <GalleryItem>[] : null;
    if (itemList != null) {
      for (final dynamic item in jsonRes['item_list']!) {
        if (item != null) {
          tryCatch(() {
            itemList
                .add(GalleryItem.fromJson(asT<Map<String, dynamic>>(item)!));
          });
        }
      }
    }
    return GalleryResult(
      itemList: itemList,
    );
  }

  List<GalleryItem>? itemList;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'item_list': itemList,
      };
}

class GalleryItem {
  GalleryItem({
    this.video,
    this.images,
    this.desc,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> jsonRes) {
    final List<GalleryImage>? images =
        jsonRes['images'] is List ? <GalleryImage>[] : null;
    if (images != null) {
      for (final dynamic item in jsonRes['images']!) {
        if (item != null) {
          tryCatch(() {
            images.add(GalleryImage.fromJson(asT<Map<String, dynamic>>(item)!));
          });
        }
      }
    }

    return GalleryItem(
      video: jsonRes['video'] == null
          ? null
          : Video.fromJson(asT<Map<String, dynamic>>(jsonRes['video'])!),
      images: images,
      desc: asT<String?>(jsonRes['desc']),
    );
  }

  Video? video;
  List<GalleryImage>? images;
  String? desc;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'video': video,
        'images': images,
        'desc': desc,
      };
}

class Video {
  Video({
    this.cover,
  });

  factory Video.fromJson(Map<String, dynamic> jsonRes) => Video(
        cover: jsonRes['cover'] == null
            ? null
            : Cover.fromJson(asT<Map<String, dynamic>>(jsonRes['cover'])!),
      );

  Cover? cover;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cover': cover,
      };
}

class Cover {
  Cover({
    this.urlList,
  });

  factory Cover.fromJson(Map<String, dynamic> jsonRes) {
    final List<String>? urlList =
        jsonRes['url_list'] is List ? <String>[] : null;
    if (urlList != null) {
      for (final dynamic item in jsonRes['url_list']!) {
        if (item != null) {
          tryCatch(() {
            urlList.add(asT<String>(item)!);
          });
        }
      }
    }
    return Cover(
      urlList: urlList,
    );
  }

  List<String>? urlList;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url_list': urlList,
      };
}

class GalleryImage {
  GalleryImage({
    this.urlList,
  });

  factory GalleryImage.fromJson(Map<String, dynamic> jsonRes) {
    final List<String>? urlList =
        jsonRes['url_list'] is List ? <String>[] : null;
    if (urlList != null) {
      for (final dynamic item in jsonRes['url_list']!) {
        if (item != null) {
          tryCatch(() {
            urlList.add(asT<String>(item)!);
          });
        }
      }
    }
    return GalleryImage(
      urlList: urlList,
    );
  }

  List<String>? urlList;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url_list': urlList,
      };
}
