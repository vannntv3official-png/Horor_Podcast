import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'app_exception.dart';
import '../logging/app_logger.dart';

class ErrorHandler {
  static AppException handle(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error('ErrorHandler caught exception: $error', error, stackTrace);

    if (error is AppException) {
      return error;
    }

    if (error is SocketException) {
      return const NetworkException(
        message: 'គ្មានការតភ្ជាប់អ៊ីនធឺណិតទេ។ សូមពិនិត្យមើល Wi-Fi ឬទិន្នន័យទូរស័ព្ទ។',
      );
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException(
            message: 'ការតភ្ជាប់ចំណាយពេលយូរពេក។ សូមព្យាយាមម្តងទៀត។',
          );
        case DioExceptionType.connectionError:
          return const NetworkException(
            message: 'មិនអាចតភ្ជាប់ទៅកាន់ម៉ាស៊ីនមេបានទេ។ សូមពិនិត្យបណ្តាញ។',
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401 || statusCode == 403) {
            return const PermissionDeniedException();
          } else if (statusCode == 404) {
            return const NotFoundException();
          }
          return AppException(
            message: 'ម៉ាស៊ីនមេមានបញ្ហា (កូដ: $statusCode)។ សូមព្យាយាមបន្តិចទៀត។',
          );
        default:
          return const AppException(
            message: 'បញ្ហាបណ្តាញមិនច្បាស់លាស់។ សូមព្យាយាមម្តងទៀត។',
          );
      }
    }

    if (error is supa.AuthException) {
      return AuthException(
        message: _mapSupabaseAuthError(error.message),
        technicalDetails: error.message,
      );
    }

    if (error is supa.PostgrestException) {
      if (error.code == 'PGRST116') {
        return const NotFoundException();
      }
      if (error.code == '42501') {
        return const PermissionDeniedException();
      }
      return AppException(
        message: 'មានបញ្ហាក្នុងការទាញយកទិន្នន័យ។ សូមព្យាយាមម្តងទៀត។',
        technicalDetails: error.message,
      );
    }

    return const AppException(
      message: 'មានបញ្ហាមិនរំពឹងទុកមួយបានកើតឡើង។ សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ។',
    );
  }

  static String _mapSupabaseAuthError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវទេ។';
    }
    if (lower.contains('user already registered')) {
      return 'អ៊ីមែលនេះមានគណនីរួចហើយ។ សូមចូលប្រើប្រាស់។';
    }
    if (lower.contains('password should be at least')) {
      return 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួអក្សរ។';
    }
    return 'ការផ្ទៀងផ្ទាត់គណនីមិនជោគជ័យ។ សូមព្យាយាមម្តងទៀត។';
  }
}
