---
tags: [checklist]
owasp: [A05, A01, API7]
asvs: [V1, V5]
---
# 4. Inyección y SSRF

## SQL
- [ ] Todas las queries están parametrizadas o pasan por el ORM sin raw concatenado
- [ ] `$queryRawUnsafe`, `query()` con template strings, `sequelize.literal`, `knex.raw` y `TypeORM .query()` revisados uno por uno
- [ ] `ORDER BY` y nombres de columna dinámicos validados contra una whitelist
- [ ] El usuario de base de datos de la app no es superuser

## NoSQL
- [ ] El body no llega crudo a filtros Mongo (`{ $ne: null }`, `$where`, `$regex`)
- [ ] Hay validación de tipos (zod / class-validator / pydantic) antes del query

## Comandos, plantillas y archivos
- [ ] Sin `exec`, `child_process`, `os.system`, `subprocess(shell=True)`, `eval` ni `new Function` con input
- [ ] Sin render de plantillas con input del usuario como plantilla (SSTI)
- [ ] Uploads: tipo validado por contenido, tamaño máximo, nombre regenerado, guardados fuera del webroot y sin ejecución
- [ ] Path traversal: rutas construidas con input normalizadas y confinadas (`path.resolve` + chequeo de prefijo)
- [ ] Parsers XML con entidades externas deshabilitadas (XXE)

## SSRF
- [ ] Cada `fetch`/`axios`/`requests` con URL que viene del usuario (webhooks configurables, previews de links, importar desde URL, imágenes remotas) está identificado
- [ ] Hay allowlist de hosts, o bloqueo de IPs privadas, loopback, link-local `169.254.169.254` y de redirects
- [ ] Next.js `images.remotePatterns` está acotado (sin `hostname: '**'`)
- [ ] Desde el contenedor no se llega a la LAN interna (10.0.0.0/8, 192.168.0.0/16) sin necesidad

## Grep
```bash
rg -n "queryRawUnsafe|executeRawUnsafe|\.query\(`|sequelize\.literal|knex\.raw|f\"SELECT|\"SELECT .*\" *\+|%s.*execute" .
rg -n "\$where|\$regex|JSON\.parse\(req" .
rg -n "child_process|exec\(|execSync|spawn\(|os\.system|shell=True|eval\(|new Function" .
rg -n "fetch\((req|body|url|input)|axios\.(get|post)\((req|body|url)|requests\.(get|post)\(url" .
rg -n "remotePatterns|domains:" next.config.*
```

## Tests de regresión sugeridos
- Parámetro con `' OR 1=1--` → 400 o sin efecto
- Body `{ "email": { "$ne": null } }` → 400
- URL `http://169.254.169.254/` o `http://127.0.0.1:5432` en un campo de URL → rechazada
- Upload `shell.php` renombrado `.jpg` → rechazado
