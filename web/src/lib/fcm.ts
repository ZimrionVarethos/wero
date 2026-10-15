import { getApps, initializeApp, cert, App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

function getFirebaseAdminApp(): App | null {
  const existingApps = getApps();
  if (existingApps.length > 0) {
    return existingApps[0]!;
  }

  let serviceAccount: any = null;
  let rawSa = process.env.FIREBASE_SERVICE_ACCOUNT || process.env.FIREBASE_CONFIG;
  if (!rawSa && process.env.FCM_SERVER_KEY) {
    const candidate = process.env.FCM_SERVER_KEY.trim();
    if (candidate.startsWith('{') || candidate.startsWith('eyJ') || candidate.includes('private_key')) {
      rawSa = candidate;
    }
  }

  if (rawSa && rawSa.trim().length > 0) {
    try {
      let trimmed = rawSa.trim();
      if ((trimmed.startsWith('"') && trimmed.endsWith('"')) || (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
        trimmed = trimmed.slice(1, -1);
      }
      if (trimmed.startsWith('{')) {
        serviceAccount = JSON.parse(trimmed);
      } else {
        // Attempt base64 decode
        try {
          const decoded = Buffer.from(trimmed, 'base64').toString('utf8');
          if (decoded.trim().startsWith('{')) {
            serviceAccount = JSON.parse(decoded);
          }
        } catch (_) {}
      }
    } catch (e: any) {
      console.error('[FCM] Failed to parse Service Account JSON:', e?.message);
    }
  } else if (process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID || 'wero-emergency',
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    };
  }

  if (serviceAccount && (serviceAccount.client_email || serviceAccount.clientEmail)) {
    const rawKey = serviceAccount.private_key || serviceAccount.privateKey || '';
    const cleanKey = typeof rawKey === 'string' ? rawKey.replace(/\\n/g, '\n') : '';

    if (cleanKey.includes('BEGIN PRIVATE KEY')) {
      try {
        if (getApps().length > 0) {
          return getApps()[0]!;
        }
        return initializeApp({
          credential: cert({
            projectId: serviceAccount.project_id || serviceAccount.projectId || 'wero-emergency',
            clientEmail: serviceAccount.client_email || serviceAccount.clientEmail,
            privateKey: cleanKey,
          }),
          projectId: serviceAccount.project_id || serviceAccount.projectId || 'wero-emergency',
        });
      } catch (err: any) {
        console.error('[FCM] Failed to initialize Firebase Admin app:', err?.message);
      }
    }
  }

  return null;
}

/**
 * Helper to dispatch Firebase Cloud Messaging (FCM) notifications to mobile devices.
 * Supports modern FCM HTTP v1 (via FIREBASE_SERVICE_ACCOUNT) with fallback to legacy FCM_SERVER_KEY.
 */
export async function sendFcmBroadcast({
  headline,
  severity,
  targetType,
  targetRegions,
}: {
  headline: string;
  severity: string;
  targetType: 'ALL' | 'SPECIFIC';
  targetRegions?: string[];
}) {
  const topics: string[] = [];
  if (targetType === 'ALL' || !targetRegions || targetRegions.length === 0) {
    topics.push('nasional');
  } else {
    for (const reg of targetRegions) {
      const clean = reg
        .trim()
        .toLowerCase()
        .replace(/kota|kabupaten|kab\./gi, '')
        .replace(/[^a-zA-Z0-9]/g, '_')
        .replace(/_+/g, '_')
        .trim();
      if (clean) {
        topics.push(`region_${clean}`);
      }
    }
  }

  const adminApp = getFirebaseAdminApp();
  const fcmKey = process.env.FCM_SERVER_KEY?.trim();

  // Diagnostics check for Web Push Certificate mistakenly used as server key
  if (fcmKey && (fcmKey.startsWith('BP6') || fcmKey.length > 80 && !fcmKey.startsWith('AAAA'))) {
    console.warn(
      '[FCM WARNING] FCM_SERVER_KEY appears to be a Web Push Certificate (VAPID key), NOT a Server Key! ' +
      'Legacy FCM requires an API Server Key starting with "AAAA...", or preferably, use FIREBASE_SERVICE_ACCOUNT for FCM HTTP v1.'
    );
  }

  let dispatchedCount = 0;

  // 1. Preferred Method: Firebase Admin FCM HTTP v1
  if (adminApp) {
    for (const topic of topics) {
      try {
        const messageId = await getMessaging(adminApp).send({
          topic: topic,
          notification: {
            title: `🚨 SIARAN DARURAT: ${severity.toUpperCase()}`,
            body: headline,
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'emergency_alerts',
              sound: 'default',
              defaultVibrateTimings: true,
              priority: 'high',
            },
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            severity: String(severity),
            topic: String(topic),
            target_type: String(targetType),
            headline: String(headline),
          },
        });
        console.log(`[FCM v1] Successfully dispatched to topic "${topic}":`, messageId);
        dispatchedCount++;
      } catch (e: any) {
        console.error(`[FCM v1] Failed sending to topic "${topic}":`, e?.message);
      }
    }
    return { success: true, method: 'v1', dispatched: dispatchedCount, topics };
  }

  // 2. Fallback Method: Legacy FCM HTTP endpoint
  if (fcmKey && fcmKey.startsWith('AAAA')) {
    for (const topic of topics) {
      try {
        const payload = {
          to: `/topics/${topic}`,
          priority: 'high',
          notification: {
            title: `🚨 SIARAN DARURAT: ${severity.toUpperCase()}`,
            body: headline,
            sound: 'default',
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            severity,
            topic,
            target_type: targetType,
            headline,
          },
        };

        const res = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `key=${fcmKey}`,
          },
          body: JSON.stringify(payload),
        });

        const json = await res.json();
        console.log(`[FCM Legacy] Dispatched to topic ${topic}:`, json);
        if (res.ok) dispatchedCount++;
      } catch (e: any) {
        console.error(`[FCM Legacy] Failed sending to topic ${topic}:`, e?.message);
      }
    }
    return { success: true, method: 'legacy', dispatched: dispatchedCount, topics };
  }

  console.warn(
    '[FCM] Neither FIREBASE_SERVICE_ACCOUNT (FCM v1) nor valid legacy FCM_SERVER_KEY is configured in environment. Skipping push.'
  );
  return {
    success: false,
    method: 'none',
    dispatched: 0,
    topics,
    reason: 'Neither FIREBASE_SERVICE_ACCOUNT nor valid legacy FCM_SERVER_KEY is configured',
  };
}

