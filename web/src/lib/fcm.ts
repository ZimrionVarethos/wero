/**
 * Helper to dispatch Firebase Cloud Messaging (FCM) notifications to mobile devices.
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
  const fcmKey = process.env.FCM_SERVER_KEY;
  if (!fcmKey) {
    console.log('[FCM] FCM_SERVER_KEY not configured in environment. Skipping push dispatch.');
    return;
  }

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
      console.log(`[FCM] Dispatched to topic ${topic}:`, json);
    } catch (e: any) {
      console.error(`[FCM] Failed sending to topic ${topic}:`, e?.message);
    }
  }
}
