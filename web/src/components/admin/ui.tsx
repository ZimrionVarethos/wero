'use client';

import {
  CheckCircle2,
  CircleAlert,
  CircleDashed,
  Info,
  LoaderCircle,
  OctagonAlert,
  ShieldCheck,
  Siren,
  TriangleAlert,
  UserRoundCheck,
  X,
  type LucideIcon,
} from 'lucide-react';
import {
  useEffect,
  useId,
  useRef,
  useState,
  type ButtonHTMLAttributes,
  type InputHTMLAttributes,
  type ReactNode,
  type SelectHTMLAttributes,
  type TextareaHTMLAttributes,
} from 'react';
import { SOS_STATUS_LABEL } from '@/lib/admin/format';
import type { Severity, SosStatus } from '@/lib/admin/types';

/* ---------- Status ---------- */

// Semantic status colors from the design skill. WASPADA uses dark text for contrast on yellow.
export const SEVERITY_STYLE: Record<Severity, { className: string; Icon: LucideIcon }> = {
  AWAS: { className: 'bg-awas text-white', Icon: OctagonAlert },
  SIAGA: { className: 'bg-siaga text-white', Icon: TriangleAlert },
  WASPADA: { className: 'bg-waspada text-[#1A1D21]', Icon: CircleAlert },
  AMAN: { className: 'bg-aman text-white', Icon: ShieldCheck },
  INFO: { className: 'bg-info text-white', Icon: Info },
};

export function SeverityBadge({ level }: { level: Severity }) {
  const s = SEVERITY_STYLE[level] ?? SEVERITY_STYLE.INFO;
  return (
    <span className={`inline-flex items-center gap-1 rounded-md px-2 py-0.5 text-xs font-bold tracking-wide ${s.className}`}>
      <s.Icon className="size-3.5" aria-hidden />
      {level}
    </span>
  );
}

const SOS_STYLE: Record<SosStatus, { className: string; Icon: LucideIcon }> = {
  ACTIVE: { className: 'bg-awas/10 text-awas ring-awas/30', Icon: Siren },
  CLAIMED: { className: 'bg-info/10 text-info ring-info/30', Icon: UserRoundCheck },
  RESOLVED: { className: 'bg-aman/10 text-aman ring-aman/30', Icon: CheckCircle2 },
  CANCELLED: { className: 'bg-[#5F6B76]/10 text-muted ring-[#5F6B76]/25', Icon: CircleDashed },
  EXPIRED: { className: 'bg-[#5F6B76]/10 text-muted ring-[#5F6B76]/25', Icon: CircleDashed },
};

export function SosStatusPill({ status }: { status: SosStatus }) {
  const s = SOS_STYLE[status];
  return (
    <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold ring-1 ring-inset ${s.className}`}>
      <s.Icon className="size-3.5" aria-hidden />
      {SOS_STATUS_LABEL[status]}
    </span>
  );
}

/* ---------- Layout ---------- */

export function PageHeader({ title, description, actions }: { title: string; description?: ReactNode; actions?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div className="min-w-0">
        <h1 className="text-2xl font-extrabold tracking-tight text-navy">{title}</h1>
        {description ? <p className="mt-1 max-w-3xl text-sm text-muted">{description}</p> : null}
      </div>
      {actions ? <div className="flex flex-wrap items-center gap-2">{actions}</div> : null}
    </div>
  );
}

export function Card({ children, className = '', as: Tag = 'section' }: { children: ReactNode; className?: string; as?: 'section' | 'div' | 'aside' }) {
  return <Tag className={`rounded-xl border border-border-neutral bg-white ${className}`}>{children}</Tag>;
}

export function CardHeader({ title, actions, description }: { title: string; actions?: ReactNode; description?: string }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border-neutral px-5 py-4">
      <div>
        <h2 className="text-base font-bold text-navy">{title}</h2>
        {description ? <p className="mt-0.5 text-xs text-muted">{description}</p> : null}
      </div>
      {actions}
    </div>
  );
}

/* ---------- Controls ---------- */

type Variant = 'primary' | 'accent' | 'secondary' | 'danger' | 'ghost';

const VARIANT: Record<Variant, string> = {
  primary: 'bg-navy text-white hover:bg-[#1c3556]',
  // Orange is the action accent. Use it for at most one primary action per screen.
  accent: 'bg-accent text-white hover:bg-[#cf4f0a]',
  secondary: 'bg-white text-navy border border-border-neutral hover:border-navy',
  danger: 'bg-white text-awas border border-awas/50 hover:bg-awas/5',
  ghost: 'text-navy hover:bg-navy/5',
};

export function Button({
  variant = 'primary',
  size = 'md',
  loading = false,
  icon: Icon,
  className = '',
  children,
  disabled,
  ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; size?: 'sm' | 'md'; loading?: boolean; icon?: LucideIcon }) {
  return (
    <button
      {...rest}
      disabled={disabled || loading}
      className={`inline-flex items-center justify-center gap-2 rounded-lg font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-navy disabled:cursor-not-allowed disabled:opacity-55 ${
        size === 'sm' ? 'min-h-10 px-3 text-sm' : 'min-h-12 px-4 text-sm'
      } ${VARIANT[variant]} ${className}`}
    >
      {loading ? <LoaderCircle className="size-4 animate-spin" aria-hidden /> : Icon ? <Icon className="size-4" aria-hidden /> : null}
      {children}
    </button>
  );
}

const fieldClass =
  'w-full rounded-lg border border-border-neutral bg-white px-3 text-sm text-[#1A1D21] outline-none transition-colors placeholder:text-muted/70 focus:border-navy focus:ring-2 focus:ring-navy/15 disabled:bg-cream';

function FieldShell({ id, label, hint, error, children }: { id: string; label: string; hint?: string; error?: string | null; children: ReactNode }) {
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-sm font-semibold text-navy">
        {label}
      </label>
      {children}
      {error ? (
        <p role="alert" className="mt-1.5 flex items-center gap-1 text-xs font-medium text-awas">
          <CircleAlert className="size-3.5" aria-hidden /> {error}
        </p>
      ) : hint ? (
        <p className="mt-1.5 text-xs text-muted">{hint}</p>
      ) : null}
    </div>
  );
}

export function TextField({ label, hint, error, className = '', ...rest }: InputHTMLAttributes<HTMLInputElement> & { label: string; hint?: string; error?: string | null }) {
  const id = useId();
  return (
    <FieldShell id={id} label={label} hint={hint} error={error}>
      <input id={id} {...rest} aria-invalid={error ? true : undefined} className={`${fieldClass} min-h-12 ${className}`} />
    </FieldShell>
  );
}

export function TextArea({ label, hint, error, ...rest }: TextareaHTMLAttributes<HTMLTextAreaElement> & { label: string; hint?: string; error?: string | null }) {
  const id = useId();
  return (
    <FieldShell id={id} label={label} hint={hint} error={error}>
      <textarea id={id} {...rest} aria-invalid={error ? true : undefined} className={`${fieldClass} py-3`} />
    </FieldShell>
  );
}

export function SelectField({ label, hint, error, children, ...rest }: SelectHTMLAttributes<HTMLSelectElement> & { label: string; hint?: string; error?: string | null }) {
  const id = useId();
  return (
    <FieldShell id={id} label={label} hint={hint} error={error}>
      <select id={id} {...rest} className={`${fieldClass} min-h-12`}>
        {children}
      </select>
    </FieldShell>
  );
}

/** Compact segmented filter, rendered as a radio group for screen readers. */
export function Segmented<T extends string>({ label, value, options, onChange }: { label: string; value: T; options: { value: T; label: string; count?: number }[]; onChange: (v: T) => void }) {
  return (
    <div role="radiogroup" aria-label={label} className="inline-flex flex-wrap gap-1 rounded-lg border border-border-neutral bg-white p-1">
      {options.map((o) => {
        const selected = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            role="radio"
            aria-checked={selected}
            onClick={() => onChange(o.value)}
            className={`inline-flex min-h-10 items-center gap-1.5 rounded-md px-3 text-sm font-semibold transition-colors ${
              selected ? 'bg-navy text-white' : 'text-muted hover:bg-cream hover:text-navy'
            }`}
          >
            {o.label}
            {o.count !== undefined ? (
              <span className={`rounded px-1.5 text-xs tabular-nums ${selected ? 'bg-white/15' : 'bg-cream'}`}>{o.count}</span>
            ) : null}
          </button>
        );
      })}
    </div>
  );
}

/* ---------- Feedback ---------- */

const ALERT_STYLE = {
  error: { className: 'border-awas/30 bg-awas/5 text-awas', Icon: CircleAlert, role: 'alert' },
  success: { className: 'border-aman/30 bg-aman/5 text-aman', Icon: CheckCircle2, role: 'status' },
  info: { className: 'border-info/25 bg-info/5 text-info', Icon: Info, role: 'status' },
} as const;

export function Alert({ tone, children, onDismiss }: { tone: keyof typeof ALERT_STYLE; children: ReactNode; onDismiss?: () => void }) {
  const s = ALERT_STYLE[tone];
  return (
    <div role={s.role} className={`flex items-start gap-2 rounded-lg border px-3 py-2.5 text-sm font-medium ${s.className}`}>
      <s.Icon className="mt-0.5 size-4 shrink-0" aria-hidden />
      <div className="min-w-0 flex-1">{children}</div>
      {onDismiss ? (
        <button type="button" onClick={onDismiss} aria-label="Tutup pesan" className="-m-1 grid size-8 place-items-center rounded hover:bg-black/5">
          <X className="size-4" aria-hidden />
        </button>
      ) : null}
    </div>
  );
}

export function EmptyState({ icon: Icon, title, children }: { icon: LucideIcon; title: string; children?: ReactNode }) {
  return (
    <div className="flex flex-col items-center px-6 py-12 text-center">
      <span className="grid size-12 place-items-center rounded-full bg-cream text-muted">
        <Icon className="size-6" aria-hidden />
      </span>
      <p className="mt-3 font-semibold text-navy">{title}</p>
      {children ? <div className="mt-1 max-w-sm text-sm text-muted">{children}</div> : null}
    </div>
  );
}

export function SkeletonRows({ rows = 4 }: { rows?: number }) {
  return (
    <div className="space-y-3 p-5" role="status" aria-label="Memuat data">
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="h-14 animate-pulse rounded-lg bg-cream" />
      ))}
    </div>
  );
}

/* ---------- Confirmation ---------- */

/**
 * Modal confirmation for sensitive actions. When `requireReason` is set the confirm button
 * stays disabled until a reason is typed, and the reason is passed to onConfirm.
 */
export function ConfirmDialog({
  open,
  title,
  children,
  confirmLabel,
  tone = 'primary',
  requireReason,
  reasonLabel = 'Alasan',
  busy,
  onConfirm,
  onClose,
}: {
  open: boolean;
  title: string;
  children?: ReactNode;
  confirmLabel: string;
  tone?: 'primary' | 'accent' | 'danger';
  requireReason?: boolean;
  reasonLabel?: string;
  busy?: boolean;
  onConfirm: (reason: string) => void;
  onClose: () => void;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  const [reason, setReason] = useState('');

  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) {
      setReason('');
      d.showModal();
    } else if (!open && d.open) {
      d.close();
    }
  }, [open]);

  const valid = !requireReason || reason.trim().length >= 3;

  return (
    <dialog
      ref={ref}
      onClose={onClose}
      className="m-auto w-[min(92vw,30rem)] rounded-xl border border-border-neutral bg-white p-0 text-[#1A1D21] shadow-xl backdrop:bg-[#0b1a2c]/55"
    >
      <form
        method="dialog"
        onSubmit={(e) => {
          e.preventDefault();
          if (valid) onConfirm(reason.trim());
        }}
      >
        <div className="px-6 pt-6">
          <h2 className="text-lg font-bold text-navy">{title}</h2>
          {children ? <div className="mt-2 text-sm leading-relaxed text-muted">{children}</div> : null}
          {requireReason ? (
            <div className="mt-4">
              <TextArea label={reasonLabel} rows={3} maxLength={500} value={reason} onChange={(e) => setReason(e.target.value)} hint="Tercatat di log audit atas nama Anda" />
            </div>
          ) : null}
        </div>
        <div className="mt-6 flex justify-end gap-2 border-t border-border-neutral bg-cream/60 px-6 py-4">
          <Button type="button" variant="secondary" onClick={onClose} disabled={busy}>
            Batal
          </Button>
          <Button type="submit" variant={tone} disabled={!valid} loading={busy}>
            {confirmLabel}
          </Button>
        </div>
      </form>
    </dialog>
  );
}
