---
tags: [checklist]
owasp: [API9]
asvs: [V15]
---
# 1. Arquitectura e inventario

## Controles
- [ ] Stack identificado: framework, versión de runtime y base de datos
- [ ] Mapa de servicios (`docker-compose.yml`, proxies, workers, crons)
- [ ] Inventario de **todas** las rutas y endpoints, públicos e internos
- [ ] Endpoints de debug, health, metrics, Swagger o GraphQL playground: ¿están expuestos?
- [ ] Versiones viejas de la API todavía activas (`/v1`, `/old`, `/test`)
- [ ] Integraciones externas: pagos, email, storage, IA, mapas, mensajería
- [ ] Datos sensibles y dónde viven: PII, credenciales, tokens, datos de pago
- [ ] Modelo de tenancy: single-tenant, multi-tenant por columna, por schema o por base
- [ ] Puertos expuestos en el host y detrás del proxy
- [ ] Commit auditado y fecha registrados

## Comandos útiles
```powershell
# Rutas Next.js (app router y pages)
Get-ChildItem -Recurse -Include route.ts,route.js,page.tsx -Path app,src/app,pages | Select FullName
# Controllers NestJS
rg -n "@(Get|Post|Put|Patch|Delete)\(" src
# Rutas Express / FastAPI / Flask
rg -n "(app|router)\.(get|post|put|patch|delete)\(|@(app|router)\.(get|post|put|delete)" .
# Servicios y puertos
rg -n "ports:|expose:" docker-compose*.yml
```

## Salida esperada
Tabla en la nota del proyecto: `endpoint | método | auth requerida | rol | tenant-scoped | notas`.
