// This source code is a part of Project Violet.
// Copyright (C) 2020. rollrat. Licensed under the MIT License.

import 'dart:convert';
import 'dart:io';

import 'package:communityexplorer/component/board_manager.dart';
import 'package:communityexplorer/component/interface.dart';
import 'package:communityexplorer/download/native_downloader.dart';
import 'package:communityexplorer/log/log.dart';
import 'package:communityexplorer/network/wrapper.dart';
import 'package:communityexplorer/other/dialogs.dart';
import 'package:communityexplorer/pages/functions/report_page.dart';
import 'package:communityexplorer/pages/functions/view_page_context_menu.dart';
import 'package:communityexplorer/widget/toast.dart';
import 'package:crypto/crypto.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter/webview_flutter.dart';

class ViewPage extends StatefulWidget {
  final String url;
  final Color color;
  final BoardManager boardManager;
  final BoardExtractor extractor;
  final ArticleInfo articleInfo;

  ViewPage({
    this.url,
    this.color,
    this.boardManager,
    this.extractor,
    this.articleInfo,
  });

  @override
  _ViewPageState createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  bool _downloadStart = false;
  double _downloadState = 0.0;
  ContextMenu contextMenu;
  InAppWebViewController webView;
  double progress = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // contextMenu =
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: _appbar(context),
      ),
      // url: widget.url,
      // body: WebView(
      body: _webview(context),
    );
  }

  _appbar(context) {
    return AppBar(
      backgroundColor: widget.color,
      actions: [
        new IconButton(
          icon: new Icon(MdiIcons.web),
          tooltip: '웹에서 보기',
          onPressed: () async {
            if (await canLaunch(widget.url)) {
              await launch(widget.url);
            }
          },
        ),
        Stack(
          children: [
            Visibility(
              visible: _downloadStart,
              child: Center(
                child: SizedBox(
                  child: CircularProgressIndicator(
                    value: _downloadState,
                    valueColor:
                        new AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            Center(
              child: new IconButton(
                icon: new Icon(MdiIcons.download),
                tooltip: '다운로드',
                onPressed: () async {
                  if (_downloadStart) return;
                  if (await Permission.storage.isPermanentlyDenied ||
                      await Permission.storage.isDenied) {
                    if (await Permission.storage.request() ==
                        PermissionStatus.denied) {
                      // await Dialogs.okDialog(context,
                      //     "You cannot use downloader, if you not allow external storage permission.");
                      await Dialogs.okDialog(
                          context, "저장공간 권한을 허용하지 않으면 다운로드 기능을 이용할 수 없습니다.");
                      return;
                    }
                  }
                  setState(() {
                    _downloadStart = true;
                  });
                  try {
                    var tasks = await widget.extractor
                        .extractMedia(widget.articleInfo.url);

                    if (tasks == null) {
                      FlutterToast(context).showToast(
                        child: ToastWrapper(
                          isCheck: false,
                          isWarning: true,
                          msg: '지원되지 않습니다 :(',
                        ),
                        gravity: ToastGravity.BOTTOM,
                        toastDuration: Duration(seconds: 4),
                      );
                      return;
                    }

                    if (tasks.length == 0) {
                      FlutterToast(context).showToast(
                        child: ToastWrapper(
                          isCheck: false,
                          isWarning: true,
                          msg: '다운로드할 내용이 없습니다 :(',
                        ),
                        gravity: ToastGravity.BOTTOM,
                        toastDuration: Duration(seconds: 4),
                      );
                      return;
                    }

                    var path =
                        await ExtStorage.getExternalStoragePublicDirectory(
                            ExtStorage.DIRECTORY_DOWNLOADS);

                    var downloader = await NativeDownloader.getInstance();
                    var downloadedFileCount = 0;
                    var hash = sha1
                        .convert(utf8.encode(DateTime.now().toString()))
                        .toString()
                        .substring(0, 8);
                    await downloader.addTasks(tasks.map((e) {
                      e.downloadPath = join(join(
                          path,
                          e.format.formatting(
                              '%(extractor)s-$hash-%(file)s.%(ext)s')));

                      e.startCallback = () {};
                      e.completeCallback = () {
                        setState(() {
                          downloadedFileCount++;
                          _downloadState = downloadedFileCount / tasks.length;
                        });
                      };

                      return e;
                    }).toList());

                    FlutterToast(context).showToast(
                      child: ToastWrapper(
                        isCheck: true,
                        isWarning: false,
                        msg: tasks.length.toString() + '개 항목 다운로드 시작!',
                      ),
                      gravity: ToastGravity.BOTTOM,
                      toastDuration: Duration(seconds: 4),
                    );

                    while (tasks.length != downloadedFileCount) {
                      await Future.delayed(Duration(milliseconds: 500));
                    }

                    FlutterToast(context).showToast(
                      child: ToastWrapper(
                        isCheck: true,
                        isWarning: false,
                        msg: tasks.length.toString() + '개 항목 다운로드 완료!',
                      ),
                      gravity: ToastGravity.BOTTOM,
                      toastDuration: Duration(seconds: 4),
                    );
                  } catch (e, stacktrace) {
                    print(e);
                    print(stacktrace);
                    Logger.error('[Download Task] [' +
                        widget.articleInfo.url +
                        '] Extracting Error MSG:' +
                        e.toString() +
                        '\n' +
                        stacktrace.toString());

                    FlutterToast(context).showToast(
                      child: ToastWrapper(
                        isCheck: false,
                        isWarning: false,
                        msg: '오류가 발생했습니다 :(',
                      ),
                      gravity: ToastGravity.BOTTOM,
                      toastDuration: Duration(seconds: 4),
                    );
                  }
                  setState(() {
                    _downloadStart = false;
                  });
                },
              ),
            ),
          ],
        ),
        new IconButton(
          icon: new Icon(MdiIcons.alert),
          tooltip: '신고',
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return ReportPage(articleInfo: widget.articleInfo);
              },
            );
          },
        ),
        new IconButton(
          icon: new Icon(Icons.share),
          tooltip: '공유',
          onPressed: () async {
            Share.share(widget.url);
          },
        ),
        new IconButton(
          icon: new Icon(
              widget.boardManager.getFixed().isScrapred(widget.articleInfo.url)
                  ? Icons.star
                  : Icons.star_border),
          tooltip: '스크랩',
          onPressed: () async {
            if (!widget.boardManager
                .getFixed()
                .isScrapred(widget.articleInfo.url)) {
              await widget.boardManager.getFixed().addScrap(widget.articleInfo);
              FlutterToast(context).showToast(
                child: ToastWrapper(
                  isCheck: true,
                  isWarning: false,
                  msg: '스크랩되었습니다!',
                ),
                gravity: ToastGravity.BOTTOM,
                toastDuration: Duration(seconds: 4),
              );
            } else {
              await widget.boardManager
                  .getFixed()
                  .removeScrap(widget.articleInfo);
              FlutterToast(context).showToast(
                child: ToastWrapper(
                  isCheck: true,
                  isWarning: false,
                  msg: '스크랩이 취소되었습니다!',
                ),
                gravity: ToastGravity.BOTTOM,
                toastDuration: Duration(seconds: 4),
              );
            }

            setState(() {});
          },
        ),
      ],
    );
  }

  _webview(context) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
              child: progress < 1.0
                  ? LinearProgressIndicator(
                      value: progress,
                      valueColor:
                          new AlwaysStoppedAnimation<Color>(widget.color),
                    )
                  : Container()),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: Uri.parse(widget.url),
                headers: {
                  'User-Agent': HttpWrapper.mobileUserAgent,
                },
              ),
              // initialUrl: widget.url,
              // initialHeaders: {'User-Agent': HttpWrapper.mobileUserAgent},
              initialOptions: InAppWebViewGroupOptions(
                  android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
              )),
              contextMenu: _contextMenu(context),
              onWebViewCreated: (InAppWebViewController controller) {
                webView = controller;
              },
              onProgressChanged:
                  (InAppWebViewController controller, int progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
              // url: widget.url,
              // appCacheEnabled: true,

              // userAgent: HttpWrapper.mobileUserAgent,
              // javascriptMode: JavascriptMode.unrestricted,
              // gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
              //   Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              // ].toSet(),
              // withOverviewMode: true,
              // useWideViewPort: true,
              // hidden: hidden,

              // body: SafeArea(
              //   // child: InAppWebView(
              //   //   initialUrl: widget.url,
              //   //   // clearCache: false,
              //   //   // javascriptMode: JavascriptMode.unrestricted,
              //   // ),
              //   child: WebviewScaffold(
              //     url: widget.url,
              //     withZoom: true,
              //   ),
              // ),
            ),
          ),
        ],
      ),
    );
  }

  _contextMenu(context) {
    return ContextMenu(
      menuItems: [
        ContextMenuItem(
            androidId: 1,
            iosId: "1",
            title: "Special",
            action: () async {
              print("Menu item Special clicked!");
            })
      ],
      onCreateContextMenu: (hitTestResult) async {
        print("onCreateContextMenu");
        print(hitTestResult.extra);
        print(hitTestResult.type);
        print(await webView.getSelectedText());

        if (hitTestResult.type == InAppWebViewHitTestResultType.IMAGE_TYPE ||
            hitTestResult.type ==
                InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE ||
            hitTestResult.type ==
                InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE) {
          var r = await showDialog(
            context: context,
            builder: (context) =>
                ViewPageContextMenu(hitTestResult.extra, hitTestResult.type),
          );

          if (r == null) return;

          // copy
          if ((hitTestResult.type ==
                      InAppWebViewHitTestResultType.SRC_ANCHOR_TYPE ||
                  hitTestResult.type ==
                      InAppWebViewHitTestResultType.SRC_IMAGE_ANCHOR_TYPE) &&
              r == 0) {
            Clipboard.setData(ClipboardData(text: hitTestResult.extra));
            FlutterToast(context).showToast(
              child: ToastWrapper(
                isCheck: true,
                isWarning: false,
                msg: '복사되었습니다!',
              ),
              gravity: ToastGravity.BOTTOM,
              toastDuration: Duration(seconds: 4),
            );
          }
        }
      },
      onHideContextMenu: () {
        print("onHideContextMenu");
      },
      onContextMenuActionItemClicked: (contextMenuItemClicked) {
        var id = (Platform.isAndroid)
            ? contextMenuItemClicked.androidId
            : contextMenuItemClicked.iosId;
        print("onContextMenuActionItemClicked: " +
            id.toString() +
            " " +
            contextMenuItemClicked.title);
      },
    );
  }
}
