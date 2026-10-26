const serviceCategories = [
  'Cleaner',
  'Cook',
  'Maid',
  'Plumber',
  'Electrician',
  'Carpenter',
  'Painter',
  'Driver',
  'Construction labour',
];

enum PriceMode { fixed, negotiable, quoteRequest }

enum JobStatus {
  open,
  hasOffers,
  pendingWorkerAccept,
  scheduled,
  inProgress,
  completionPending,
  completed,
  cancelled,
  disputed,
}

enum OfferStatus { pending, customerAccepted, confirmed, declined, withdrawn }

enum DurationType { hourly, halfDay, fullDay, multiDay, custom }

enum ReportTarget { profile, job, message, safety }

enum ReportStatus { open, reviewing, resolved, dismissed }

class PublicLocation {
  const PublicLocation({
    this.town,
    this.district,
    this.state,
    this.pin,
    this.showPin = false,
  });

  final String? town;
  final String? district;
  final String? state;
  final String? pin;
  final bool showPin;

  String get display {
    final parts = <String>[
      if (town != null && town!.isNotEmpty) town!,
      if (district != null && district!.isNotEmpty) '$district District',
      if (state != null && state!.isNotEmpty) state!,
      if (showPin && pin != null && pin!.isNotEmpty) 'PIN $pin',
    ];
    return parts.isEmpty ? 'Location hidden' : parts.join(', ');
  }

  PublicLocation copyWith({
    String? town,
    String? district,
    String? state,
    String? pin,
    bool? showPin,
  }) =>
      PublicLocation(
        town: town ?? this.town,
        district: district ?? this.district,
        state: state ?? this.state,
        pin: pin ?? this.pin,
        showPin: showPin ?? this.showPin,
      );
}

class UserProfile {
  UserProfile({
    required this.id,
    required this.phone,
    required this.displayName,
    this.bio = '',
    this.languages = const ['Telugu', 'English'],
    this.location = const PublicLocation(),
    this.categories = const [],
    this.skills = const [],
    this.experience = '',
    this.serviceArea = '',
    this.availability = '',
    this.priceGuidance = '',
    this.portfolioNote = '',
    this.blockedUserIds = const {},
    this.deletionRequested = false,
  });

  final String id;
  final String phone;
  String displayName;
  String bio;
  List<String> languages;
  PublicLocation location;
  List<String> categories;
  List<String> skills;
  String experience;
  String serviceArea;
  String availability;
  String priceGuidance;
  String portfolioNote;
  Set<String> blockedUserIds;
  bool deletionRequested;

  bool get isWorker => categories.isNotEmpty || skills.isNotEmpty;

  UserProfile copy() => UserProfile(
        id: id,
        phone: phone,
        displayName: displayName,
        bio: bio,
        languages: List.of(languages),
        location: location,
        categories: List.of(categories),
        skills: List.of(skills),
        experience: experience,
        serviceArea: serviceArea,
        availability: availability,
        priceGuidance: priceGuidance,
        portfolioNote: portfolioNote,
        blockedUserIds: Set.of(blockedUserIds),
        deletionRequested: deletionRequested,
      );
}

class Job {
  Job({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.approxLocation,
    required this.priceMode,
    required this.durationType,
    required this.status,
    this.fixedAmount,
    this.scheduleNote = '',
    this.photoNote = '',
    this.customerCompleted = false,
    this.workerCompleted = false,
    this.hasDispute = false,
    this.cancelReason,
    this.noShowReported = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String ownerId;
  String title;
  String description;
  String category;
  String approxLocation;
  PriceMode priceMode;
  DurationType durationType;
  JobStatus status;
  double? fixedAmount;
  String scheduleNote;
  String photoNote;
  bool customerCompleted;
  bool workerCompleted;
  bool hasDispute;
  String? cancelReason;
  bool noShowReported;
  final DateTime createdAt;

  bool get bothCompleted => customerCompleted && workerCompleted;
}

class Offer {
  Offer({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.scope,
    required this.amount,
    required this.schedule,
    required this.status,
    this.customerAcceptedAt,
    this.workerAcceptedAt,
  });

  final String id;
  final String jobId;
  final String workerId;
  String scope;
  double amount;
  String schedule;
  OfferStatus status;
  DateTime? customerAcceptedAt;
  DateTime? workerAcceptedAt;
}

class Conversation {
  Conversation({
    required this.id,
    required this.participantIds,
    this.jobId,
    DateTime? updatedAt,
    this.blocked = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final List<String> participantIds;
  final String? jobId;
  DateTime updatedAt;
  bool blocked;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    DateTime? sentAt,
    this.reported = false,
  }) : sentAt = sentAt ?? DateTime.now();

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  bool reported;
}

class Review {
  Review({
    required this.id,
    required this.jobId,
    required this.authorId,
    required this.recipientId,
    required this.rating,
    required this.text,
  });

  final String id;
  final String jobId;
  final String authorId;
  final String recipientId;
  final int rating;
  final String text;
}

class ReportCase {
  ReportCase({
    required this.id,
    required this.reporterId,
    required this.target,
    required this.targetId,
    required this.reason,
    required this.status,
    this.adminNotes = '',
    this.actionTaken = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String reporterId;
  final ReportTarget target;
  final String targetId;
  final String reason;
  ReportStatus status;
  String adminNotes;
  String actionTaken;
  final DateTime createdAt;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    this.read = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String recipientId;
  final String title;
  final String body;
  bool read;
  final DateTime createdAt;
}

class AuditEvent {
  AuditEvent({
    required this.id,
    required this.actorId,
    required this.action,
    required this.entity,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final String id;
  final String actorId;
  final String action;
  final String entity;
  final DateTime at;
}
