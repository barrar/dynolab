String? readStorage(String key) => null;
void writeStorage(String key, String value) {}
String currentUrl() => '';
String? readUrlState() => null;
void writeUrlState(String state) {}
void Function() listenToUrlChanges(void Function() callback) => () {};
Future<void> copyText(String text) async {}
void openExternal(String url) {}
void downloadCsv(String csv) {}
