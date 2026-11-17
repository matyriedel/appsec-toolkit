---
tags: [checklist]
owasp: [A01, A04, A05]
asvs: [V14]
---
# 12. Base de datos

## Controles
- [ ] Puerto no expuesto a internet (ni a la LAN si no hace falta)
- [ ] Usuario de la app con privilegios mínimos: sin `SUPERUSER`, sin `CREATEDB`, sin dueño del schema en runtime si se puede separar
- [ ] Usuario de migraciones distinto del de runtime (ideal)
- [ ] Contraseña fuerte, que no sea la del ejemplo de compose
- [ ] Conexión con TLS si cruza hosts
- [ ] Constraints de integridad: `UNIQUE` en `event_id` de webhooks, en emails y en slugs por tenant; `FOREIGN KEY`; `CHECK` en montos ≥ 0
- [ ] `tenant_id NOT NULL` e indexado en tablas multi-tenant; RLS evaluado
- [ ] Migraciones revisadas: ninguna destructiva sin backup previo
- [ ] Backups automáticos con restore probado
- [ ] Datos sensibles (tokens de terceros, documentos) cifrados a nivel aplicación si aplica

## Consultas de solo lectura útiles (Postgres)
```sql
-- Roles y privilegios
SELECT rolname, rolsuper, rolcreatedb, rolcreaterole FROM pg_roles;
-- Tablas con RLS
SELECT relname, relrowsecurity FROM pg_class WHERE relkind = 'r' AND relnamespace = 'public'::regnamespace;
-- Conexiones sin SSL
SELECT usename, client_addr, ssl FROM pg_stat_ssl JOIN pg_stat_activity USING (pid);
```

> [!warning]
> En producción solo `SELECT` sobre catálogos. Nada de `ALTER`, `DROP`, `UPDATE` ni `prisma migrate` (Reglas de compromiso).
