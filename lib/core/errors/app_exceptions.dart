/// Base class for all application-level exceptions in Wero.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Thrown when network connection is absent or requests time out.
final class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Koneksi jaringan terputus atau tidak stabil.',
    Object? cause,
  ]) : super(code: 'NETWORK_ERROR', cause: cause);
}

/// Thrown when authentication or session validation fails.
final class AppAuthException extends AppException {
  const AppAuthException([
    super.message = 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    Object? cause,
  ]) : super(code: 'AUTH_REQUIRED', cause: cause);
}

/// Thrown when user lacks required role or permission for an operation.
final class PermissionDeniedException extends AppException {
  const PermissionDeniedException([
    super.message = 'Anda tidak memiliki hak akses untuk tindakan ini.',
    Object? cause,
  ]) : super(code: 'PERMISSION_DENIED', cause: cause);
}

/// Thrown when a requested resource is not found.
final class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Data yang dicari tidak ditemukan.',
    Object? cause,
  ]) : super(code: 'NOT_FOUND', cause: cause);
}

/// Thrown when user input validation fails.
final class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause})
    : super(code: 'VALIDATION_ERROR');
}

/// Thrown when a server error occurs.
final class ServerException extends AppException {
  const ServerException([
    super.message = 'Terjadi kesalahan pada server. Coba beberapa saat lagi.',
    Object? cause,
  ]) : super(code: 'SERVER_ERROR', cause: cause);
}
