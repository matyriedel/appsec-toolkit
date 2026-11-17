---
tags: [metodologia, reglas]
---
# Reglas y autorización

## Quién puede autorizar
| Activo | Quién autoriza | Cómo |
|---|---|---|
| Dominios y servidores propios | Vos | Documento de autorización y alcance firmado por vos |
| Sitios de clientes | **El cliente**, aunque vos lo hostees | Email o documento del cliente con alcance y fechas |
| Hosting o VPS de terceros (proveedor cloud, panel de hosting, CDN) | El proveedor, según sus términos | Leer la política de pentesting del proveedor antes de hacer pruebas activas |
| Red privada propia (LAN, VPN) | Vos, como administrador | Nota de alcance |
| Red pública (Wi-Fi ajeno) | **Nadie te autoriza a escanear a otros** | Solo se analiza tu propio equipo y lo que tu equipo expone |

> [!warning]
> Que un servidor sea tuyo no autoriza a probar los sitios de clientes que corren en él. Cada dominio necesita su autorización.

## Prohibido siempre
- ❌ Escanear o probar activos sin autorización escrita, aunque "solo sea un nmap".
- ❌ Escanear a otros usuarios de una red pública o compartida.
- ❌ Pruebas de denegación de servicio, carga o fuerza bruta contra producción.
- ❌ Explotar una vulnerabilidad más allá de lo necesario para demostrarla.
- ❌ Usar credenciales filtradas de terceros encontradas en OSINT. Se reportan, no se usan.
- ❌ Publicar o compartir hallazgos sin corregir fuera del canal acordado.

## Siempre
- Anotar fecha, hora, IP de origen y herramienta de cada prueba activa (para distinguirla de un ataque real en los logs).
- Empezar por el nivel pasivo y subir de nivel solo si el alcance lo permite (Niveles de prueba).
- Ventana horaria acordada para pruebas activas en producción.
- Separar lo **comprobado** de lo **pendiente** (Leyenda de estados).
- Datos sensibles encontrados (credenciales, PII): avisar al momento, citarlos redactados y no guardarlos.
