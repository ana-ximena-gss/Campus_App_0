import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class UsernameGenerator {
  static final Random _random = Random();

  static const List<String> _nouns = [
    'falcon',
    'river',
    'cactus',
    'moon',
    'otter',
    'cloud',
    'comet',
    'forest',
    'turtle',
    'mountain',
    'star',
    'ocean',
    'eagle',
    'mesa',
    'sun',
    'fox',
    'pine',
    'meteor',
    'hawk',
    'lake',
    'wolf',
    'planet',
    'grove',
    'island',
    'robin',
    'valley',
    'cedar',
    'reef',
    'sparrow',
    'stone',
    'meadow',
    'orbit',
    'panda',
    'harbor',
    'willow',
    'pebble',
    'dolphin',
    'prairie',
    'coral',
    'badger',
    'maple',
    'bay',
    'raven',
    'trail',
    'bison',
    'ridge',
    'acorn',
    'lagoon',
    'gecko',
    'cliff',
  ];

  static String _generateCandidate() {
    String first;
    String second;

    do {
      first = _nouns[_random.nextInt(_nouns.length)];
      second = _nouns[_random.nextInt(_nouns.length)];
    } while (first == second);

    return '${first}_$second';
  }

  static Future<String> generateUnique() async {
    final supabase = Supabase.instance.client;

    for (int attempt = 0; attempt < 20; attempt++) {
      final username = _generateCandidate();

      final available = await supabase.rpc(
        'is_username_available',
        params: {
          'candidate': username,
        },
      );

      if (available == true) {
        return username;
      }
    }

    throw StateError(
      'Unable to generate an available username. Please try again.',
    );
  }
}