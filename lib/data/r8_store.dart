import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import 'mock_store.dart';

/// App-facing store. Prefer [R8Store.create] so UI stays the same for mock/Firebase.
abstract class R8Store extends ChangeNotifier {
  UserProfile? get currentUser;
  Map<String, UserProfile> get users;
  List<Job> get jobs;
  List<Offer> get offers;
  List<Conversation> get conversations;
  List<ChatMessage> get messages;
  List<Review> get reviews;
  List<ReportCase> get reports;
  List<AppNotification> get notifications;
  List<AuditEvent> get audit;
  String? get lastError;

  Future<void> init();
  void disposeStore();

  bool requestOtp(String phone);
  Future<bool> verifyOtp(String phone, String otp);
  /// Real Firebase phone auth — starts SMS; returns verificationId.
  Future<String?> startPhoneAuth(String phoneE164);
  Future<bool> confirmPhoneAuth({required String verificationId, required String smsCode});
  Future<void> logout();

  Future<void> updateProfile(UserProfile updated);
  List<UserProfile> discover({String? category, String? areaQuery});

  Future<Job?> createJob({
    required String title,
    required String description,
    required String category,
    required String approxLocation,
    required PriceMode priceMode,
    required DurationType durationType,
    double? fixedAmount,
    String scheduleNote = '',
  });

  Future<Offer?> submitOffer({
    required String jobId,
    required String scope,
    required double amount,
    required String schedule,
  });

  Future<bool> customerAcceptOffer(String offerId);
  Future<bool> workerConfirmOffer(String offerId);
  Future<bool> declineOffer(String offerId);
  Future<void> markInProgress(String jobId);
  Future<void> confirmCompletion(String jobId, {required bool asCustomer});
  Future<void> cancelJob(String jobId, String reason);
  Future<void> reportNoShow(String jobId);
  Future<void> openDispute(String jobId);
  Future<String?> addReview({
    required String jobId,
    required String recipientId,
    required int rating,
    required String text,
  });

  Future<Conversation> startChat(String otherUserId, {String? jobId});
  Future<void> sendMessage(String conversationId, String text);
  Future<void> blockUser(String userId);
  Future<void> report({
    required ReportTarget target,
    required String targetId,
    required String reason,
  });
  Future<void> adminResolveReport(String reportId, String notes, String action);
  Future<void> requestAccountDeletion();

  List<Offer> offersForJob(String jobId);
  List<ChatMessage> messagesFor(String conversationId);
  UserProfile? user(String id);

  static R8Store create({required bool useMock}) {
    if (useMock) return MockR8Store();
    return FirebaseR8Store();
  }
}

/// Thin adapter so existing mock logic still works in tests / offline demos.
class MockR8Store extends R8Store {
  MockR8Store() {
    _inner.seed();
    _inner.addListener(notifyListeners);
  }

  final MockStore _inner = MockStore();

  @override
  UserProfile? get currentUser => _inner.currentUser;
  @override
  Map<String, UserProfile> get users => _inner.users;
  @override
  List<Job> get jobs => _inner.jobs;
  @override
  List<Offer> get offers => _inner.offers;
  @override
  List<Conversation> get conversations => _inner.conversations;
  @override
  List<ChatMessage> get messages => _inner.messages;
  @override
  List<Review> get reviews => _inner.reviews;
  @override
  List<ReportCase> get reports => _inner.reports;
  @override
  List<AppNotification> get notifications => _inner.notifications;
  @override
  List<AuditEvent> get audit => _inner.audit;
  @override
  String? get lastError => _inner.lastError;

  @override
  Future<void> init() async {}

  @override
  void disposeStore() {
    _inner.removeListener(notifyListeners);
  }

  @override
  bool requestOtp(String phone) => _inner.requestOtp(phone);

  @override
  Future<bool> verifyOtp(String phone, String otp) async =>
      _inner.verifyOtp(phone, otp);

  @override
  Future<String?> startPhoneAuth(String phoneE164) async {
    requestOtp(phoneE164);
    return 'mock-verification-id';
  }

  @override
  Future<bool> confirmPhoneAuth({
    required String verificationId,
    required String smsCode,
  }) async {
    // phone stored separately in mock login screens
    return verifyOtp(_pendingPhone ?? '', smsCode);
  }

  String? _pendingPhone;
  void setPendingPhone(String p) => _pendingPhone = p;

  @override
  Future<void> logout() async => _inner.logout();

  @override
  Future<void> updateProfile(UserProfile updated) async =>
      _inner.updateProfile(updated);

  @override
  List<UserProfile> discover({String? category, String? areaQuery}) =>
      _inner.discover(category: category, areaQuery: areaQuery);

  @override
  Future<Job?> createJob({
    required String title,
    required String description,
    required String category,
    required String approxLocation,
    required PriceMode priceMode,
    required DurationType durationType,
    double? fixedAmount,
    String scheduleNote = '',
  }) async =>
      _inner.createJob(
        title: title,
        description: description,
        category: category,
        approxLocation: approxLocation,
        priceMode: priceMode,
        durationType: durationType,
        fixedAmount: fixedAmount,
        scheduleNote: scheduleNote,
      );

  @override
  Future<Offer?> submitOffer({
    required String jobId,
    required String scope,
    required double amount,
    required String schedule,
  }) async =>
      _inner.submitOffer(
        jobId: jobId,
        scope: scope,
        amount: amount,
        schedule: schedule,
      );

  @override
  Future<bool> customerAcceptOffer(String offerId) async =>
      _inner.customerAcceptOffer(offerId);

  @override
  Future<bool> workerConfirmOffer(String offerId) async =>
      _inner.workerConfirmOffer(offerId);

  @override
  Future<bool> declineOffer(String offerId) async =>
      _inner.declineOffer(offerId);

  @override
  Future<void> markInProgress(String jobId) async =>
      _inner.markInProgress(jobId);

  @override
  Future<void> confirmCompletion(String jobId, {required bool asCustomer}) async =>
      _inner.confirmCompletion(jobId, asCustomer: asCustomer);

  @override
  Future<void> cancelJob(String jobId, String reason) async =>
      _inner.cancelJob(jobId, reason);

  @override
  Future<void> reportNoShow(String jobId) async => _inner.reportNoShow(jobId);

  @override
  Future<void> openDispute(String jobId) async => _inner.openDispute(jobId);

  @override
  Future<String?> addReview({
    required String jobId,
    required String recipientId,
    required int rating,
    required String text,
  }) async =>
      _inner.addReview(
        jobId: jobId,
        recipientId: recipientId,
        rating: rating,
        text: text,
      );

  @override
  Future<Conversation> startChat(String otherUserId, {String? jobId}) async =>
      _inner.startChat(otherUserId, jobId: jobId);

  @override
  Future<void> sendMessage(String conversationId, String text) async =>
      _inner.sendMessage(conversationId, text);

  @override
  Future<void> blockUser(String userId) async => _inner.blockUser(userId);

  @override
  Future<void> report({
    required ReportTarget target,
    required String targetId,
    required String reason,
  }) async =>
      _inner.report(target: target, targetId: targetId, reason: reason);

  @override
  Future<void> adminResolveReport(
          String reportId, String notes, String action) async =>
      _inner.adminResolveReport(reportId, notes, action);

  @override
  Future<void> requestAccountDeletion() async =>
      _inner.requestAccountDeletion();

  @override
  List<Offer> offersForJob(String jobId) => _inner.offersForJob(jobId);

  @override
  List<ChatMessage> messagesFor(String conversationId) =>
      _inner.messagesFor(conversationId);

  @override
  UserProfile? user(String id) => _inner.user(id);
}

class FirebaseR8Store extends R8Store {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  late final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: AppConfig.functionsRegion,
  );

  final Map<String, UserProfile> _users = {};
  final List<Job> _jobs = [];
  final List<Offer> _offers = [];
  final List<Conversation> _conversations = [];
  final List<ChatMessage> _messages = [];
  final List<Review> _reviews = [];
  final List<ReportCase> _reports = [];
  final List<AppNotification> _notifications = [];
  final List<AuditEvent> _audit = [];

  UserProfile? _current;
  String? _lastError;
  final List<StreamSubscription> _subs = [];

  @override
  UserProfile? get currentUser => _current;
  @override
  Map<String, UserProfile> get users => _users;
  @override
  List<Job> get jobs => List.unmodifiable(_jobs);
  @override
  List<Offer> get offers => List.unmodifiable(_offers);
  @override
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  @override
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  @override
  List<Review> get reviews => List.unmodifiable(_reviews);
  @override
  List<ReportCase> get reports => List.unmodifiable(_reports);
  @override
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  @override
  List<AuditEvent> get audit => List.unmodifiable(_audit);
  @override
  String? get lastError => _lastError;

  @override
  Future<void> init() async {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _current = null;
        _clearCaches();
        notifyListeners();
        return;
      }
      await _ensureProfile(user);
      await _bindListeners(user.uid);
    });
  }

  void _clearCaches() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _users.clear();
    _jobs.clear();
    _offers.clear();
    _conversations.clear();
    _messages.clear();
    _reviews.clear();
    _reports.clear();
    _notifications.clear();
  }

  Future<void> _ensureProfile(User user) async {
    final ref = _db.collection('profiles').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'displayName': 'New user',
        'bio': '',
        'languages': ['Telugu', 'English'],
        'location': {
          'town': '',
          'district': '',
          'state': '',
          'pin': '',
          'showPin': false,
        },
        'categories': [],
        'skills': [],
        'experience': '',
        'serviceArea': '',
        'availability': '',
        'priceGuidance': '',
        'portfolioNote': '',
        'blockedUserIds': [],
        'deletionRequested': false,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('userPrivate').doc(user.uid).set({
        'uid': user.uid,
        'phone': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    _current = _profileFrom(await ref.get());
    _users[user.uid] = _current!;
    notifyListeners();
  }

  Future<void> _bindListeners(String uid) async {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();

    _subs.add(_db.collection('profiles').snapshots().listen((qs) {
      for (final d in qs.docs) {
        _users[d.id] = _profileFrom(d);
      }
      if (_users.containsKey(uid)) _current = _users[uid];
      notifyListeners();
    }));

    _subs.add(_db
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((qs) {
      _jobs
        ..clear()
        ..addAll(qs.docs.map(_jobFrom));
      notifyListeners();
    }));

    _subs.add(_db.collection('offers').limit(200).snapshots().listen((qs) {
      _offers
        ..clear()
        ..addAll(qs.docs.map(_offerFrom));
      notifyListeners();
    }));

    _subs.add(_db
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .listen((qs) async {
      _conversations
        ..clear()
        ..addAll(qs.docs.map(_conversationFrom));
      notifyListeners();
      for (final c in _conversations) {
        _subs.add(_db
            .collection('conversations')
            .doc(c.id)
            .collection('messages')
            .orderBy('sentAt')
            .limit(200)
            .snapshots()
            .listen((ms) {
          _messages.removeWhere((m) => m.conversationId == c.id);
          _messages.addAll(ms.docs.map(_messageFrom));
          notifyListeners();
        }));
      }
    }));

    _subs.add(_db
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((qs) {
      _notifications
        ..clear()
        ..addAll(qs.docs.map((d) {
          final m = d.data();
          return AppNotification(
            id: d.id,
            recipientId: m['recipientId'] as String,
            title: m['title'] as String? ?? '',
            body: m['body'] as String? ?? '',
            read: m['read'] as bool? ?? false,
            createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
          );
        }));
      notifyListeners();
    }));

    _subs.add(_db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((qs) {
      _reports
        ..clear()
        ..addAll(qs.docs.map(_reportFrom));
      notifyListeners();
    }, onError: (_) {
      // Non-admins cannot list all reports — ignore.
    }));
  }

  @override
  void disposeStore() {
    for (final s in _subs) {
      s.cancel();
    }
  }

  @override
  bool requestOtp(String phone) {
    _lastError = null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      _lastError = 'Enter a valid 10-digit mobile number.';
      notifyListeners();
      return false;
    }
    return true;
  }

  @override
  Future<String?> startPhoneAuth(String phoneE164) async {
    _lastError = null;
    final digits = phoneE164.replaceAll(RegExp(r'\D'), '');
    final e164 = digits.length == 10 ? '+91$digits' : phoneE164;
    final completer = Completer<String?>();
    await _auth.verifyPhoneNumber(
      phoneNumber: e164,
      timeout: const Duration(seconds: 60),
      verificationCompleted: ( cred) async {
        await _auth.signInWithCredential(cred);
        if (!completer.isCompleted) completer.complete(null);
      },
      verificationFailed: (e) {
        _lastError = e.message ?? 'Verification failed';
        notifyListeners();
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );
    try {
      return await completer.future;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> confirmPhoneAuth({
    required String verificationId,
    required String smsCode,
  }) async {
    _lastError = null;
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(cred);
      return true;
    } on FirebaseAuthException catch (e) {
      _lastError = e.message ?? 'Invalid OTP';
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> verifyOtp(String phone, String otp) async {
    // Mock path only — Firebase uses confirmPhoneAuth.
    _lastError = 'Use confirmPhoneAuth with Firebase.';
    notifyListeners();
    return false;
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    _current = null;
    _clearCaches();
    notifyListeners();
  }

  @override
  Future<void> updateProfile(UserProfile updated) async {
    await _db.collection('profiles').doc(updated.id).set({
      'uid': updated.id,
      'displayName': updated.displayName,
      'bio': updated.bio,
      'languages': updated.languages,
      'location': {
        'town': updated.location.town,
        'district': updated.location.district,
        'state': updated.location.state,
        'pin': updated.location.pin,
        'showPin': updated.location.showPin,
      },
      'categories': updated.categories,
      'skills': updated.skills,
      'experience': updated.experience,
      'serviceArea': updated.serviceArea,
      'availability': updated.availability,
      'priceGuidance': updated.priceGuidance,
      'portfolioNote': updated.portfolioNote,
      'blockedUserIds': updated.blockedUserIds.toList(),
      'deletionRequested': updated.deletionRequested,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  List<UserProfile> discover({String? category, String? areaQuery}) {
    final me = _current;
    return _users.values.where((u) {
      if (me != null && u.id == me.id) return false;
      if (me != null && me.blockedUserIds.contains(u.id)) return false;
      if (u.blockedUserIds.contains(me?.id)) return false;
      if (!u.isWorker) return false;
      if (category != null &&
          category.isNotEmpty &&
          !u.categories.contains(category)) {
        return false;
      }
      if (areaQuery != null && areaQuery.trim().isNotEmpty) {
        final q = areaQuery.toLowerCase();
        final hay = '${u.location.display} ${u.serviceArea}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Job?> createJob({
    required String title,
    required String description,
    required String category,
    required String approxLocation,
    required PriceMode priceMode,
    required DurationType durationType,
    double? fixedAmount,
    String scheduleNote = '',
  }) async {
    final me = _current;
    if (me == null) return null;
    if (title.trim().isEmpty || description.trim().isEmpty) {
      _lastError = 'Title and description are required.';
      notifyListeners();
      return null;
    }
    if (priceMode == PriceMode.fixed &&
        (fixedAmount == null || fixedAmount <= 0)) {
      _lastError = 'Fixed price jobs need a valid amount.';
      notifyListeners();
      return null;
    }
    final id = _uuid.v4();
    await _db.collection('jobs').doc(id).set({
      'ownerId': me.id,
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'approxLocation': approxLocation,
      'priceMode': priceMode.name,
      'durationType': durationType.name,
      'status': 'open',
      'fixedAmount': fixedAmount,
      'scheduleNote': scheduleNote,
      'photoNote': '',
      'customerCompleted': false,
      'workerCompleted': false,
      'hasDispute': false,
      'noShowReported': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _lastError = null;
    return _jobs.cast<Job?>().firstWhere((j) => j?.id == id, orElse: () => null) ??
        Job(
          id: id,
          ownerId: me.id,
          title: title.trim(),
          description: description.trim(),
          category: category,
          approxLocation: approxLocation,
          priceMode: priceMode,
          durationType: durationType,
          status: JobStatus.open,
          fixedAmount: fixedAmount,
          scheduleNote: scheduleNote,
        );
  }

  @override
  Future<Offer?> submitOffer({
    required String jobId,
    required String scope,
    required double amount,
    required String schedule,
  }) async {
    final me = _current;
    if (me == null) return null;
    final job = _jobs.cast<Job?>().firstWhere((j) => j?.id == jobId, orElse: () => null);
    if (job == null || job.ownerId == me.id) {
      _lastError = 'Invalid offer.';
      notifyListeners();
      return null;
    }
    final id = _uuid.v4();
    await _db.collection('offers').doc(id).set({
      'jobId': jobId,
      'workerId': me.id,
      'scope': scope,
      'amount': amount,
      'schedule': schedule,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Job status → hasOffers is applied by Cloud Function onOfferCreated.
    return Offer(
      id: id,
      jobId: jobId,
      workerId: me.id,
      scope: scope,
      amount: amount,
      schedule: schedule,
      status: OfferStatus.pending,
    );
  }

  Future<bool> _call(String name, Map<String, dynamic> data) async {
    _lastError = null;
    try {
      await _functions.httpsCallable(name).call(data);
      return true;
    } on FirebaseFunctionsException catch (e) {
      _lastError = e.message ?? e.code;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = '$e';
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> customerAcceptOffer(String offerId) =>
      _call('customerAcceptOffer', {'offerId': offerId});

  @override
  Future<bool> workerConfirmOffer(String offerId) =>
      _call('workerConfirmOffer', {'offerId': offerId});

  @override
  Future<bool> declineOffer(String offerId) =>
      _call('declineOffer', {'offerId': offerId});

  @override
  Future<void> markInProgress(String jobId) async {
    await _call('markJobInProgress', {'jobId': jobId});
  }

  @override
  Future<void> confirmCompletion(String jobId, {required bool asCustomer}) async {
    await _call('confirmCompletion', {'jobId': jobId, 'asCustomer': asCustomer});
  }

  @override
  Future<void> cancelJob(String jobId, String reason) async {
    await _call('cancelJob', {'jobId': jobId, 'reason': reason});
  }

  @override
  Future<void> reportNoShow(String jobId) async {
    await _db.collection('jobs').doc(jobId).set({
      'noShowReported': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> openDispute(String jobId) async {
    await _db.collection('jobs').doc(jobId).set({
      'hasDispute': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<String?> addReview({
    required String jobId,
    required String recipientId,
    required int rating,
    required String text,
  }) async {
    final ok = await _call('addReview', {
      'jobId': jobId,
      'recipientId': recipientId,
      'rating': rating,
      'text': text,
    });
    return ok ? null : _lastError;
  }

  @override
  Future<Conversation> startChat(String otherUserId, {String? jobId}) async {
    final me = _current!;
    if (me.blockedUserIds.contains(otherUserId) ||
        (_users[otherUserId]?.blockedUserIds.contains(me.id) ?? false)) {
      throw StateError('Cannot chat: user blocked.');
    }
    final existing = _conversations.where((c) {
      final set = c.participantIds.toSet();
      return set.contains(me.id) &&
          set.contains(otherUserId) &&
          c.jobId == jobId;
    });
    if (existing.isNotEmpty) return existing.first;
    final id = _uuid.v4();
    await _db.collection('conversations').doc(id).set({
      'participantIds': [me.id, otherUserId],
      'jobId': jobId,
      'blocked': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return Conversation(
      id: id,
      participantIds: [me.id, otherUserId],
      jobId: jobId,
    );
  }

  @override
  Future<void> sendMessage(String conversationId, String text) async {
    final me = _current;
    if (me == null || text.trim().isEmpty) return;
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': me.id,
      'text': text.trim(),
      'sentAt': FieldValue.serverTimestamp(),
      'reported': false,
    });
  }

  @override
  Future<void> blockUser(String userId) async {
    final me = _current;
    if (me == null) return;
    final next = {...me.blockedUserIds, userId}.toList();
    await _db.collection('profiles').doc(me.id).update({
      'blockedUserIds': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final c in _conversations) {
      if (c.participantIds.contains(me.id) &&
          c.participantIds.contains(userId)) {
        await _db.collection('conversations').doc(c.id).update({'blocked': true});
      }
    }
  }

  @override
  Future<void> report({
    required ReportTarget target,
    required String targetId,
    required String reason,
  }) async {
    final me = _current;
    if (me == null) return;
    await _db.collection('reports').add({
      'reporterId': me.id,
      'target': target.name,
      'targetId': targetId,
      'reason': reason,
      'status': 'open',
      'adminNotes': '',
      'actionTaken': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> adminResolveReport(
      String reportId, String notes, String action) async {
    await _call('resolveReport', {
      'reportId': reportId,
      'notes': notes,
      'actionTaken': action,
    });
  }

  @override
  Future<void> requestAccountDeletion() async {
    final me = _current;
    if (me == null) return;
    await _db.collection('profiles').doc(me.id).update({
      'deletionRequested': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  List<Offer> offersForJob(String jobId) =>
      _offers.where((o) => o.jobId == jobId).toList();

  @override
  List<ChatMessage> messagesFor(String conversationId) =>
      _messages.where((m) => m.conversationId == conversationId).toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  @override
  UserProfile? user(String id) => _users[id];

  // --- mappers ---
  UserProfile _profileFrom(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final loc = Map<String, dynamic>.from(m['location'] as Map? ?? {});
    return UserProfile(
      id: d.id,
      phone: '', // never from public profile
      displayName: m['displayName'] as String? ?? 'User',
      bio: m['bio'] as String? ?? '',
      languages: List<String>.from(m['languages'] as List? ?? const []),
      location: PublicLocation(
        town: loc['town'] as String?,
        district: loc['district'] as String?,
        state: loc['state'] as String?,
        pin: loc['pin'] as String?,
        showPin: loc['showPin'] as bool? ?? false,
      ),
      categories: List<String>.from(m['categories'] as List? ?? const []),
      skills: List<String>.from(m['skills'] as List? ?? const []),
      experience: m['experience'] as String? ?? '',
      serviceArea: m['serviceArea'] as String? ?? '',
      availability: m['availability'] as String? ?? '',
      priceGuidance: m['priceGuidance'] as String? ?? '',
      portfolioNote: m['portfolioNote'] as String? ?? '',
      blockedUserIds: Set<String>.from(m['blockedUserIds'] as List? ?? const []),
      deletionRequested: m['deletionRequested'] as bool? ?? false,
    );
  }

  Job _jobFrom(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Job(
      id: d.id,
      ownerId: m['ownerId'] as String,
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      category: m['category'] as String? ?? '',
      approxLocation: m['approxLocation'] as String? ?? '',
      priceMode: PriceMode.values.byName(m['priceMode'] as String? ?? 'quoteRequest'),
      durationType:
          DurationType.values.byName(m['durationType'] as String? ?? 'custom'),
      status: JobStatus.values.byName(m['status'] as String? ?? 'open'),
      fixedAmount: (m['fixedAmount'] as num?)?.toDouble(),
      scheduleNote: m['scheduleNote'] as String? ?? '',
      photoNote: m['photoNote'] as String? ?? '',
      customerCompleted: m['customerCompleted'] as bool? ?? false,
      workerCompleted: m['workerCompleted'] as bool? ?? false,
      hasDispute: m['hasDispute'] as bool? ?? false,
      cancelReason: m['cancelReason'] as String?,
      noShowReported: m['noShowReported'] as bool? ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Offer _offerFrom(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Offer(
      id: d.id,
      jobId: m['jobId'] as String,
      workerId: m['workerId'] as String,
      scope: m['scope'] as String? ?? '',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      schedule: m['schedule'] as String? ?? '',
      status: OfferStatus.values.byName(m['status'] as String? ?? 'pending'),
      customerAcceptedAt: (m['customerAcceptedAt'] as Timestamp?)?.toDate(),
      workerAcceptedAt: (m['workerAcceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Conversation _conversationFrom(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Conversation(
      id: d.id,
      participantIds: List<String>.from(m['participantIds'] as List? ?? const []),
      jobId: m['jobId'] as String?,
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
      blocked: m['blocked'] as bool? ?? false,
    );
  }

  ChatMessage _messageFrom(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return ChatMessage(
      id: d.id,
      conversationId: d.reference.parent.parent!.id,
      senderId: m['senderId'] as String,
      text: m['text'] as String? ?? '',
      sentAt: (m['sentAt'] as Timestamp?)?.toDate(),
      reported: m['reported'] as bool? ?? false,
    );
  }

  ReportCase _reportFrom(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return ReportCase(
      id: d.id,
      reporterId: m['reporterId'] as String,
      target: ReportTarget.values.byName(m['target'] as String? ?? 'safety'),
      targetId: m['targetId'] as String? ?? '',
      reason: m['reason'] as String? ?? '',
      status: ReportStatus.values.byName(m['status'] as String? ?? 'open'),
      adminNotes: m['adminNotes'] as String? ?? '',
      actionTaken: m['actionTaken'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
