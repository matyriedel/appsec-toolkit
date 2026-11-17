---
tags: [checklist, pagos]
owasp: [A06, A08, API6, API10]
asvs: [V2]
---
# 7. Webhooks, suscripciones y pagos

## Webhooks
- [ ] **Firma verificada** con el secreto del proveedor, sobre el **body crudo** y con comparación en tiempo constante
  - Mercado Pago: header `x-signature` (`ts` + `v1`) más `x-request-id` y `data.id`
  - Stripe: `stripe.webhooks.constructEvent(rawBody, sig, secret)`
- [ ] Se rechazan eventos con timestamp viejo (anti-replay, tolerancia de ~5 min)
- [ ] **Idempotencia**: tabla de `event_id` procesados con UNIQUE; un evento duplicado no acredita dos veces
- [ ] Ante la notificación, se **consulta el estado real al proveedor** (`GET /v1/payments/:id`) en lugar de confiar en el payload
- [ ] Se verifica que el pago corresponda a la orden: `external_reference`, **monto**, **moneda**, cuenta receptora
- [ ] Respuesta 2xx rápida y procesamiento en cola; los reintentos del proveedor no generan efectos dobles
- [ ] El endpoint de webhook no tiene CSRF, pero sí rate limit; si el proveedor publica IPs, filtrar por ellas como defensa extra

## Checkout y lógica de negocio
- [ ] El precio y el total se calculan en el servidor desde la base, nunca desde el body
- [ ] Cantidades negativas, cero, decimales raros y overflow rechazados
- [ ] Cupones: un uso por usuario, con expiración, sin apilado indebido y con control de carrera
- [ ] Cambios de estado de la orden solo por transiciones válidas (`pendiente → pagada`, nunca `cancelada → pagada` desde el cliente)
- [ ] `back_url` / `success_url` **no** marcan la orden como pagada: solo lo hace el webhook verificado
- [ ] Operaciones concurrentes (doble click, dos pestañas) protegidas con transacción o lock

## Suscripciones
- [ ] El acceso premium depende del estado en la base, actualizado por webhook verificado, no de un flag del cliente
- [ ] Downgrade, cancelación y fallo de pago revocan el acceso
- [ ] El período de gracia está definido y testeado
- [ ] Un usuario no puede asociarse a la suscripción de otro (`preapproval_id` / `customer_id` verificado)

## WooCommerce
- [ ] Plugins de pago actualizados y del origen oficial
- [ ] El IPN/webhook valida firma; las órdenes no se completan solo por el retorno del navegador

## Tests de regresión sugeridos
- Webhook sin firma o con firma inválida → 401, sin cambios en la base
- Mismo evento enviado dos veces → un solo crédito
- Webhook con monto distinto al de la orden → la orden no se marca pagada
- POST de checkout con `price: 1` → se ignora y se usa el precio de la base
- Visitar `success_url` sin webhook → la orden sigue pendiente
