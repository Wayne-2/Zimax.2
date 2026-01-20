import 'package:supabase_flutter/supabase_flutter.dart';

class LiveKitService {
  static Future<String> getToken(String lessonId) async {
    final supabase = Supabase.instance.client;

    final res = await supabase.functions.invoke(
      'generate-livekit-token',
      body: {'lessonId': lessonId},
    );

    if (res.data == null) {
      throw Exception('Function returned null');
    }

    if (res.data is! Map<String, dynamic>) {
      
      throw Exception(
        'Expected Map, got ${res.data.runtimeType}, FUNCTION RESPONSE: ${res.data}',
      );
    }

    final data = res.data as Map<String, dynamic>;

    final token = data['token'];

    if (token == null) {
      throw Exception('Token field is null');
    }

    if (token is! String) {
      throw Exception(
        'Expected token String, got ${token.runtimeType}, FUNCTION RESPONSE: ${res.data}',
      );
    }

    return token;
    
  }
}
