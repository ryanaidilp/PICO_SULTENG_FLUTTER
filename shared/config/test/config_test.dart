import 'package:flutter_test/flutter_test.dart';

import 'env/test_env.dart';

void main() {
  group(
    'config',
    () {
      group(
        'env',
        () {
          test(
            "baseUrl Should return 'API_BASE_URL'",
            () => expect(TestEnv.baseUrl, equals('API_BASE_URL')),
          );
          test(
            "onesignalAppId Should return 'ONESIGNAL_APP_ID'",
            () => expect(TestEnv.onesignalAppId, equals('ONESIGNAL_APP_ID')),
          );
          test(
            "newsapiApiKey Should return 'NEWS_API_KEY'",
            () => expect(TestEnv.newsapiApiKey, equals('NEWS_API_KEY')),
          );
        },
      );
    },
  );
}
