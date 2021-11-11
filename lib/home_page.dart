import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:douget/bean/download.dart';
import 'package:douget/bean/gallery.dart';
import 'package:douget/bean/video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textEditingController = TextEditingController();

  bool _loading = false;

  final Dio _dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) => status == null || status < 500,
    ),
  );

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  bool _isDouYinSharedUrl(String url) =>
      url.startsWith("https://www.iesdouyin.com") ||
      url.startsWith("https://v.douyin.com");

  bool _checkRedirectUrl(String url) =>
      url.startsWith("https://www.iesdouyin.com");

  void _showMessage(String e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e),
    ));
    setState(() {
      _loading = false;
    });
  }

  String _checkSharedText(String sharedUrl, {bool? fromClipBoard}) {
    RegExp r = RegExp(
        r"http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+");
    RegExpMatch? firstMatch = r.firstMatch(sharedUrl);
    if (firstMatch != null) {
      String? sharedUrl = firstMatch.group(0);
      if (sharedUrl != null && _isDouYinSharedUrl(sharedUrl)) {
        return sharedUrl.trim();
      } else {
        if (fromClipBoard == null) _showMessage("分享链接格式不正确!");
      }
    } else {
      if (fromClipBoard == null) _showMessage("分享链接格式不正确!");
    }
    return "";
  }

  void _checkClipboard() async {
    if (_loading) {
      return;
    }
    ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null &&
        clipboardData.text != null &&
        clipboardData.text!.isNotEmpty) {
      String sharedUrl =
          _checkSharedText(clipboardData.text ?? "", fromClipBoard: true);
      if (sharedUrl.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            action: SnackBarAction(
              label: "保存到相册",
              onPressed: () {
                _download(sharedUrl);
              },
            ),
            content: const Text("检测到分享链接"),
          ),
        );
      }
    }
  }

  void _download(String sharedUrl) async {
    setState(() {
      _loading = true;
    });
    String redirectUrl = "";
    if (_checkRedirectUrl(sharedUrl)) {
      redirectUrl = sharedUrl;
    } else {
      redirectUrl = await _getRedirectUrl(sharedUrl);
    }
    if (redirectUrl.isNotEmpty) {
      DownloadBean? bean = await _fetchDownloadBean(redirectUrl);
      if (bean != null) {
        _downloadFromBean(bean);
      } else {
        _showMessage("获取下载地址出错!");
      }
    }
  }

  Future<String> _getRedirectUrl(String url) async {
    try {
      Response response = await _dio.get(url);
      bool? isRedirect = response.isRedirect;
      if (isRedirect != null && isRedirect) {
        List<String>? redirectList = response.headers["Location"];
        if (redirectList != null && redirectList.isNotEmpty) {
          return redirectList.first;
        } else {
          _showMessage("重定向错误!");
        }
      } else {
        _showMessage("重定向错误!");
      }
    } catch (e) {
      _showMessage(e.toString());
    }
    return "";
  }

  String _getVideoId(String redirectUrl) {
    RegExp r = RegExp(r"video/(\d+)/");
    RegExpMatch? firstMatch = r.firstMatch(redirectUrl);
    if (firstMatch != null && (firstMatch.end - 1 > firstMatch.start + 6)) {
      return redirectUrl.substring(firstMatch.start + 6, firstMatch.end - 1);
    }
    _showMessage("获取VideoId错误!");
    return "";
  }

  Future<DownloadBean?> _fetchDownloadBean(String redirectUrl) async {
    String videoId = _getVideoId(redirectUrl);
    if (videoId.isNotEmpty) {
      try {
        Response response = await Dio().get(
            "https://www.iesdouyin.com/web/api/v2/aweme/iteminfo/?item_ids=$videoId");
        if (response.data != null && response.data is Map<String, dynamic>) {
          Map<String, dynamic> map = response.data;

          bool isGallery = map['item_list'][0]['images'] != null &&
              map['item_list'][0]['images'].isNotEmpty;
          if (isGallery) {
            String preview = "";
            String desc = "";
            List<String> galleryUrlList = [];
            GalleryResult galleryResult = GalleryResult.fromJson(map);
            if (galleryResult.itemList != null &&
                galleryResult.itemList!.isNotEmpty) {
              GalleryItem item = galleryResult.itemList!.first;
              desc = item.desc ?? "";
              preview = item.video?.cover?.urlList?.first ?? "";
              for (GalleryImage image in item.images!) {
                if (image.urlList != null && image.urlList!.isNotEmpty) {
                  bool hasJpeg = false;
                  for (String url in image.urlList!) {
                    if (url.contains("jpeg")) {
                      galleryUrlList.add(url);
                      hasJpeg = true;
                      break;
                    }
                  }
                  if (!hasJpeg) {
                    galleryUrlList.add(image.urlList!.first);
                  }
                }
              }
              return DownloadBean(
                desc: desc,
                preview: preview,
                galleryUrlList: galleryUrlList,
              );
            }
          } else {
            String videoUrl = "";
            String preview = "";
            String desc = "";
            VideoResult videoResult = VideoResult.fromJson(map);

            if (videoResult.itemList != null &&
                videoResult.itemList!.isNotEmpty) {
              VideoItem item = videoResult.itemList!.first;
              desc = item.desc ?? "";
              preview = item.video?.cover?.urlList?.first ?? "";
              String? uri = item.video?.playAddr?.uri;
              if (uri != null && uri.isNotEmpty) {
                String ratio = "1080p";
                String url =
                    "https://aweme.snssdk.com/aweme/v1/play/?video_id=$uri&ratio=$ratio&line=0";
                String _videoUrl = await _getRedirectUrl(url);
                if (_videoUrl.isNotEmpty) {
                  videoUrl = _videoUrl;
                }
              }
              return DownloadBean(
                desc: desc,
                preview: preview,
                videoUrl: videoUrl,
              );
            }
          }
        }
      } catch (e) {
        _showMessage(e.toString());
      }
    }
    return null;
  }

  void _downloadFromBean(DownloadBean bean) async {
    var result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(bean.desc),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height / 3.0,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    bean.preview,
                    fit: BoxFit.scaleDown,
                  ),
                ),
                if (bean.isGallery)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 6.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                        color: const Color(0x7e333333),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image,
                            size: 14.0,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            bean.galleryUrlList!.length.toString(),
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(bean.isGallery ? '保存图集到相册' : '保存视频到相册'),
              onPressed: () async {
                Navigator.of(context).pop(true);
                try {
                  if (await Permission.storage.request().isGranted) {
                    var appDocDir = await getTemporaryDirectory();
                    if (bean.isGallery) {
                      int success = 0;
                      for (String url in bean.galleryUrlList!) {
                        int time = DateTime.now().millisecondsSinceEpoch;
                        String name = "/douget_$time.jpeg";
                        if (url.contains("jpeg")) {
                          name = "/douget_$time.jpeg";
                        }
                        if (url.contains("webp")) {
                          name = "/douget_$time.webp";
                        }
                        Response response = await Dio().get(url,
                            options: Options(responseType: ResponseType.bytes));
                        final AssetEntity? result =
                            await PhotoManager.editor.saveImage(
                          Uint8List.fromList(response.data),
                          title: name,
                        );
                        if (result != null) {
                          success++;
                        }
                      }
                      _showMessage("$success张图片已保存到相册!");
                    } else if (bean.isVideo) {
                      int time = DateTime.now().millisecondsSinceEpoch;
                      String filename = 'douget_$time.mp4';
                      String savePath = appDocDir.path + filename;

                      await Dio().download(bean.videoUrl!, savePath);
                      final AssetEntity? result =
                          await PhotoManager.editor.saveVideo(
                        File(savePath),
                        title: filename,
                      );
                      if (result != null) {
                        _showMessage("已保存到相册!");
                      }
                    }
                  } else {
                    _showMessage("未授予存储权限!");
                  }
                } catch (e) {
                  _showMessage(e.toString());
                }
              },
            ),
          ],
        );
      },
    );
    if (result == null) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DouGet")),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                  hintText: "复制分享链接到此处",
                  border: InputBorder.none,
                  fillColor: Theme.of(context).bottomAppBarColor,
                  filled: true,
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 15.0),
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton(
                  child: const Text(
                    '清除',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    _textEditingController.clear();
                  },
                ),
              ),
              const SizedBox(height: 15.0),
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton(
                  child: const Text(
                    '粘贴',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    ClipboardData? clipboardData =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData != null && clipboardData.text != null) {
                      _textEditingController.text = clipboardData.text!;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_loading) return;
          String text = _textEditingController.text.trim();
          if (text.isNotEmpty) {
            FocusScope.of(context).unfocus();
            String sharedUrl = _checkSharedText(text);
            if (sharedUrl.isNotEmpty) {
              _download(sharedUrl);
            }
          }
        },
        tooltip: '下载',
        child: _loading
            ? const CircularProgressIndicator()
            : const Icon(Icons.download),
      ),
    );
  }
}
