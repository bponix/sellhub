class AppFailure implements Exception {
  const AppFailure({required this.title, this.detail});

  final String title;
  final String? detail;

  factory AppFailure.fromObject(Object error, {required String fallbackTitle}) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('OperationException(linkException: ', '')
        .replaceFirst('OperationException(', '')
        .trim();
    return AppFailure(
      title: fallbackTitle,
      detail: message.isEmpty ? null : message,
    );
  }

  @override
  String toString() => detail == null || detail!.isEmpty ? title : detail!;
}
