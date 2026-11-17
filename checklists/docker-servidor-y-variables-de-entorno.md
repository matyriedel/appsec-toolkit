---
tags: [checklist, infra]
owasp: [A02]
asvs: [V13]
---
# 9. Docker, servidor y variables de entorno

## Dockerfile
- [ ] Imagen base mínima (`-alpine`, `-slim`, distroless) y con versión fijada
- [ ] Multi-stage: la imagen final no lleva toolchain, código fuente innecesario ni devDependencies
- [ ] `USER` sin privilegios (no root)
- [ ] Sin secretos en `ARG`/`ENV`/`COPY` (quedan en las capas): usar `--secret` de BuildKit
- [ ] `.dockerignore` excluye `.env`, `.git`, `node_modules`, backups
- [ ] `HEALTHCHECK` definido

## docker-compose
- [ ] Base de datos, Redis y servicios internos **sin** `ports:` publicados al host (solo red interna), o bind a `127.0.0.1`
- [ ] Sin `privileged: true`, `network_mode: host` ni montar `/var/run/docker.sock` salvo que esté justificado
- [ ] `read_only: true` y `cap_drop: [ALL]` donde se pueda
- [ ] Secretos vía `env_file` fuera del repo o Docker secrets, no inline
- [ ] `restart: unless-stopped` y límites de recursos (`mem_limit`, `cpus`)
- [ ] Persistencia por bind mount en el proyecto (`./data`), con permisos correctos y fuera del webroot

## Variables de entorno
- [ ] `NODE_ENV=production` / `DEBUG=False` / `APP_DEBUG=false` en producción
- [ ] Validación del env al arrancar (zod, `@nestjs/config` con schema, pydantic-settings): la app no arranca con secretos vacíos
- [ ] No hay fallback a un secreto por defecto (`process.env.JWT_SECRET || 'secret'`)

## Servidor / host
- [ ] SSH solo con clave, sin login de root y con fail2ban o similar
- [ ] Firewall: solo 80/443 públicos en el proxy; los puertos de apps solo desde el proxy
- [ ] Reverse proxy (Nginx / CloudPanel / Traefik) con TLS y cabeceras
- [ ] Updates de seguridad del SO aplicados
- [ ] Backups automáticos, cifrados, fuera del host y **probados** (restore)

## Grep
```bash
rg -n "^USER|^FROM|ARG .*(KEY|SECRET|PASS)|ENV .*(KEY|SECRET|PASS)" -g "Dockerfile*" .
rg -n "privileged|network_mode: host|docker.sock|ports:" docker-compose*.yml
rg -n "\|\| ['\"](secret|changeme|password|dev)" .
```
Con permiso de lectura en el host: `trivy image <imagen>`, `docker inspect`, `ss -tlnp`. **Solo lectura.**
