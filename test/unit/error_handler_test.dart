import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khmer_horror_podcast/core/errors/app_exception.dart';
import 'package:khmer_horror_podcast/core/errors/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('maps SocketException to user-friendly NetworkException in Khmer', () {
      const socketError = SocketException('Connection refused');
      final appEx = ErrorHandler.handle(socketError);

      expect(appEx, isA<NetworkException>());
      expect(appEx.message, contains('គ្មានការតភ្ជាប់អ៊ីនធឺណិត'));
    });

    test('maps Dio connectionTimeout to NetworkException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      final appEx = ErrorHandler.handle(dioError);

      expect(appEx, isA<NetworkException>());
      expect(appEx.message, contains('ការតភ្ជាប់ចំណាយពេលយូរ'));
    });

    test('preserves existing AppException directly', () {
      const customEx = AudioPlaybackException(message: 'សំឡេងបរាជ័យ');
      final appEx = ErrorHandler.handle(customEx);

      expect(appEx, isA<AudioPlaybackException>());
      expect(appEx.message, 'សំឡេងបរាជ័យ');
    });
  });
}
