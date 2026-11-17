---
tags: [checklist]
owasp: [A04, A02, API3]
asvs: [V11, V14]
---
# 6. Exposición de datos y secretos

> [!danger] Si encontrás un secreto real
> Lo reportás **en el momento**, lo citás redactado (Reglas de compromiso) y recomendás rotarlo. Que se borre del repo no alcanza: ya quedó en el historial de git.

## Secretos
- [ ] `.env*` en `.gitignore` y **nunca** commiteados (revisar historial)
- [ ] Sin claves en `docker-compose.yml`, Dockerfiles, configs, seeds, tests ni README
- [ ] `.env.example` sin valores reales
- [ ] Secretos de producción distintos de los de desarrollo
- [ ] Ninguna API key privada en el frontend
- [ ] Credenciales por defecto cambiadas (admin/admin, postgres/postgres, root sin password)

## Datos
- [ ] Las respuestas de la API no incluyen `password`, `hash`, `token`, `secret` ni datos de otros usuarios
- [ ] Los errores no devuelven stack traces, queries ni rutas internas en producción
- [ ] PII mínima necesaria; datos sensibles cifrados en reposo si aplica
- [ ] Backups y dumps fuera del webroot y fuera del repo
- [ ] Sin `/.git`, `/.env`, `/backup.sql`, `/phpinfo.php` ni `/debug` accesibles por HTTP
- [ ] Exportaciones (CSV/Excel) respetan permisos y tenant

## Herramientas
```bash
gitleaks detect --source . --redact -v          # incluye historial
gitleaks detect --source . --no-git --redact     # solo working tree
trufflehog git file://. --only-verified
git log --all --diff-filter=A --name-only -- "*.env" "*.pem" "*.key" "*id_rsa*"
```

## Grep
```bash
rg -n -i "(api[_-]?key|secret|password|passwd|token|private[_-]?key)\s*[:=]\s*['\"][^'\"]{8,}" --glob '!*.lock' .
rg -n "BEGIN (RSA|OPENSSH|EC) PRIVATE KEY" .
rg -n "APP_USR-|TEST-[0-9]{10}|sk_live_|pk_live_|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[bp]-|ghp_" .
```
`APP_USR-` y `TEST-` son tokens de Mercado Pago; `sk_live_` es de Stripe.
