// Dart imports
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class LoggerService {
  static final Logger logger = Logger(
    level: kReleaseMode ? Level.warning : Level.debug,
  );
}
