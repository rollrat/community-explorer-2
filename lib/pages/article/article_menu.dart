// This source code is a part of Project Violet.
// Copyright (C) 2020. rollrat. Licensed under the MIT License.

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:communityexplorer/settings/settings.dart';

class ArticleSelector extends StatelessWidget {
  bool isScraped = false;
  ArticleSelector([this.isScraped = false]);

  Color getColor(int i) {
    return Settings.themeWhat ? Colors.grey.shade400 : Colors.grey.shade900;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Card(
              color:
                  Settings.themeWhat ? Color(0xFF353535) : Colors.grey.shade100,
              child: SizedBox(
                child: SizedBox(
                  width: 280,
                  height: (56 * 3 + 16).toDouble(),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // _typeItem(context, Icons.grid_on, 'srt0', 0),
                        _typeItem(
                            context,
                            isScraped
                                ? MdiIcons.briefcaseUploadOutline
                                : MdiIcons.briefcaseDownloadOutline,
                            '스크랩' + (isScraped ? ' 취소' : ''),
                            0),
                        _typeItem(
                            context, MdiIcons.eyeOffOutline, '게시글 가리기', 1),
                        _typeItem(
                            context, MdiIcons.alertOutline, '게시글 신고하기', 2),
                        // _typeItem(context, MdiIcons.trashCanOutline, '삭제', 2),
                        // _typeItem(context, MdiIcons.viewAgendaOutline, 'srt2', 2),
                        Expanded(
                          child: Container(),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(1)),
          boxShadow: [
            BoxShadow(
              color: Settings.themeWhat
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeItem(
      BuildContext context, IconData icon, String text, int selection) {
    return ListTile(
      leading: Icon(icon, color: getColor(selection)),
      title: Text(text, //Translations.of(context).trans(text),
          style: TextStyle(color: getColor(selection))),
      onTap: () async {
        Navigator.pop(context, selection);
      },
    );
  }
}