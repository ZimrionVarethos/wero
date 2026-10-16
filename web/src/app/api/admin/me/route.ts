import { NextResponse } from 'next/server';
import { errorResponse, MODERATION_ROLES, requireAdmin } from '@/lib/admin/session';

export async function GET() {
  try {
    const session = await requireAdmin(MODERATION_ROLES);
    return NextResponse.json({ success: true, data: session });
  } catch (error) {
    return errorResponse(error, 'Gagal memuat profil petugas');
  }
}
