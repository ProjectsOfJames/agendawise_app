import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class IdGenerator {
  const IdGenerator();

  static const _uuid = Uuid();

  String next() => _uuid.v4();
}

final idGeneratorProvider = Provider<IdGenerator>((ref) => const IdGenerator());
