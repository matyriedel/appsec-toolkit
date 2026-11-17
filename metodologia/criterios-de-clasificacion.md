---
tags: [metodologia, clasificacion]
---
# Criterios de clasificación

Cuatro ejes: **severidad** (qué pasa si se explota), **exposición** (desde dónde se alcanza), **esfuerzo** y **prioridad**.

## Severidad
| Nivel | Criterio | Ejemplos externos |
|---|---|---|
| 🔴 Crítica | Compromiso directo sin credenciales | Base de datos abierta a internet, panel admin sin login, credenciales por defecto funcionando, `.env` o `.git` descargables, RCE conocido en una versión expuesta |
| 🟠 Alta | Acceso a datos o control con poco esfuerzo | Subdominio tomable (takeover), SSH con contraseña y sin protección, servicio de gestión expuesto (Portainer, phpMyAdmin), backup descargable |
| 🟡 Media | Facilita ataques o expone información útil | Sin DMARC (suplantación de email), TLS viejo, servicio interno publicado en la LAN, listado de directorios, versión desactualizada sin exploit público |
| 🔵 Baja | Endurecimiento | Cabeceras faltantes, banner con versión, `security.txt` ausente |
| ⚪ Info | Observación | Tecnologías detectadas, inventario |

## Exposición (ajusta la severidad)
| Exposición | Ajuste |
|---|---|
| 🌐 Internet | Se mantiene, o **sube un nivel** si es automatizable por bots |
| 🔒 VPN o LAN | **Baja un nivel**, salvo que la red tenga invitados o equipos no confiables |
| 👤 Requiere cuenta | Baja un nivel si el registro está cerrado; se mantiene si el registro es abierto |

## Esfuerzo y prioridad
Los mismos criterios que en la bóveda de código: esfuerzo **S** (< 2 h), **M** (2 h a 2 días), **L** (> 2 días); prioridad de **P0** (inmediato) a **P3** (backlog).
Regla práctica: **expuesto a internet + Crítica/Alta + esfuerzo S = hoy.** Cerrar un puerto o borrar un archivo expuesto casi siempre es S.

## Propiedades en las notas
```yaml
severidad: critica | alta | media | baja | info
exposicion: internet | vpn-lan | requiere-cuenta
esfuerzo: S | M | L
prioridad: P0 | P1 | P2 | P3
```
