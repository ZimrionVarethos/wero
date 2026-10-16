import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { createClient } from '@/lib/supabase/server';

export async function GET(_req: NextRequest) {
  try {
    try {
      const result = await pool.query(`
        SELECT id, name, code, level
        FROM public.regions
        WHERE is_active = true
        ORDER BY name ASC
      `);
      return NextResponse.json({ success: true, data: result.rows });
    } catch (pgError) {
      console.warn('Postgres pool error fetching regions, falling back to Supabase REST:', pgError);
      const supabase = await createClient();
      const { data, error } = await supabase
        .from('regions')
        .select('id, name, code, level')
        .eq('is_active', true)
        .order('name', { ascending: true });

      if (error) throw error;
      return NextResponse.json({ success: true, data: data || [] });
    }
  } catch (error: any) {
    console.error('Failed to fetch regions:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal mengambil daftar daerah' },
      { status: 500 }
    );
  }
}
