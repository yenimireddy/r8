import 'package:flutter_test/flutter_test.dart';
import 'package:r8/app.dart';
import 'package:r8/data/mock_store.dart';

void main() {
  testWidgets('Login screen shows R8 branding', (tester) async {
    final store = MockStore()..seed();
    await tester.pumpWidget(R8App(store: store));
    expect(find.text('R8'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  test('Mock OTP accepts 123456 and creates dual-role session', () {
    final store = MockStore()..seed();
    expect(store.requestOtp('9876543210'), isTrue);
    expect(store.verifyOtp('9876543210', '000000'), isFalse);
    expect(store.verifyOtp('9876543210', mockOtp), isTrue);
    expect(store.currentUser, isNotNull);
  });

  test('Booking needs dual acceptance', () {
    final store = MockStore()..seed();
    store.verifyOtp('9876543210', mockOtp);
    final offer = store.offers.first;
    expect(store.customerAcceptOffer(offer.id), isTrue);
    expect(store.jobs.firstWhere((j) => j.id == offer.jobId).status.name, 'pendingWorkerAccept');
    // switch to worker by logging as ravi is not supported; confirm path exists
    store.currentUser = store.users['u_ravi'];
    expect(store.workerConfirmOffer(offer.id), isTrue);
    expect(offer.status.name, 'confirmed');
  });

  test('Public location never includes home coordinates fields', () {
    final store = MockStore()..seed();
    final ravi = store.users['u_ravi']!;
    expect(ravi.location.display.contains('GPS'), isFalse);
    expect(ravi.location.showPin, isTrue);
    expect(ravi.location.display.contains('PIN'), isTrue);
  });
}
