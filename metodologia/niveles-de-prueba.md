---
tags: [metodologia]
---
# Niveles de prueba

| Nivel | Qué hace | Toca el objetivo | Autorización | Ejemplos |
|---|---|---|---|---|
| 🟢 **0 · Pasivo** | Consulta fuentes públicas de terceros | No | No hace falta, si es solo información pública | crt.sh, DNS públicos, Shodan/Censys, Wayback Machine, Google dorks, WHOIS |
| 🟡 **1 · Activo liviano** | Requests normales, como un navegador | Sí, tráfico mínimo | Sí (propio o escrita) | `curl -I`, chequeo de TLS, `robots.txt`, `security.txt`, rutas conocidas puntuales |
| 🟠 **2 · Activo no intrusivo** | Descubrimiento y enumeración | Sí, tráfico moderado | Sí, escrita y con ventana horaria | `nmap` de puertos, `testssl.sh`, fuzzing de rutas con lista corta, `nuclei` con plantillas de info o exposición |
| 🔴 **3 · Intrusivo** | Intenta explotar | Sí, con riesgo | Sí, escrita, explícita para este nivel, con contacto de emergencia | Inyecciones, fuerza bruta de login, explotación de CVE. **Preferir staging** |

## Reglas de subida de nivel
- Cada objetivo tiene un **nivel máximo autorizado**, definido por escrito antes de empezar.
- El nivel 3 nunca contra producción sin un backup reciente verificado y la persona responsable disponible.
- Si en el nivel 2 aparece algo crítico (panel admin abierto, base expuesta), **se frena y se avisa**. No se sigue explorando.

## Script incluido
[`scripts/chequeo-pasivo.ps1`](../scripts/chequeo-pasivo.ps1) trabaja en los niveles 0 y 1: DNS, TLS, cabeceras y unas 30 rutas puntuales con `GET`.
