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

class VideoResult {
  VideoResult({
    this.itemList,
  });

  factory VideoResult.fromJson(Map<String, dynamic> jsonRes) {
    final List<VideoItem>? itemList = jsonRes['item_list'] is List ? <VideoItem>[] : null;
    if (itemList != null) {
      for (final dynamic item in jsonRes['item_list']!) {
        if (item != null) {
          tryCatch(() {
            itemList.add(VideoItem.fromJson(asT<Map<String, dynamic>>(item)!));
          });
        }
      }
    }
    return VideoResult(
      itemList: itemList,
    );
  }

  List<VideoItem>? itemList;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'item_list': itemList,
      };
}

class VideoItem {
  VideoItem({
    this.video,
    this.desc,
  });

  factory VideoItem.fromJson(Map<String, dynamic> jsonRes) {
    return VideoItem(
      video: jsonRes['video'] == null
          ? null
          : Video.fromJson(asT<Map<String, dynamic>>(jsonRes['video'])!),
      desc: asT<String?>(jsonRes['desc']),
    );
  }

  Video? video;
  String? desc;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'video': video,
        'desc': desc,
      };
}

class Video {
  Video({
    this.playAddr,
    this.cover,
  });

  factory Video.fromJson(Map<String, dynamic> jsonRes) => Video(
        playAddr: jsonRes['play_addr'] == null
            ? null
            : PlayAddr.fromJson(
                asT<Map<String, dynamic>>(jsonRes['play_addr'])!),
        cover: jsonRes['cover'] == null
            ? null
            : Cover.fromJson(asT<Map<String, dynamic>>(jsonRes['cover'])!),
      );

  PlayAddr? playAddr;
  Cover? cover;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'play_addr': playAddr,
        'cover': cover,
      };
}

class PlayAddr {
  PlayAddr({
    this.urlList,
    this.uri,
  });

  factory PlayAddr.fromJson(Map<String, dynamic> jsonRes) {
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
    return PlayAddr(
      urlList: urlList,
      uri: asT<String?>(jsonRes['uri']),
    );
  }

  List<String>? urlList;
  String? uri;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url_list': urlList,
        'uri': uri,
      };
}

class Cover {
  Cover({
    this.uri,
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
      uri: asT<String?>(jsonRes['uri']),
      urlList: urlList,
    );
  }

  String? uri;
  List<String>? urlList;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uri': uri,
        'url_list': urlList,
      };
}
