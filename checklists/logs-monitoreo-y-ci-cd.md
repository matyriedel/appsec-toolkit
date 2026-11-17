---
tags: [checklist]
owasp: [A09, A10, A03, API4]
asvs: [V16]
---
# 11. Logs, monitoreo y CI-CD

## Logs
- [ ] Se registran logins (ok y fallidos), cambios de contraseña o rol, acciones admin, pagos y errores de autorización
- [ ] Cada evento lleva timestamp, usuario, tenant, IP y request-id
- [ ] **No** se loguean contraseñas, tokens, cookies, números de tarjeta ni el body completo de un webhook con datos sensibles
- [ ] Logs protegidos contra inyección (saltos de línea escapados; logging estructurado JSON)
- [ ] Retención definida y rotación (`logrotate` o `max-size` del driver de Docker)
- [ ] Alertas ante picos de 401/403/500, logins fallidos o webhooks inválidos

## Manejo de errores (A10:2025)
- [ ] Handler global de excepciones con mensaje genérico al cliente
- [ ] Las excepciones en chequeos de seguridad deniegan (fail-closed)
- [ ] Los timeouts de servicios externos están definidos y no dejan órdenes o estados a medias

## Consumo de recursos (API4)
- [ ] Rate limit global y por endpoint sensible
- [ ] Límite de tamaño del body y de los uploads
- [ ] Paginación con máximo (`take ≤ 100`)
- [ ] Timeouts en queries y requests salientes

## CI/CD
- [ ] Secretos en el gestor del CI (GitHub Secrets, etc.) y no en el YAML
- [ ] Workflows sin `pull_request_target` con checkout del código del PR
- [ ] Actions de terceros fijadas por SHA
- [ ] `permissions:` mínimos en el workflow
- [ ] El pipeline corre tests + `audit` + escaneo de secretos antes del deploy
- [ ] El deploy a producción exige aprobación o rama protegida
- [ ] Si el deploy es manual (sudo + compose), está documentado quién lo hace y cómo se vuelve atrás

## Grep
```bash
rg -n "console\.log\(.*(password|token|secret|req\.body|headers)" -i .
rg -n "logger\.(info|debug)\(.*(password|token|authorization)" -i .
rg -n "pull_request_target|uses: .*@(main|master|v[0-9]+)$|permissions:" .github
rg -n "ThrottlerModule|rateLimit|express-rate-limit|slowapi" .
```
