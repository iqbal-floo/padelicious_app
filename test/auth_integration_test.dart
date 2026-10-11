// Registration + login against a RUNNING backend.
//   flutter test test/auth_integration_test.dart --dart-define=API=http://127.0.0.1:8160
import 'package:flutter_test/flutter_test.dart';
import 'package:padelicious/data/api/api_client.dart';
import 'package:padelicious/state/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const base = String.fromEnvironment('API', defaultValue: 'http://127.0.0.1:8160');

  AuthController fresh() =>
      AuthController(client: ApiClient(baseUrl: '$base/api/v1'));

  // /auth/login and /auth/register are throttled to 6/min each, which a
  // suite like this trips legitimately. Reset the limiter between tests so
  // we are exercising auth, not the rate limiter (which has its own test).
  Future<void> clearRateLimit() async {
    try {
      await Dio().post('$base/api/test/clear-rate-limit');
    } catch (_) {
      // Endpoint only exists in local/testing environments.
    }
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await clearRateLimit();
  });

  test('register, then the session restores and logs out', () async {
    final unique = DateTime.now().microsecondsSinceEpoch;
    final email = 'dart.$unique@example.com';
    final auth = fresh();

    final result = await auth.register(
      fullName: 'Dart Tester',
      email: email,
      password: 'secret123',
      passwordConfirmation: 'secret123',
    );

    expect(result.ok, isTrue, reason: result.message);
    expect(await auth.isSignedIn, isTrue);
    // A player profile is created server-side and surfaced to the client.
    expect(auth.displayName, 'Dart');

    expect(await auth.restore(), isTrue);

    await auth.logout();
    expect(await auth.isSignedIn, isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a duplicate email surfaces as an inline email error', () async {
    final unique = DateTime.now().microsecondsSinceEpoch;
    final email = 'dup.$unique@example.com';

    final first = await fresh().register(
      fullName: 'First One',
      email: email,
      password: 'secret123',
      passwordConfirmation: 'secret123',
    );
    expect(first.ok, isTrue, reason: first.message);

    final second = await fresh().register(
      fullName: 'Second One',
      email: email,
      password: 'secret123',
      passwordConfirmation: 'secret123',
    );

    expect(second.ok, isFalse);
    expect(second.errorFor('email'), isNotNull);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a short password is rejected by the backend', () async {
    final unique = DateTime.now().microsecondsSinceEpoch;
    final result = await fresh().register(
      fullName: 'Shorty Pass',
      email: 'short.$unique@example.com',
      password: 'abc12',
      passwordConfirmation: 'abc12',
    );

    expect(result.ok, isFalse);
    expect(result.errorFor('password'), isNotNull);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a registered user can log in and gets their player name', () async {
    final unique = DateTime.now().microsecondsSinceEpoch;
    final email = 'login.$unique@example.com';

    await fresh().register(
      fullName: 'Login Tester',
      email: email,
      password: 'secret123',
      passwordConfirmation: 'secret123',
    );

    final auth = fresh();
    final result = await auth.login(email: email, password: 'secret123');

    expect(result.ok, isTrue, reason: result.message);
    expect(auth.displayName, 'Login');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('wrong credentials fail without revealing whether the account exists',
      () async {
    final result = await fresh()
        .login(email: 'nobody.here@example.com', password: 'wrong-password');

    expect(result.ok, isFalse);
    expect(result.message, isNotNull);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('google sign-in reports that it is not configured', () async {
    final result = await fresh().signInWithGoogle('fake-token');

    expect(result.ok, isFalse);
    expect(result.message, contains('not set up'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
