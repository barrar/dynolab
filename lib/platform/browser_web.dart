import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../share_state.dart';

String? readStorage(String key) => web.window.localStorage.getItem(key);
void writeStorage(String key, String value) =>
    web.window.localStorage.setItem(key, value);
String currentUrl() => web.window.location.href;
String? readUrlState() => sharedStateFromUrl(Uri.parse(currentUrl()));
void writeUrlState(String state) {
  final url = urlWithSharedState(Uri.parse(currentUrl()), state).toString();
  if (url != currentUrl()) {
    web.window.history.replaceState(web.window.history.state, '', url);
  }
}

void Function() listenToUrlChanges(void Function() callback) {
  final listener = ((web.Event _) => callback()).toJS;
  web.window.addEventListener('popstate', listener);
  return () => web.window.removeEventListener('popstate', listener);
}

Future<void> copyText(String text) =>
    web.window.navigator.clipboard.writeText(text).toDart;
void openExternal(String url) =>
    web.window.open(url, '_blank', 'noopener,noreferrer');
void downloadCsv(String csv) {
  final uri = Uri.dataFromString(csv, mimeType: 'text/csv', encoding: utf8);
  final anchor = web.HTMLAnchorElement()
    ..href = uri.toString()
    ..download = 'dynolab-comparison.csv';
  anchor.click();
}
