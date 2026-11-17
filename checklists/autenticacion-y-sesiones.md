---
tags: [checklist]
owasp: [A07, A04, API2]
asvs: [V6, V7, V9, V10]
---
# 2. Autenticación y sesiones

## Contraseñas
- [ ] Hash con `argon2id` o `bcrypt` (cost ≥ 10). Nunca MD5/SHA1/SHA256 sin sal
- [ ] Longitud mínima 8 (ASVS sugiere 12 para L2), sin máximo absurdo, chequeo contra contraseñas filtradas
- [ ] Mensajes de login genéricos (no revelan si el usuario existe)
- [ ] Rate limit y/o bloqueo progresivo en login, registro, reset y OTP
- [ ] Reset de contraseña: token aleatorio ≥ 128 bits, de un solo uso, con expiración ≤ 1 h y guardado hasheado
- [ ] Cambio de email o contraseña exige la contraseña actual o reautenticación

## Sesiones / cookies
- [ ] Cookie de sesión `HttpOnly`, `Secure`, `SameSite=Lax|Strict`, con `Path` acotado
- [ ] ID de sesión regenerado al loguearse (evita fixation)
- [ ] Logout invalida la sesión **en el servidor**
- [ ] Expiración por inactividad y absoluta
- [ ] Cambio de contraseña revoca las demás sesiones

## JWT
- [ ] Algoritmo fijo en la verificación (`algorithms: ['HS256']` o `RS256`); rechaza `none`
- [ ] Secreto ≥ 256 bits que no sea un default (`secret`, `changeme`, `jwt_secret`)
- [ ] Valida `exp`, y `iss`/`aud` si aplican
- [ ] Access token corto (≤ 15–60 min) + refresh token rotativo y revocable
- [ ] No guarda datos sensibles en el payload; no se usa `decode()` como si fuera `verify()`
- [ ] El token no queda en `localStorage` si hay riesgo de XSS (preferir cookie HttpOnly)

## OAuth / social login
- [ ] Parámetro `state` validado; PKCE en clientes públicos
- [ ] `redirect_uri` en lista blanca exacta
- [ ] Vinculación de cuentas por email solo si el proveedor marca el email como verificado

## Grep
```bash
rg -n "jwt\.decode|ignoreExpiration|algorithms|verify\(" .
rg -n "md5|sha1|createHash\('sha256'\)" --glob '!*.lock' .
rg -n "JWT_SECRET|SESSION_SECRET|NEXTAUTH_SECRET" .
rg -n "httpOnly|sameSite|secure:" .
rg -n "localStorage\.(setItem|getItem)\(.*(token|jwt)" -i .
```

## Tests de regresión sugeridos
- Login con contraseña incorrecta N veces → 429
- Token con `alg: none` o firma alterada → 401
- Token vencido → 401
- Reutilizar el token de reset → rechazado
- Después del logout, la cookie vieja → 401
