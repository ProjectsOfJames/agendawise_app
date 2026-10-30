import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/intent_parser.dart';

final intentParserProvider = Provider<IntentParser>((ref) => const IntentParser());
