import 'package:supabase_flutter/supabase_flutter.dart';

class CallService {
  /// Fetches a LiveKit token for a call
  static Future<String> getToken({
    required String callId,
    bool isCaller = false, // optional: pass role if needed
  }) async {
    final supabase = Supabase.instance.client;

    // Invoke the Edge Function
    final res = await supabase.functions.invoke(
      'call-handler', // Your Supabase Edge Function name
      body: {
        'callId': callId,
        'isCaller': isCaller,
      },
    );

    // res.data can be null if something went wrong
    if (res.data == null) {
      throw Exception('Function returned null');
    }

    // Ensure the response is a Map
    if (res.data is! Map<String, dynamic>) {
      throw Exception(
        'Expected Map<String, dynamic>, got ${res.data.runtimeType}. '
        'Response: ${res.data}',
      );
    }

    final data = res.data as Map<String, dynamic>;

    // Extract the token
    final token = data['token'];
    if (token == null || token is! String) {
      throw Exception('Invalid token in function response: ${res.data}');
    }

    return token;
  }
}
