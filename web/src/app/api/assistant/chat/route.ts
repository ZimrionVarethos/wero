import { NextRequest, NextResponse } from 'next/server';

const SYSTEM_INSTRUCTION =
  'Anda adalah Siaga AI, asisten resmi kesiapsiagaan bencana dan tanggap ' +
  'darurat Indonesia berstandar BNPB, BMKG, dan BASARNAS. Berikan instruksi ' +
  'keselamatan cepat, taktis, bernomor, dan tenang. Tekankan tindakan ' +
  'penyelamatan diri, larangan berbahaya, dan nomor darurat bila relevan ' +
  '(112 Darurat Umum, 115 Basarnas, 113 Damkar, 119 Medis, 117 BNPB). ' +
  'Jawab selalu dalam Bahasa Indonesia.';

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const message = body.message?.trim();
    const previousMessages = body.previousMessages || [];

    if (!message) {
      return NextResponse.json(
        { success: false, error: 'Pesan pengguna tidak boleh kosong' },
        {
          status: 400,
          headers: { 'Access-Control-Allow-Origin': '*' },
        }
      );
    }

    const apiKey = process.env.GEMINI_API_KEY;
    const model = process.env.GEMINI_MODEL || 'gemini-flash-lite-latest';

    if (!apiKey) {
      return NextResponse.json(
        {
          success: false,
          error: 'GEMINI_API_KEY belum dikonfigurasi di server backend.',
        },
        {
          status: 500,
          headers: { 'Access-Control-Allow-Origin': '*' },
        }
      );
    }

    // Format chat contents
    const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

    const recent = previousMessages.length > 6
      ? previousMessages.slice(previousMessages.length - 6)
      : previousMessages;

    for (const m of recent) {
      contents.push({
        role: m.role === 'user' ? 'user' : 'model',
        parts: [{ text: m.text }],
      });
    }

    contents.push({
      role: 'user',
      parts: [{ text: message }],
    });

    const geminiPayload = {
      systemInstruction: {
        parts: [{ text: SYSTEM_INSTRUCTION }],
      },
      contents,
    };

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: JSON.stringify(geminiPayload),
      }
    );

    if (!response.ok) {
      const errText = await response.text();
      console.error('Gemini API Error:', response.status, errText);
      return NextResponse.json(
        { success: false, error: 'Gagal menghubungi layanan AI Gemini.' },
        {
          status: 502,
          headers: { 'Access-Control-Allow-Origin': '*' },
        }
      );
    }

    const data = await response.json();
    const replyText =
      data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ||
      'Maaf, tidak dapat menghasilkan jawaban saat ini.';

    // Resolve quick action chips
    const actions: Array<{
      label: string;
      route?: string;
      phoneNumber?: string;
      iconName?: string;
    }> = [];

    const lower = `${message} ${replyText}`.toLowerCase();
    if (lower.includes('gempa')) {
      actions.push({
        label: 'Panduan Gempa',
        route: '/guides/detail',
        iconName: 'menu_book',
      });
    }
    if (lower.includes('banjir')) {
      actions.push({
        label: 'Panduan Banjir',
        route: '/guides/detail',
        iconName: 'menu_book',
      });
    }
    if (lower.includes('112')) {
      actions.push({
        label: 'Panggil 112',
        phoneNumber: '112',
        iconName: 'phone',
      });
    }
    if (lower.includes('115') || lower.includes('basarnas')) {
      actions.push({
        label: 'Panggil 115',
        phoneNumber: '115',
        iconName: 'phone',
      });
    }
    if (lower.includes('evakuasi') || lower.includes('posko')) {
      actions.push({
        label: 'Peta Evakuasi',
        route: '/evacuation',
        iconName: 'map',
      });
    }

    return NextResponse.json(
      {
        success: true,
        text: replyText,
        suggestedActions: actions.slice(0, 3),
      },
      {
        headers: {
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (error: any) {
    console.error('AI chat endpoint error:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Terjadi kesalahan server.' },
      {
        status: 500,
        headers: { 'Access-Control-Allow-Origin': '*' },
      }
    );
  }
}
