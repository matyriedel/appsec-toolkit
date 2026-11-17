---
tags: [checklist]
owasp: [A05, A01]
asvs: [V1, V3]
---
# 5. XSS, CSRF y frontend

## XSS
- [ ] Sin `dangerouslySetInnerHTML`, `v-html`, `innerHTML`, `{!! !!}` ni `|safe` con datos de usuario; si hace falta HTML, sanitizar con DOMPurify
- [ ] URLs de usuario en `href`/`src` validadas (bloquear `javascript:` y `data:`)
- [ ] JSON embebido en `<script>` escapado
- [ ] XSS almacenado en paneles admin (nombres, comentarios, notas de pedidos): **máxima prioridad**, porque ejecuta con privilegios
- [ ] Markdown renderizado con sanitización
- [ ] CSP definida (ver Cabeceras HTTP, CORS y TLS)

## CSRF
- [ ] Si la auth es por cookie: `SameSite=Lax|Strict` **y** token CSRF o verificación de `Origin` en métodos que cambian estado
- [ ] Ningún GET cambia estado
- [ ] Server Actions de Next.js: verificación de origen activa (por defecto sí; revisar `serverActions.allowedOrigins`)
- [ ] Si la auth es por header `Authorization: Bearer`, el riesgo de CSRF es bajo; dejarlo anotado como ✅ con esa justificación
- [ ] Formularios WordPress / WooCommerce verifican nonce

## Frontend en general
- [ ] Sin secretos en el bundle: en Next.js, todo `NEXT_PUBLIC_*` es público; en Vite, `VITE_*`
- [ ] Source maps de producción no publicados (o publicados a propósito)
- [ ] Validación en cliente acompañada **siempre** de validación en servidor
- [ ] Precios, totales y descuentos se recalculan en el servidor
- [ ] `target="_blank"` con `rel="noopener noreferrer"` en links externos de usuario
- [ ] Scripts de terceros con SRI o desde un origen confiable

## Grep
```bash
rg -n "dangerouslySetInnerHTML|v-html|innerHTML\s*=|outerHTML|document\.write|\|safe|\{!!" .
rg -n "href=\{.*(url|link)" .
rg -n "NEXT_PUBLIC_|VITE_|REACT_APP_" --glob '!node_modules' .
rg -n "productionBrowserSourceMaps" next.config.*
rg -n "wp_verify_nonce|check_admin_referer|check_ajax_referer" .
```

## Tests de regresión sugeridos
- Guardar `<img src=x onerror=alert(1)>` en un campo y renderizarlo → escapado
- POST desde un origen externo con cookie de sesión → 403
