---
tags: [checklist]
owasp: [A03]
asvs: [V15]
---
# 8. Dependencias y supply chain

## Controles
- [ ] Hay lockfile commiteado (`package-lock.json`, `pnpm-lock.yaml`, `poetry.lock`, `composer.lock`)
- [ ] Sin CVEs críticos ni altos **alcanzables** (anotar si el código vulnerable se usa o no)
- [ ] Runtime soportado (Node LTS, Python, PHP con soporte de seguridad)
- [ ] Framework en versión con parches (Next.js, NestJS, WordPress core)
- [ ] Sin paquetes abandonados o typosquatting en dependencias directas
- [ ] Scripts `postinstall` de terceros revisados
- [ ] Imágenes Docker base fijadas por tag específico (idealmente digest)
- [ ] Dependabot o Renovate configurado
- [ ] WordPress: plugins y temas actualizados, sin plugins nulled, inactivos borrados

## Comandos
```bash
npm audit --omit=dev            # o: pnpm audit --prod / yarn npm audit
npx better-npm-audit audit
pip-audit -r requirements.txt
composer audit
trivy fs --scanners vuln,secret,misconfig .
osv-scanner -r .
wp plugin list --update=available   # WordPress con WP-CLI, solo lectura
```

## Cómo reportar
Una nota de hallazgo por paquete crítico o alto alcanzable. El resto va agrupado en un único hallazgo "Dependencias desactualizadas" con la tabla `paquete | versión | CVE | fix | alcanzable`.
