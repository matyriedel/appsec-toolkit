# AppSec Toolkit

**Chequeo pasivo de seguridad de dominios + checklists de auditoría de aplicaciones web basados en OWASP y ASVS.**

![PowerShell](https://img.shields.io/badge/PowerShell_5.1+-5391FE?logo=powershell&logoColor=white)
![OWASP](https://img.shields.io/badge/OWASP_Top_10_2025-000000?logo=owasp&logoColor=white)
![ASVS](https://img.shields.io/badge/ASVS_5.0-1f2937)
![License](https://img.shields.io/badge/license-MIT-16a34a)

> 🇬🇧 **English summary.** The toolkit I use to audit my own products. `chequeo-pasivo.ps1` runs a passive /
> light-active check of a domain (DNS, SPF/DMARC/CAA, Certificate Transparency, Shodan InternetDB, HTTPS redirect,
> TLS version and certificate expiry, security headers, CORS reflection, ~30 sensitive paths with false-200
> detection) and writes a prioritized Markdown report. The `checklists/` cover 12 areas of a code-level AppSec
> review mapped to OWASP Top 10 2025, API Security Top 10 and ASVS 5.0, each with controls, ripgrep patterns,
> manual tests and suggested regression tests. Content is in Spanish.

---

## ⚠️ Uso responsable

Usalo **solo con dominios propios o con autorización escrita** del dueño. El script no escanea puertos,
no hace fuerza bruta y no envía formularios, pero igual hace requests al objetivo (nivel 1).
Ver [metodologia/reglas-y-autorizacion.md](metodologia/reglas-y-autorizacion.md) y
[metodologia/niveles-de-prueba.md](metodologia/niveles-de-prueba.md).

## Chequeo pasivo de un dominio

```powershell
.\scripts\chequeo-pasivo.ps1 -Dominio example.com
.\scripts\chequeo-pasivo.ps1 -Dominio example.com -SinOsint -Salida .\informes
```

Requiere Windows PowerShell 5.1 o PowerShell 7 y `curl.exe` (incluido en Windows 10+).

| Área | Qué revisa |
|---|---|
| DNS | A/AAAA/MX/NS, IPs privadas publicadas, **SPF** (ausente, duplicado, `+all`), **DMARC** (`p=none`), **CAA**, wildcard |
| OSINT (nivel 0) | Subdominios por Certificate Transparency (crt.sh), puertos y CVEs indexados (Shodan InternetDB) |
| HTTP / TLS | Redirección a HTTPS, protocolo negociado, validez y vencimiento del certificado, rechazo de TLS ≤ 1.1 |
| Cabeceras | HSTS, CSP, nosniff, X-Frame-Options, Referrer-Policy, Permissions-Policy, banners con versión, flags de cookies |
| CORS | Reflejo de un origen externo con y sin credenciales |
| Rutas sensibles | `.env`, `.git`, dumps SQL, backups, `phpinfo`, paneles, Swagger, GraphQL, WordPress… con detección de **"200 falso"** |
| Informe | Markdown con resumen ordenado por severidad sugerida y detalle por sección |

Todo lo marcado ❌ / ⚠️ es una **señal** para confirmar a mano, no un hallazgo confirmado.

## Checklists de auditoría de código

Cada checklist trae principios, controles, búsquedas con `rg`, prueba manual y tests de regresión sugeridos.

| # | Área | Referencias |
|---|---|---|
| 1 | [Arquitectura e inventario](checklists/arquitectura-e-inventario.md) | API9 · ASVS V15 |
| 2 | [Autenticación y sesiones](checklists/autenticacion-y-sesiones.md) | A07 · A04 · API2 · ASVS V6/V7/V9/V10 |
| 3 | [Autorización, roles y multi-tenant](checklists/autorizacion-roles-y-multi-tenant.md) | A01 · API1/API3/API5 · ASVS V8 |
| 4 | [Inyección y SSRF](checklists/inyeccion-y-ssrf.md) | A05 · A01 · API7 · ASVS V1/V5 |
| 5 | [XSS, CSRF y frontend](checklists/xss-csrf-y-frontend.md) | A05 · A01 · ASVS V1/V3 |
| 6 | [Cabeceras HTTP, CORS y TLS](checklists/cabeceras-http-cors-y-tls.md) | A02 · API8 · ASVS V3/V12 |
| 7 | [Exposición de datos y secretos](checklists/exposicion-de-datos-y-secretos.md) | A04 · A02 · API3 · ASVS V11/V14 |
| 8 | [Base de datos](checklists/base-de-datos.md) | A01 · A04 · A05 · ASVS V14 |
| 9 | [Webhooks, suscripciones y pagos](checklists/webhooks-suscripciones-y-pagos.md) | A06 · A08 · API6/API10 · ASVS V2 |
| 10 | [Dependencias y supply chain](checklists/dependencias-y-supply-chain.md) | A03 · ASVS V15 |
| 11 | [Docker, servidor y variables de entorno](checklists/docker-servidor-y-variables-de-entorno.md) | A02 · ASVS V13 |
| 12 | [Logs, monitoreo y CI/CD](checklists/logs-monitoreo-y-ci-cd.md) | A09 · A10 · A03 · API4 · ASVS V16 |

## Metodología

- [Niveles de prueba](metodologia/niveles-de-prueba.md): de 0 (pasivo) a 3 (intrusivo), con la autorización que exige cada uno.
- [Criterios de clasificación](metodologia/criterios-de-clasificacion.md): severidad × exposición, esfuerzo y prioridad.
- [Reglas y autorización](metodologia/reglas-y-autorizacion.md): quién puede autorizar qué y lo que está prohibido siempre.

## Cómo lo uso

Cada producto que desarrollo pasa por una auditoría con estos checklists: informe con hallazgos numerados,
plan de corrección aprobado antes de tocar código, cambios en una rama separada y verificación pasiva en
producción. Así se auditaron y corrigieron, entre otros, [PidoSimple](https://github.com/matyriedel/pidosimple),
[¿En qué se me fue?](https://github.com/matyriedel/enquesemefue), [ColdSense](https://github.com/matyriedel/coldsense)
y el [CRM Gastronómico](https://github.com/matyriedel/crm-gastronomico).

## Licencia

[MIT](LICENSE)
