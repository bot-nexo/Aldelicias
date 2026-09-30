export default function AdminHomePage() {
  return (
    <section>
      <p className="text-xs font-semibold text-[var(--color-accent)] uppercase">
        AlDelicias
      </p>
      <h1 className="mt-2 text-2xl font-semibold">Área administrativa</h1>
      <p className="mt-2 max-w-xl text-sm leading-6 text-[var(--color-ink-muted)]">
        La infraestructura de acceso está preparada. Los módulos operativos se
        incorporarán en sus fases correspondientes.
      </p>
      <div className="mt-8 border-t border-[var(--color-border)] pt-5">
        <p className="text-sm font-medium">Sin actividad por mostrar</p>
      </div>
    </section>
  );
}
