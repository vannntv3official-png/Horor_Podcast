/// Unified application exception hierarchy with localized Khmer messages
class AppException implements Exception {
  final String message;
  final String? technicalDetails;
  final String? code;

  const AppException({
    required this.message,
    this.technicalDetails,
    this.code,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'គ្មានការតភ្ជាប់អ៊ីនធឺណិតទេ។ សូមពិនិត្យបណ្តាញរបស់អ្នកឡើងវិញ។',
    super.technicalDetails,
    super.code = 'NETWORK_ERROR',
  });
}

class AuthException extends AppException {
  const AuthException({
    super.message = 'សម័យការចូលប្រើប្រាស់បានផុតកំណត់។ សូមចូលគណនីម្តងទៀត។',
    super.technicalDetails,
    super.code = 'AUTH_EXPIRED',
  });
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException({
    super.message = 'អ្នកមិនមានសិទ្ធិអនុវត្តសកម្មភាពនេះទេ។',
    super.technicalDetails,
    super.code = 'PERMISSION_DENIED',
  });
}

class AudioPlaybackException extends AppException {
  const AudioPlaybackException({
    super.message = 'មិនអាចចាក់សំឡេងបានទេ។ សូមព្យាយាមម្តងទៀត។',
    super.technicalDetails,
    super.code = 'AUDIO_ERROR',
  });
}

class DownloadException extends AppException {
  const DownloadException({
    super.message = 'ការទាញយកត្រូវបានរំខាន ឬមិនអាចដំណើរការបាន។',
    super.technicalDetails,
    super.code = 'DOWNLOAD_ERROR',
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'រកមិនឃើញទិន្នន័យដែលអ្នកកំពុងស្វែងរកទេ។',
    super.technicalDetails,
    super.code = 'NOT_FOUND',
  });
}

class ValidationException extends AppException {
  const ValidationException({
    super.message = 'ព័ត៌មានដែលបានបញ្ចូលមិនត្រឹមត្រូវទេ។',
    super.technicalDetails,
    super.code = 'VALIDATION_ERROR',
  });
}
