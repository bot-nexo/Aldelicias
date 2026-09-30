export default function AdminLoading() {
  return (
    <div
      aria-label="Cargando área administrativa"
      aria-live="polite"
      role="status"
    >
      <span className="sr-only">Cargando…</span>
      <div className="h-3 w-20 animate-pulse rounded bg-[var(--color-border)]" />
      <div className="mt-4 h-8 w-64 max-w-full animate-pulse rounded bg-[var(--color-border)]" />
      <div className="mt-3 h-4 w-full max-w-xl animate-pulse rounded bg-[var(--color-border)]" />
    </div>
  );
}
