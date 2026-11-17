---
tags: [checklist]
owasp: [A01, API1, API3, API5]
asvs: [V8]
---
# 3. Autorización, roles y multi-tenant

## Principios
- Denegar por defecto: si no hay guard explícito, la ruta tiene que fallar cerrada.
- La identidad y el tenant salen **de la sesión**, nunca del body, de la query ni de un header que controle el cliente.
- Cada query sobre datos de un tenant filtra por `tenantId` / `ownerId`.

## Controles
- [ ] Guard o middleware global de autenticación (las excepciones públicas se listan explícitamente)
- [ ] Chequeo de rol en cada endpoint admin, **en el backend** (ocultar el botón en el front no cuenta)
- [ ] **BOLA/IDOR**: cada `findById`, `update` y `delete` verifica la pertenencia del objeto
- [ ] **Mass assignment**: DTO/whitelist de campos; el cliente no puede setear `role`, `tenantId`, `isAdmin`, `price`, `status`, `ownerId`
- [ ] **Exposición de propiedades**: las respuestas usan serializers o DTOs; no devuelven `passwordHash`, tokens ni datos internos
- [ ] IDs no secuenciales para recursos expuestos (UUID). Es defensa en profundidad, no reemplaza la autorización
- [ ] Aislamiento multi-tenant en: queries, jobs, caches (clave con tenant), archivos/buckets, búsquedas y exportaciones
- [ ] Row Level Security en Postgres si el modelo lo permite
- [ ] Server Actions / API routes de Next.js verifican sesión y permisos (no confían en el middleware solo)
- [ ] Errores de autorización no filtran existencia (usar 404 en lugar de 403 donde convenga)
- [ ] Ante una excepción en el chequeo de permisos, se deniega (fail-closed)

## Grep
```bash
# Queries por id sin filtro de dueño o tenant (revisar a mano cada match)
rg -n "findUnique\(\{\s*where:\s*\{\s*id|findById\(|findOne\(\{\s*where:\s*\{\s*id" .
rg -n "req\.(body|query|params)\.(tenantId|userId|ownerId|role)" .
rg -n "@Public\(\)|skipAuth|isPublic" .
rg -n "'use server'" app src
# Spread directo del body a un update/create
rg -n "data:\s*(req\.body|body|dto)\b|\.\.\.req\.body" .
```

## Prueba manual (local/staging)
1. Crear usuario A (tenant 1) y usuario B (tenant 2).
2. Con la sesión de B, repetir cada request de A cambiando IDs.
3. Con un usuario común, llamar cada endpoint admin.
4. Enviar campos extra (`"role":"admin"`, `"tenantId":"<otro>"`) en create y update.

## Tests de regresión sugeridos
- `GET /recurso/:idDeOtroTenant` → 404
- `PATCH /me` con `role: admin` → el rol no cambia
- Usuario común en `/admin/*` → 403
