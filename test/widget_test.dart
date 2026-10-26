import 'package:flutter_test/flutter_test.dart';
import 'package:r8/app.dart';
import 'package:r8/data/mock_store.dart';
import 'package:r8/data/r8_store.dart';

void main() {
  testWidgets('Login screen shows R8 branding in mock mode', (tester) async {
    final store = R8Store.create(useMock: true);
    await store.init();
    await tester.pumpWidget(R8App(store: store, usingMock: true));
    expect(find.text('R8'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  test('Mock OTP accepts 123456', () async {
    final store = MockR8Store();
    await store.init();
    expect(store.requestOtp('9876543210'), isTrue);
    store.setPendingPhone('9876543210');
    expect(await store.verifyOtp('9876543210', '000000'), isFalse);
    expect(await store.verifyOtp('9876543210', mockOtp), isTrue);
    expect(store.currentUser, isNotNull);
  });

  test('Dual acceptance path exists on mock store', () async {
    final inner = MockStore()..seed();
    final offer = inner.offers.first;
    expect(inner.customerAcceptOffer(offer.id), isTrue);
    inner.currentUser = inner.users['u_ravi'];
    expect(inner.workerConfirmOffer(offer.id), isTrue);
    expect(offer.status.name, 'confirmed');
  });
}
