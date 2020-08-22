// This source code is a part of Project Violet.
// Copyright (C) 2020. rollrat. Licensed under the MIT License.

import 'dart:ui';
import 'dart:convert';

import 'package:communityexplorer/component/dcinside/dcinside_parser.dart';
import 'package:communityexplorer/component/interface.dart';
import 'package:communityexplorer/network/http_header.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DCInsideExtractor extends BoardExtractor {
  RegExp urlMatcher;

  DCInsideExtractor() {
    urlMatcher = RegExp(
        r'^https?://(gall|m)\.dcinside\.com/(mgallery/)?board/(view|\w+\/\d+)/?.*?$');
  }

  @override
  bool acceptURL(String url) {
    return urlMatcher.stringMatch(url) == url;
  }

  @override
  Future<String> tidyURL(String url) async {
    var urlMatcher = RegExp(
        r'^https?://(gall|m)\.dcinside\.com/(mgallery/)?board/(lists|\w+)/?.*?$');
    var match = urlMatcher.allMatches(url);

    var ismobile = match.first[1] == 'm';
    if (ismobile) {
      var request = await http.post(url);
      url = request.headers['location'];
    }

    return url.split('&').first;
  }

  @override
  Color color() {
    return Colors.indigo;
  }

  @override
  String fav() {
    return 'https://gall.dcinside.com/favicon.ico';
  }

  @override
  String extractor() {
    return 'dcinside';
  }

  @override
  String name() {
    return '디시인사이드';
  }

  @override
  Future<PageInfo> next(BoardInfo board, int offset) async {
    // URL
    // 1. https://gall.dcinside.com/board/lists
    // 2. https://gall.dcinside.com/mgallery/board/lists

    var qurey = Map<String, dynamic>.from(board.extrainfo);
    qurey['page'] = offset + 1;

    var url = board.url +
        '?' +
        qurey.entries
            .map((e) =>
                '${e.key}=${Uri.encodeQueryComponent(e.value.toString())}')
            .join('&');

    var html = (await http.get(
      url,
      headers: {
        'Accept': HttpWrapper.accept,
        'User-Agent': HttpWrapper.userAgent,
      },
    ))
        .body;

    List<ArticleInfo> articles;

    if (!board.url.contains('/mgallery/'))
      articles = DCInsideParser.parseGalleryBoard(html);
    else
      articles = DCInsideParser.parseMinorGalleryBoard(html);

    return PageInfo(
      articles: articles,
      board: board,
      offset: offset,
    );
  }

  @override
  List<BoardInfo> best() {
    return [
      BoardInfo(
        url: 'https://gall.dcinside.com/board/lists',
        name: '이슈줌 갤러리',
        extrainfo: {'id': 'issuezoom'},
        extractor: 'dcinside',
      ),
      BoardInfo(
        url: 'https://gall.dcinside.com/board/lists',
        name: '초개념 갤러리',
        extrainfo: {'id': 'superidea'},
        extractor: 'dcinside',
      ),
      BoardInfo(
        url: 'https://gall.dcinside.com/board/lists',
        name: 'HIT 갤러리',
        extrainfo: {'id': 'hit', 'exception_mode': 'recommend'},
        extractor: 'dcinside',
      ),
      BoardInfo(
        url: 'https://gall.dcinside.com/board/lists',
        name: '국내야구 갤러리',
        extrainfo: {'id': 'baseball_new9', 'exception_mode': 'recommend'},
        extractor: 'dcinside',
      ),
      BoardInfo(
        url: 'https://gall.dcinside.com/mgallery/board/lists',
        name: '중세게임 마이너 갤러리',
        extrainfo: {'id': 'aoegame', 'exception_mode': 'recommend'},
        extractor: 'dcinside',
      ),
    ];
  }
}