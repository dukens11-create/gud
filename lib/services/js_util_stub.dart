// Stub file for dart:js_util on non-web platforms
// This provides a dummy jsify function that should never be called on mobile

dynamic jsify(dynamic object) {
  throw UnsupportedError('jsify is only available on web platforms');
}
