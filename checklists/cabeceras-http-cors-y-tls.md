---
tags: [checklist, infra]
owasp: [A02, API8]
asvs: [V3, V12]
---
# 10. Cabeceras HTTP, CORS y TLS

## Cabeceras
| Cabecera | Valor recomendado |
|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` (sumar `preload` solo si se decide) |
| `Content-Security-Policy` | Empezar con `default-src 'self'; frame-ancestors 'none'; object-src 'none'; base-uri 'self'`, en modo Report-Only primero |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` según el uso |
| `X-Frame-Options` | `DENY` (legado; CSP `frame-ancestors` lo reemplaza) |
| `X-Powered-By` / `Server` | Eliminados o genéricos |

- [ ] Cabeceras presentes en HTML **y** en las respuestas de la API
- [ ] Definidas en un solo lugar (proxy **o** app) y sin duplicados contradictorios

## CORS
- [ ] Sin `Access-Control-Allow-Origin: *` junto con `Allow-Credentials: true` (además, el navegador lo bloquea)
- [ ] No refleja el `Origin` recibido sin validarlo contra una lista
- [ ] Sin regex flojas (`.*example.com` también acepta `evilexample.com`)
- [ ] `null` no figura como origen permitido

## TLS
- [ ] Solo TLS 1.2 y 1.3, con cifrados modernos
- [ ] Redirect 80 → 443
- [ ] Certificado válido, con renovación automática y alerta de vencimiento
- [ ] Sin contenido mixto
- [ ] Servicios internos que viajan por red no confiable usan TLS o un túnel (WireGuard)

## Verificación
```bash
curl -sI https://dominio | sort
curl -sI -H "Origin: https://evil.example" https://dominio/api/x | rg -i "access-control"
testssl.sh --fast https://dominio      # o https://www.ssllabs.com/ssltest/
```
Externos: https://securityheaders.com, https://observatory.mozilla.org

## Grep
```bash
rg -n "enableCors|cors\(|origin:\s*(true|\*|'\*')|credentials:\s*true" .
rg -n "headers\(\)|helmet" next.config.* src
rg -n "add_header|ssl_protocols" /etc/nginx   # en el host, lectura
```
