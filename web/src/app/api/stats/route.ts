import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function GET(_req: NextRequest) {
  try {
    const [sheltersRes, sosRes, reportsRes, disastersRes] = await Promise.all([
      pool.query(`
        SELECT 
          COUNT(*)::int as total_shelters,
          COUNT(*) FILTER (WHERE is_active = true)::int as active_shelters,
          COALESCE(SUM(capacity), 0)::int as total_capacity
        FROM public.evacuation_points
      `),
      pool.query(`
        SELECT 
          COUNT(*)::int as active_sos
        FROM public.sos_events
        WHERE status NOT IN ('RESOLVED', 'CANCELLED')
      `),
      pool.query(`
        SELECT 
          COUNT(*)::int as pending_reports
        FROM public.community_reports
        WHERE status = 'PENDING'
      `),
      pool.query(`
        SELECT 
          COUNT(*)::int as active_disasters
        FROM public.disaster_events
        WHERE is_published = true AND created_at > NOW() - INTERVAL '7 days'
      `),
    ]);

    return NextResponse.json({
      success: true,
      stats: {
        shelters: sheltersRes.rows[0],
        activeSos: sosRes.rows[0]?.active_sos ?? 0,
        pendingReports: reportsRes.rows[0]?.pending_reports ?? 0,
        activeDisasters: disastersRes.rows[0]?.active_disasters ?? 0,
      },
    });
  } catch (error: any) {
    console.error('Failed to aggregate dashboard stats:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal menghitung statistik' },
      { status: 500 }
    );
  }
}
