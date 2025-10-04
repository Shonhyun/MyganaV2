/// Configuration for OpenAI API
class OpenAIConfig {
  /// Your OpenAI API key
  ///
  /// To get your API key:
  /// 1. Go to https://platform.openai.com/api-keys
  /// 2. Create a new API key
  /// 3. Replace 'YOUR_OPENAI_API_KEY' with your actual key
  ///
  /// ⚠️ IMPORTANT: Never commit your real API key to version control!
  /// Consider using environment variables or a secure configuration file.
  static const String apiKey = 'YOUR_OPENAI_API_KEY_HERE';

  /// OpenAI API base URL
  static const String baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Model to use for vision analysis
  static const String model = 'gpt-4o-mini';

  /// Maximum tokens for response
  static const int maxTokens = 500;

  /// Temperature for response generation (0.0 = deterministic, 1.0 = creative)
  static const double temperature = 0.1;
}
