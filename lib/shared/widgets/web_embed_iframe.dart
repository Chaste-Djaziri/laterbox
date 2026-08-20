import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Widget buildWebEmbedIframe(String embedUrl) {
  final viewId = 'embed-iframe-${embedUrl.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final iframe = web.HTMLIFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..allowFullscreen = true;
      return iframe;
    },
  );

  return HtmlElementView(viewType: viewId);
}
