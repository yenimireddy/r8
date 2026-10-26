import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

const mockOtp = '123456';
const categories = serviceCategories;

class MockStore extends ChangeNotifier {
  final _uuid = const Uuid();

  UserProfile? currentUser;
  final Map<String, UserProfile> users = {};
  final List<Job> jobs = [];
  final List<Offer> offers = [];
  final List<Conversation> conversations = [];
  final List<ChatMessage> messages = [];
  final List<Review> reviews = [];
  final List<ReportCase> reports = [];
  final List<AppNotification> notifications = [];
  final List<AuditEvent> audit = [];

  String? lastError;
  bool busy = false;

  void seed() {
    final me = UserProfile(
      id: 'u_me',
      phone: '9876543210',
      displayName: 'You',
      bio: 'Looking for help around Mandasa and offering painting on weekends.',
      location: const PublicLocation(
        town: 'Mandasa',
        district: 'Srikakulam',
        state: 'Andhra Pradesh',
        pin: '532242',
        showPin: false,
      ),
      categories: ['Painter'],
      skills: ['Interior painting', 'Touch-ups'],
      experience: '3 years',
      serviceArea: 'Mandasa, Palasa',
      availability: 'Weekends',
      priceGuidance: '₹600/day',
    );

    final ravi = UserProfile(
      id: 'u_ravi',
      phone: '9000000001',
      displayName: 'Ravi Kumar',
      bio: 'Plumber for homes and small shops.',
      location: const PublicLocation(
        town: 'Mandasa',
        district: 'Srikakulam',
        state: 'Andhra Pradesh',
        pin: '532242',
        showPin: true,
      ),
      categories: ['Plumber'],
      skills: ['Leak repair', 'Blocked pipes'],
      experience: '8 years',
      serviceArea: 'Mandasa, Sompeta',
      availability: 'Mon–Sat',
      priceGuidance: 'Quotes from ₹300',
    );

    final lakshmi = UserProfile(
      id: 'u_lakshmi',
      phone: '9000000002',
      displayName: 'Lakshmi',
      bio: 'Home cooking and cleaning.',
      location: const PublicLocation(
        town: 'Palasa',
        district: 'Srikakulam',
        state: 'Andhra Pradesh',
      ),
      categories: ['Cook', 'Cleaner'],
      skills: ['Veg meals', 'Deep clean'],
      experience: '5 years',
      serviceArea: 'Palasa, Mandasa',
      availability: 'Daily',
      priceGuidance: '₹500/day cleaning',
    );

    final suresh = UserProfile(
      id: 'u_suresh',
      phone: '9000000003',
      displayName: 'Suresh',
      bio: 'Electrical wiring and fan fitting.',
      location: const PublicLocation(
        town: 'Sompeta',
        district: 'Srikakulam',
        state: 'Andhra Pradesh',
      ),
      categories: ['Electrician'],
      skills: ['Wiring', 'Switches', 'Fans'],
      experience: '6 years',
      serviceArea: 'Sompeta, Mandasa',
      availability: 'On call',
      priceGuidance: '₹400 onwards',
    );

    users.addAll({
      me.id: me,
      ravi.id: ravi,
      lakshmi.id: lakshmi,
      suresh.id: suresh,
    });

    final job1 = Job(
      id: 'j1',
      ownerId: me.id,
      title: 'Blocked kitchen pipe',
      description: 'Sink backing up since yesterday. Need quote.',
      category: 'Plumber',
      approxLocation: 'Mandasa (general area)',
      priceMode: PriceMode.quoteRequest,
      durationType: DurationType.hourly,
      status: JobStatus.hasOffers,
      scheduleNote: 'Tomorrow morning preferred',
    );
    final job2 = Job(
      id: 'j2',
      ownerId: lakshmi.id,
      title: 'Two days house cleaning',
      description: '2BHK deep clean before guests arrive.',
      category: 'Cleaner',
      approxLocation: 'Palasa',
      priceMode: PriceMode.fixed,
      fixedAmount: 1000,
      durationType: DurationType.multiDay,
      status: JobStatus.open,
      scheduleNote: 'Sat–Sun, full day',
    );
    jobs.addAll([job1, job2]);

    offers.add(Offer(
      id: 'o1',
      jobId: job1.id,
      workerId: ravi.id,
      scope: 'Clear blockage + check trap',
      amount: 450,
      schedule: 'Tomorrow 9–11 AM',
      status: OfferStatus.pending,
    ));

    final c1 = Conversation(
      id: 'c1',
      participantIds: [me.id, ravi.id],
      jobId: job1.id,
    );
    conversations.add(c1);
    messages.addAll([
      ChatMessage(
        id: 'm1',
        conversationId: c1.id,
        senderId: me.id,
        text: 'Hi Ravi, can you look at our kitchen pipe?',
      ),
      ChatMessage(
        id: 'm2',
        conversationId: c1.id,
        senderId: ravi.id,
        text: 'Yes. I sent an offer for ₹450. Chat is not a booking.',
      ),
    ]);

    notifications.add(AppNotification(
      id: 'n1',
      recipientId: me.id,
      title: 'New offer',
      body: 'Ravi offered ₹450 on Blocked kitchen pipe',
    ));

    _audit(me.id, 'seed', 'store');
    notifyListeners();
  }

  // --- Auth ---
  bool requestOtp(String phone) {
    lastError = null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      lastError = 'Enter a valid 10-digit mobile number.';
      notifyListeners();
      return false;
    }
    // mock rate-limit hint
    return true;
  }

  bool verifyOtp(String phone, String otp) {
    lastError = null;
    if (otp != mockOtp) {
      lastError = 'Invalid OTP. Use $mockOtp for this mock build.';
      notifyListeners();
      return false;
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final existing = users.values.where((u) => u.phone == digits);
    if (existing.isNotEmpty) {
      currentUser = existing.first;
    } else {
      final id = _uuid.v4();
      final profile = UserProfile(
        id: id,
        phone: digits,
        displayName: 'New user',
        location: const PublicLocation(
          town: 'Mandasa',
          district: 'Srikakulam',
          state: 'Andhra Pradesh',
        ),
      );
      users[id] = profile;
      currentUser = profile;
    }
    _notify(currentUser!.id, 'Welcome', 'OTP verifies phone control only — not identity.');
    notifyListeners();
    return true;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // --- Profile ---
  void updateProfile(UserProfile updated) {
    users[updated.id] = updated;
    if (currentUser?.id == updated.id) currentUser = updated;
    _audit(updated.id, 'profile.update', updated.id);
    notifyListeners();
  }

  List<UserProfile> discover({String? category, String? areaQuery}) {
    final me = currentUser;
    return users.values.where((u) {
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
        final hay =
            '${u.location.display} ${u.serviceArea}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  // --- Jobs / offers ---
  Job? createJob({
    required String title,
    required String description,
    required String category,
    required String approxLocation,
    required PriceMode priceMode,
    required DurationType durationType,
    double? fixedAmount,
    String scheduleNote = '',
  }) {
    final me = currentUser;
    if (me == null) return null;
    if (title.trim().isEmpty || description.trim().isEmpty) {
      lastError = 'Title and description are required.';
      notifyListeners();
      return null;
    }
    if (priceMode == PriceMode.fixed && (fixedAmount == null || fixedAmount <= 0)) {
      lastError = 'Fixed price jobs need a valid amount.';
      notifyListeners();
      return null;
    }
    final job = Job(
      id: _uuid.v4(),
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
    jobs.insert(0, job);
    _audit(me.id, 'job.create', job.id);
    lastError = null;
    notifyListeners();
    return job;
  }

  Offer? submitOffer({
    required String jobId,
    required String scope,
    required double amount,
    required String schedule,
  }) {
    final me = currentUser;
    if (me == null) return null;
    final job = jobs.cast<Job?>().firstWhere((j) => j!.id == jobId, orElse: () => null);
    if (job == null) return null;
    if (job.ownerId == me.id) {
      lastError = 'You cannot offer on your own job.';
      notifyListeners();
      return null;
    }
    final offer = Offer(
      id: _uuid.v4(),
      jobId: jobId,
      workerId: me.id,
      scope: scope,
      amount: amount,
      schedule: schedule,
      status: OfferStatus.pending,
    );
    offers.add(offer);
    if (job.status == JobStatus.open) job.status = JobStatus.hasOffers;
    _notify(job.ownerId, 'New offer', '${me.displayName} offered ₹${amount.toStringAsFixed(0)}');
    _audit(me.id, 'offer.submit', offer.id);
    notifyListeners();
    return offer;
  }

  /// BR-06: customer accepts; booking confirmed only after worker accepts same terms.
  bool customerAcceptOffer(String offerId) {
    final me = currentUser;
    final offer = _offer(offerId);
    if (me == null || offer == null) return false;
    final job = _job(offer.jobId);
    if (job == null || job.ownerId != me.id) return false;
    offer.status = OfferStatus.customerAccepted;
    offer.customerAcceptedAt = DateTime.now();
    job.status = JobStatus.pendingWorkerAccept;
    _notify(offer.workerId, 'Offer accepted', 'Confirm the same final terms to book.');
    _audit(me.id, 'offer.customer_accept', offer.id);
    notifyListeners();
    return true;
  }

  bool workerConfirmOffer(String offerId) {
    final me = currentUser;
    final offer = _offer(offerId);
    if (me == null || offer == null || offer.workerId != me.id) return false;
    if (offer.status != OfferStatus.customerAccepted) {
      lastError = 'Customer must accept first.';
      notifyListeners();
      return false;
    }
    offer.status = OfferStatus.confirmed;
    offer.workerAcceptedAt = DateTime.now();
    final job = _job(offer.jobId)!;
    job.status = JobStatus.scheduled;
    // decline other pending offers on same job
    for (final o in offers.where((o) => o.jobId == job.id && o.id != offer.id)) {
      if (o.status == OfferStatus.pending ||
          o.status == OfferStatus.customerAccepted) {
        o.status = OfferStatus.declined;
      }
    }
    _notify(job.ownerId, 'Booking confirmed', 'Both parties accepted the same terms.');
    _audit(me.id, 'offer.worker_confirm', offer.id);
    notifyListeners();
    return true;
  }

  bool declineOffer(String offerId) {
    final offer = _offer(offerId);
    if (offer == null) return false;
    offer.status = OfferStatus.declined;
    _audit(currentUser?.id ?? 'system', 'offer.decline', offer.id);
    notifyListeners();
    return true;
  }

  void markInProgress(String jobId) {
    final job = _job(jobId);
    if (job == null) return;
    job.status = JobStatus.inProgress;
    _audit(currentUser?.id ?? '', 'job.in_progress', jobId);
    notifyListeners();
  }

  void confirmCompletion(String jobId, {required bool asCustomer}) {
    final me = currentUser;
    final job = _job(jobId);
    if (me == null || job == null) return;
    if (asCustomer) {
      if (job.ownerId != me.id) return;
      job.customerCompleted = true;
    } else {
      final confirmed = offers.any((o) =>
          o.jobId == jobId &&
          o.workerId == me.id &&
          o.status == OfferStatus.confirmed);
      if (!confirmed) return;
      job.workerCompleted = true;
    }
    if (job.bothCompleted) {
      job.status = JobStatus.completed;
      _notify(job.ownerId, 'Job completed', 'You can leave a review.');
    } else {
      job.status = JobStatus.completionPending;
    }
    _audit(me.id, 'job.completion', jobId);
    notifyListeners();
  }

  void cancelJob(String jobId, String reason) {
    final job = _job(jobId);
    if (job == null) return;
    job.status = JobStatus.cancelled;
    job.cancelReason = reason;
    _audit(currentUser?.id ?? '', 'job.cancel', jobId);
    notifyListeners();
  }

  void reportNoShow(String jobId) {
    final job = _job(jobId);
    if (job == null) return;
    job.noShowReported = true;
    // BR-10: no automatic punishment
    _audit(currentUser?.id ?? '', 'job.no_show_report', jobId);
    notifyListeners();
  }

  void openDispute(String jobId) {
    final job = _job(jobId);
    if (job == null) return;
    job.hasDispute = true;
    // BR-08: dispute separate from completion
    _audit(currentUser?.id ?? '', 'job.dispute', jobId);
    notifyListeners();
  }

  String? addReview({
    required String jobId,
    required String recipientId,
    required int rating,
    required String text,
  }) {
    final me = currentUser;
    final job = _job(jobId);
    if (me == null || job == null) return 'Not found';
    if (job.status != JobStatus.completed) {
      return 'Reviews only for eligible completed jobs.';
    }
    if (rating < 1 || rating > 5) return 'Rating must be 1–5';
    final dup = reviews.any(
        (r) => r.jobId == jobId && r.authorId == me.id && r.recipientId == recipientId);
    if (dup) return 'You already reviewed this party for this job.';
    reviews.add(Review(
      id: _uuid.v4(),
      jobId: jobId,
      authorId: me.id,
      recipientId: recipientId,
      rating: rating,
      text: text,
    ));
    _audit(me.id, 'review.create', jobId);
    notifyListeners();
    return null;
  }

  // --- Chat ---
  Conversation startChat(String otherUserId, {String? jobId}) {
    final me = currentUser!;
    if (me.blockedUserIds.contains(otherUserId) ||
        users[otherUserId]!.blockedUserIds.contains(me.id)) {
      throw StateError('Cannot chat: user blocked.');
    }
    final existing = conversations.where((c) {
      final set = c.participantIds.toSet();
      return set.contains(me.id) &&
          set.contains(otherUserId) &&
          c.jobId == jobId;
    });
    if (existing.isNotEmpty) return existing.first;
    // simple anti-spam: max 20 convos
    final mine = conversations.where((c) => c.participantIds.contains(me.id));
    if (mine.length >= 20) {
      throw StateError('Chat rate limit reached (mock).');
    }
    final c = Conversation(
      id: _uuid.v4(),
      participantIds: [me.id, otherUserId],
      jobId: jobId,
    );
    conversations.insert(0, c);
    _audit(me.id, 'chat.start', c.id);
    notifyListeners();
    return c;
  }

  void sendMessage(String conversationId, String text) {
    final me = currentUser;
    if (me == null || text.trim().isEmpty) return;
    final c = conversations.firstWhere((c) => c.id == conversationId);
    if (c.blocked) {
      lastError = 'Conversation blocked.';
      notifyListeners();
      return;
    }
    final other = c.participantIds.firstWhere((id) => id != me.id);
    if (me.blockedUserIds.contains(other)) {
      lastError = 'You blocked this user.';
      notifyListeners();
      return;
    }
    messages.add(ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: me.id,
      text: text.trim(),
    ));
    c.updatedAt = DateTime.now();
    _notify(other, 'New message', text.trim());
    notifyListeners();
  }

  void blockUser(String userId) {
    final me = currentUser;
    if (me == null) return;
    me.blockedUserIds = {...me.blockedUserIds, userId};
    for (final c in conversations) {
      if (c.participantIds.contains(me.id) &&
          c.participantIds.contains(userId)) {
        c.blocked = true;
      }
    }
    _audit(me.id, 'user.block', userId);
    notifyListeners();
  }

  void report({
    required ReportTarget target,
    required String targetId,
    required String reason,
  }) {
    final me = currentUser;
    if (me == null) return;
    reports.insert(
      0,
      ReportCase(
        id: _uuid.v4(),
        reporterId: me.id,
        target: target,
        targetId: targetId,
        reason: reason,
        status: ReportStatus.open,
      ),
    );
    _audit(me.id, 'report.create', targetId);
    notifyListeners();
  }

  void adminResolveReport(String reportId, String notes, String action) {
    final r = reports.firstWhere((r) => r.id == reportId);
    r.status = ReportStatus.resolved;
    r.adminNotes = notes;
    r.actionTaken = action;
    _audit('admin', 'report.resolve', reportId);
    notifyListeners();
  }

  void requestAccountDeletion() {
    final me = currentUser;
    if (me == null) return;
    me.deletionRequested = true;
    _audit(me.id, 'account.deletion_request', me.id);
    notifyListeners();
  }

  List<Offer> offersForJob(String jobId) =>
      offers.where((o) => o.jobId == jobId).toList();

  List<ChatMessage> messagesFor(String conversationId) => messages
      .where((m) => m.conversationId == conversationId)
      .toList()
    ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  UserProfile? user(String id) => users[id];

  Job? _job(String id) {
    try {
      return jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  Offer? _offer(String id) {
    try {
      return offers.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void _notify(String recipientId, String title, String body) {
    notifications.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        recipientId: recipientId,
        title: title,
        body: body,
      ),
    );
  }

  void _audit(String actorId, String action, String entity) {
    audit.insert(
      0,
      AuditEvent(
        id: _uuid.v4(),
        actorId: actorId,
        action: action,
        entity: entity,
      ),
    );
  }
}
