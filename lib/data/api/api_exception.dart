/// A failure surfaced from the backend, in a form the UI can show.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  /// Field-level validation errors from a 422 response.
  final Map<String, List<String>> errors;

  ApiException(this.message, {this.statusCode, this.errors = const {}});

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  /// 409: the action conflicts with current state (e.g. nothing to undo).
  bool get isConflict => statusCode == 409;

  bool get isValidation => statusCode == 422;

  /// First validation message, if any — handy for a snackbar.
  String? get firstError =>
      errors.values.where((l) => l.isNotEmpty).map((l) => l.first).firstOrNull;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
