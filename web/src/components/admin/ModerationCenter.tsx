'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  ShieldAlert,
  CheckCircle,
  AlertOctagon,
  RefreshCw,
  FileText,
  User,
  Clock,
  History,
} from 'lucide-react';

interface ReportRow {
  report_id: string;
  post_id: string;
  reporter_id: string;
  reason_code: string;
  details: string | null;
  report_status: string;
  report_created_at: string;
  reviewed_at: string | null;
  resolution: string | null;
  post_title: string | null;
  post_body: string | null;
  post_status: string | null;
  post_report_count: number | null;
  post_created_at: string | null;
  author_name: string | null;
}

interface AuditRow {
  id: string;
  post_id: string;
  action: string;
  reason: string;
  created_at: string;
  post_title: string | null;
}

export default function ModerationCenter() {
  const [reports, setReports] = useState<ReportRow[]>([]);
  const [auditList, setAuditList] = useState<AuditRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'QUEUE' | 'AUDIT'>('QUEUE');
  const [actionInProgress, setActionInProgress] = useState<string | null>(null);
  const [resolutionNotes, setResolutionNotes] = useState<{ [id: string]: string }>({});

  const fetchReports = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/moderation');
      const json = await res.json();
      if (json.success) {
        setReports(json.reports || []);
        setAuditList(json.auditHistory || []);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  const handleAction = async (report: ReportRow, action: 'REMOVE_TAKEDOWN' | 'APPROVE_RESTORE') => {
    const note = resolutionNotes[report.report_id] || (action === 'REMOVE_TAKEDOWN' ? 'Konten melanggar pedoman' : 'Laporan ditolak');
    setActionInProgress(report.report_id);
    try {
      const res = await fetch('/api/moderation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          reportId: report.report_id,
          postId: report.post_id,
          action,
          resolutionNote: note,
        }),
      });
      const json = await res.json();
      if (json.success) {
        fetchReports();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setActionInProgress(null);
    }
  };

  const getReasonBadge = (code: string) => {
    switch (code) {
      case 'MISLEADING_DANGEROUS':
        return (
          <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-100 text-rose-800 border border-rose-300">
            🚨 Hoaks & Berbahaya
          </span>
        );
      case 'SPAM':
        return (
          <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-100 text-amber-800 border border-amber-300">
            ⚠️ Spam / Iklan
          </span>
        );
      case 'HARASSMENT':
        return (
          <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-purple-100 text-purple-800 border border-purple-300">
            ⛔ Ujaran Kebencian
          </span>
        );
      default:
        return (
          <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-slate-100 text-slate-700 border border-slate-300">
            ℹ️ {code}
          </span>
        );
    }
  };

  const pendingReports = reports.filter((r) => r.report_status === 'PENDING');

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
        <div>
          <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2">
            <ShieldAlert className="w-5 h-5 text-indigo-600" /> Pusat Moderasi Komunitas & Anti-Hoaks
          </h2>
          <p className="text-xs text-slate-500 mt-1">
            Tinjau postingan warga yang dilaporkan, cegah kepanikan massal, dan jaga integritas informasi bencana.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setActiveTab('QUEUE')}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition ${
              activeTab === 'QUEUE' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            Antrean ({pendingReports.length})
          </button>
          <button
            onClick={() => setActiveTab('AUDIT')}
            className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition flex items-center gap-1 ${
              activeTab === 'AUDIT' ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <History className="w-3.5 h-3.5" /> Riwayat Keputusan
          </button>
          <button
            onClick={fetchReports}
            className="p-2 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50"
            title="Muat Ulang"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {activeTab === 'QUEUE' ? (
        <div className="space-y-4">
          {pendingReports.length === 0 ? (
            <div className="bg-white p-12 rounded-2xl border border-slate-200 text-center text-slate-400">
              <CheckCircle className="w-10 h-10 text-emerald-500 mx-auto mb-2 opacity-80" />
              <h4 className="font-bold text-slate-700">Semua Laporan Telah Selesai Ditinjau</h4>
              <p className="text-xs text-slate-400 mt-1">Tidak ada postingan yang menunggu moderasi saat ini.</p>
            </div>
          ) : (
            pendingReports.map((report) => (
              <div
                key={report.report_id}
                className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs space-y-4"
              >
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-3 border-b border-slate-100">
                  <div className="flex items-center gap-2">
                    {getReasonBadge(report.reason_code)}
                    <span className="text-xs text-slate-500 flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {new Date(report.report_created_at).toLocaleString('id-ID', {
                        dateStyle: 'medium',
                        timeStyle: 'short',
                      })}
                    </span>
                  </div>
                  <span className="text-xs font-semibold text-rose-600 bg-rose-50 px-2.5 py-0.5 rounded-full">
                    Total Laporan: {report.post_report_count || 1} Warga
                  </span>
                </div>

                {/* Post Content Preview */}
                <div className="bg-slate-50 p-4 rounded-xl border border-slate-100 space-y-1.5">
                  <div className="flex items-center gap-2 text-xs text-slate-500">
                    <User className="w-3.5 h-3.5" />
                    <span>Penulis:</span>
                    <span className="font-semibold text-slate-700">{report.author_name || 'Warga Anonim'}</span>
                    <span>• Status Postingan:</span>
                    <span className="font-bold uppercase text-slate-700">{report.post_status}</span>
                  </div>
                  <h4 className="font-bold text-slate-900 text-base">{report.post_title || '(Tanpa Judul)'}</h4>
                  <p className="text-sm text-slate-700 leading-relaxed">{report.post_body}</p>
                </div>

                {/* Reporter's Details */}
                {report.details && (
                  <div className="text-xs text-slate-600 bg-amber-50/70 p-3 rounded-lg border border-amber-200/60">
                    <span className="font-bold text-amber-800">Catatan Pelapor: </span>
                    {report.details}
                  </div>
                )}

                {/* Moderator Decision Action */}
                <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 pt-2">
                  <input
                    type="text"
                    placeholder="Catatan pertimbangan moderator (opsional)..."
                    value={resolutionNotes[report.report_id] || ''}
                    onChange={(e) =>
                      setResolutionNotes({ ...resolutionNotes, [report.report_id]: e.target.value })
                    }
                    className="flex-1 px-3 py-2 text-xs rounded-xl border border-slate-200 focus:outline-none focus:border-indigo-500"
                  />
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleAction(report, 'APPROVE_RESTORE')}
                      disabled={actionInProgress === report.report_id}
                      className="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-xs transition flex items-center gap-1.5"
                    >
                      <CheckCircle className="w-3.5 h-3.5 text-emerald-600" /> Pulihkan Postingan
                    </button>
                    <button
                      onClick={() => handleAction(report, 'REMOVE_TAKEDOWN')}
                      disabled={actionInProgress === report.report_id}
                      className="px-3.5 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-semibold text-xs transition flex items-center gap-1.5 shadow-xs"
                    >
                      <AlertOctagon className="w-3.5 h-3.5" /> Takedown Postingan
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      ) : (
        /* Audit History View */
        <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs">
          <div className="p-4 border-b border-slate-100 font-bold text-sm text-slate-800 flex items-center gap-2">
            <History className="w-4 h-4 text-slate-500" /> Riwayat Keputusan Moderasi Terakhir
          </div>
          <div className="divide-y divide-slate-100">
            {auditList.length === 0 ? (
              <div className="p-8 text-center text-slate-400 text-sm">Belum ada catatan riwayat moderasi.</div>
            ) : (
              auditList.map((audit) => (
                <div key={audit.id} className="p-4 flex items-center justify-between text-sm">
                  <div>
                    <div className="flex items-center gap-2">
                      <span
                        className={`px-2 py-0.5 rounded-full text-xs font-bold ${
                          audit.action === 'REMOVE_TAKEDOWN'
                            ? 'bg-rose-100 text-rose-800'
                            : 'bg-emerald-100 text-emerald-800'
                        }`}
                      >
                        {audit.action === 'REMOVE_TAKEDOWN' ? 'TAKEDOWN' : 'DIPULIHKAN'}
                      </span>
                      <span className="font-semibold text-slate-900">{audit.post_title || 'Postingan'}</span>
                    </div>
                    <p className="text-xs text-slate-500 mt-1 italic">"{audit.reason}"</p>
                  </div>
                  <span className="text-xs text-slate-400 whitespace-nowrap">
                    {new Date(audit.created_at).toLocaleString('id-ID', {
                      dateStyle: 'short',
                      timeStyle: 'short',
                    })}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}
