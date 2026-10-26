import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as functionsV1 from "firebase-functions/v1";
import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({ region: "asia-south1", maxInstances: 20 });

admin.initializeApp();
const db = admin.firestore();

async function audit(actorId: string, action: string, entity: string, meta?: object) {
  await db.collection("audit").add({
    actorId,
    action,
    entity,
    meta: meta ?? {},
    at: FieldValue.serverTimestamp(),
  });
}

async function notify(recipientId: string, title: string, body: string, type: string, relatedId?: string) {
  await db.collection("notifications").add({
    recipientId,
    title,
    body,
    type,
    relatedId: relatedId ?? null,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function hitRateLimit(uid: string, bucket: string, max: number, windowSeconds: number) {
  const ref = db.collection("rateLimits").doc(`${uid}_${bucket}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const data = snap.data() ?? { count: 0, resetAt: now + windowSeconds * 1000 };
    if (now > (data.resetAt as number)) {
      tx.set(ref, { count: 1, resetAt: now + windowSeconds * 1000 });
      return;
    }
    if ((data.count as number) >= max) {
      throw new HttpsError("resource-exhausted", `Rate limit: ${bucket}. Try again later.`);
    }
    tx.update(ref, { count: FieldValue.increment(1) });
  });
}

/** Ensure profile docs exist for every new Auth user. */
export const bootstrapUser = functionsV1
  .region("asia-south1")
  .auth.user()
  .onCreate(async (user) => {
    const uid = user.uid;
    const phone = user.phoneNumber ?? "";
    const batch = db.batch();
    batch.set(
      db.collection("profiles").doc(uid),
      {
        uid,
        displayName: "New user",
        bio: "",
        languages: ["Telugu", "English"],
        location: {
          town: "",
          district: "",
          state: "",
          pin: "",
          showPin: false,
        },
        categories: [],
        skills: [],
        experience: "",
        serviceArea: "",
        availability: "",
        priceGuidance: "",
        portfolioNote: "",
        blockedUserIds: [],
        deletionRequested: false,
        status: "active",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    batch.set(
      db.collection("userPrivate").doc(uid),
      {
        uid,
        phone,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    await batch.commit();
    await audit(uid, "auth.user_created", uid);
  });

/** Customer accepts an offer → pendingWorkerAccept (not booked yet). */
export const customerAcceptOffer = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const uid = request.auth.uid;
  const offerId = String(request.data?.offerId ?? "");
  if (!offerId) throw new HttpsError("invalid-argument", "offerId required");

  await hitRateLimit(uid, "offer_accept", 30, 3600);

  await db.runTransaction(async (tx) => {
    const offerRef = db.collection("offers").doc(offerId);
    const offerSnap = await tx.get(offerRef);
    if (!offerSnap.exists) throw new HttpsError("not-found", "Offer not found");
    const offer = offerSnap.data()!;
    if (offer.status !== "pending") {
      throw new HttpsError("failed-precondition", "Offer is not pending");
    }
    const jobRef = db.collection("jobs").doc(offer.jobId);
    const jobSnap = await tx.get(jobRef);
    if (!jobSnap.exists) throw new HttpsError("not-found", "Job not found");
    const job = jobSnap.data()!;
    if (job.ownerId !== uid) throw new HttpsError("permission-denied", "Only job owner can accept");

    tx.update(offerRef, {
      status: "customerAccepted",
      customerAcceptedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(jobRef, {
      status: "pendingWorkerAccept",
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  const offer = (await db.collection("offers").doc(offerId).get()).data()!;
  await notify(offer.workerId, "Offer accepted", "Confirm the same final terms to book.", "offer", offerId);
  await audit(uid, "offer.customer_accept", offerId);
  return { ok: true };
});

/** Worker confirms same terms → booking scheduled. */
export const workerConfirmOffer = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const uid = request.auth.uid;
  const offerId = String(request.data?.offerId ?? "");
  if (!offerId) throw new HttpsError("invalid-argument", "offerId required");

  await hitRateLimit(uid, "offer_confirm", 30, 3600);

  let jobOwnerId = "";
  await db.runTransaction(async (tx) => {
    const offerRef = db.collection("offers").doc(offerId);
    const offerSnap = await tx.get(offerRef);
    if (!offerSnap.exists) throw new HttpsError("not-found", "Offer not found");
    const offer = offerSnap.data()!;
    if (offer.workerId !== uid) throw new HttpsError("permission-denied", "Only worker can confirm");
    if (offer.status !== "customerAccepted") {
      throw new HttpsError("failed-precondition", "Customer must accept first");
    }
    const jobRef = db.collection("jobs").doc(offer.jobId);
    const jobSnap = await tx.get(jobRef);
    if (!jobSnap.exists) throw new HttpsError("not-found", "Job not found");
    const job = jobSnap.data()!;
    jobOwnerId = job.ownerId;

    tx.update(offerRef, {
      status: "confirmed",
      workerAcceptedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(jobRef, {
      status: "scheduled",
      confirmedOfferId: offerId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Decline sibling offers
    const siblings = await db.collection("offers").where("jobId", "==", offer.jobId).get();
    // Note: cannot query inside transaction easily for all; decline after.
  });

  const offerSnap = await db.collection("offers").doc(offerId).get();
  const offer = offerSnap.data()!;
  const siblings = await db.collection("offers").where("jobId", "==", offer.jobId).get();
  const batch = db.batch();
  siblings.docs.forEach((d) => {
    if (d.id !== offerId && ["pending", "customerAccepted"].includes(d.data().status)) {
      batch.update(d.ref, { status: "declined", updatedAt: FieldValue.serverTimestamp() });
    }
  });
  await batch.commit();

  await notify(jobOwnerId, "Booking confirmed", "Both parties accepted the same terms.", "booking", offer.jobId);
  await audit(uid, "offer.worker_confirm", offerId);
  return { ok: true };
});

export const declineOffer = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const uid = request.auth.uid;
  const offerId = String(request.data?.offerId ?? "");
  const offerRef = db.collection("offers").doc(offerId);
  const offerSnap = await offerRef.get();
  if (!offerSnap.exists) throw new HttpsError("not-found", "Offer not found");
  const offer = offerSnap.data()!;
  const job = (await db.collection("jobs").doc(offer.jobId).get()).data();
  if (!job) throw new HttpsError("not-found", "Job not found");
  if (job.ownerId !== uid && offer.workerId !== uid) {
    throw new HttpsError("permission-denied", "Not a participant");
  }
  await offerRef.update({ status: "declined", updatedAt: FieldValue.serverTimestamp() });
  await audit(uid, "offer.decline", offerId);
  return { ok: true };
});

export const confirmCompletion = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const uid = request.auth.uid;
  const jobId = String(request.data?.jobId ?? "");
  const asCustomer = Boolean(request.data?.asCustomer);
  if (!jobId) throw new HttpsError("invalid-argument", "jobId required");

  const jobRef = db.collection("jobs").doc(jobId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(jobRef);
    if (!snap.exists) throw new HttpsError("not-found", "Job not found");
    const job = snap.data()!;
    if (!["scheduled", "inProgress", "completionPending"].includes(job.status)) {
      throw new HttpsError("failed-precondition", "Job not in completable state");
    }
    const updates: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
    if (asCustomer) {
      if (job.ownerId !== uid) throw new HttpsError("permission-denied", "Not job owner");
      updates.customerCompleted = true;
    } else {
      const offerId = job.confirmedOfferId;
      if (!offerId) throw new HttpsError("failed-precondition", "No confirmed offer");
      const offer = (await tx.get(db.collection("offers").doc(offerId))).data();
      if (!offer || offer.workerId !== uid) throw new HttpsError("permission-denied", "Not confirmed worker");
      updates.workerCompleted = true;
    }
    const customerDone = asCustomer ? true : Boolean(job.customerCompleted);
    const workerDone = asCustomer ? Boolean(job.workerCompleted) : true;
    updates.status = customerDone && workerDone ? "completed" : "completionPending";
    tx.update(jobRef, updates);
  });

  await audit(uid, "job.completion", jobId, { asCustomer });
  return { ok: true };
});

export const addReview = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const uid = request.auth.uid;
  const jobId = String(request.data?.jobId ?? "");
  const recipientId = String(request.data?.recipientId ?? "");
  const rating = Number(request.data?.rating ?? 0);
  const text = String(request.data?.text ?? "").slice(0, 1000);
  if (!jobId || !recipientId) throw new HttpsError("invalid-argument", "Missing fields");
  if (rating < 1 || rating > 5) throw new HttpsError("invalid-argument", "Rating 1–5");

  const jobSnap = await db.collection("jobs").doc(jobId).get();
  if (!jobSnap.exists) throw new HttpsError("not-found", "Job not found");
  const job = jobSnap.data()!;
  if (job.status !== "completed") {
    throw new HttpsError("failed-precondition", "Reviews only for completed jobs");
  }

  const dup = await db
    .collection("reviews")
    .where("jobId", "==", jobId)
    .where("authorId", "==", uid)
    .where("recipientId", "==", recipientId)
    .limit(1)
    .get();
  if (!dup.empty) throw new HttpsError("already-exists", "Already reviewed");

  const ref = await db.collection("reviews").add({
    jobId,
    authorId: uid,
    recipientId,
    rating,
    text,
    createdAt: FieldValue.serverTimestamp(),
  });
  await audit(uid, "review.create", ref.id);
  await notify(recipientId, "New review", `You received a ${rating}-star review.`, "review", ref.id);
  return { ok: true, reviewId: ref.id };
});

export const resolveReport = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const uid = request.auth.uid;
  const adminDoc = await db.collection("admins").doc(uid).get();
  if (!adminDoc.exists) throw new HttpsError("permission-denied", "Admin only");

  const reportId = String(request.data?.reportId ?? "");
  const notes = String(request.data?.notes ?? "").slice(0, 2000);
  const actionTaken = String(request.data?.actionTaken ?? "").slice(0, 2000);
  if (!reportId) throw new HttpsError("invalid-argument", "reportId required");

  await db.collection("reports").doc(reportId).update({
    status: "resolved",
    adminNotes: notes,
    actionTaken,
    resolvedBy: uid,
    resolvedAt: FieldValue.serverTimestamp(),
  });
  await audit(uid, "report.resolve", reportId, { actionTaken });
  return { ok: true };
});

export const markJobInProgress = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const uid = request.auth.uid;
  const jobId = String(request.data?.jobId ?? "");
  const jobRef = db.collection("jobs").doc(jobId);
  const snap = await jobRef.get();
  if (!snap.exists) throw new HttpsError("not-found", "Job not found");
  const job = snap.data()!;
  const offerId = job.confirmedOfferId as string | undefined;
  let isWorker = false;
  if (offerId) {
    const offer = (await db.collection("offers").doc(offerId).get()).data();
    isWorker = offer?.workerId === uid;
  }
  if (job.ownerId !== uid && !isWorker) throw new HttpsError("permission-denied", "Not a participant");
  if (job.status !== "scheduled" && job.status !== "inProgress") {
    throw new HttpsError("failed-precondition", "Invalid status");
  }
  await jobRef.update({ status: "inProgress", updatedAt: FieldValue.serverTimestamp() });
  await audit(uid, "job.in_progress", jobId);
  return { ok: true };
});

export const cancelJob = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required");
  const uid = request.auth.uid;
  const jobId = String(request.data?.jobId ?? "");
  const reason = String(request.data?.reason ?? "Cancelled").slice(0, 500);
  const jobRef = db.collection("jobs").doc(jobId);
  const snap = await jobRef.get();
  if (!snap.exists) throw new HttpsError("not-found", "Job not found");
  const job = snap.data()!;
  if (job.ownerId !== uid) throw new HttpsError("permission-denied", "Owner only");
  await jobRef.update({
    status: "cancelled",
    cancelReason: reason,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await audit(uid, "job.cancel", jobId);
  return { ok: true };
});

/** When a worker submits an offer, mark job as hasOffers. */
export const onOfferCreated = onDocumentCreated("offers/{offerId}", async (event) => {
  const data = event.data?.data();
  if (!data) return;
  const jobRef = db.collection("jobs").doc(data.jobId);
  const job = await jobRef.get();
  if (!job.exists) return;
  if (job.data()?.status === "open") {
    await jobRef.update({
      status: "hasOffers",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await notify(
    job.data()!.ownerId,
    "New offer",
    `New offer of ₹${data.amount}`,
    "offer",
    event.params.offerId
  );
});

/** Create notification when a new message arrives (best-effort). */
export const onMessageCreated = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const conversationId = event.params.conversationId;
    const conv = (await db.collection("conversations").doc(conversationId).get()).data();
    if (!conv) return;
    const recipients = (conv.participantIds as string[]).filter((id) => id !== data.senderId);
    await Promise.all(
      recipients.map((rid) =>
        notify(rid, "New message", String(data.text).slice(0, 120), "chat", conversationId)
      )
    );
    await db.collection("conversations").doc(conversationId).update({
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
);
