import 'dart:async';
import 'package:flutter/material.dart';
import 'bootstrap.dart';

void main() {
  runZonedGuarded(() async {
    await bootstrap();
  }, (error, stack) {
    debugPrint('Top-level unhandled exception: $error\n$stack');
  });
}
