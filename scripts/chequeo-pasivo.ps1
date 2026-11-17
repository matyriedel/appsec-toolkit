<#
.SYNOPSIS
  Chequeo pasivo / activo liviano (niveles 0 y 1) de un dominio. Genera un informe Markdown.

.DESCRIPTION
  Solo hace consultas DNS, consultas a fuentes públicas (crt.sh, InternetDB de Shodan) y unas ~30 requests HTTP
  puntuales al dominio. No escanea puertos, no hace fuerza bruta, no envía formularios.
  Usalo solo con dominios propios o con autorización (ver metodologia/reglas-y-autorizacion.md).

.EXAMPLE
  .\chequeo-pasivo.ps1 -Dominio example.com
  .\chequeo-pasivo.ps1 -Dominio tienda.example.com -SinOsint -Salida .\informes
#>
param(
  [Parameter(Mandatory = $true)][string]$Dominio,
  [string]$Salida,
  [switch]$SinOsint
)

$ErrorActionPreference = 'Continue'
$Dominio = $Dominio.Trim().ToLower() -replace '^https?://', '' -replace '/.*$', ''
$fecha = Get-Date -Format 'yyyy-MM-dd'
$hora = Get-Date -Format 'HH:mm'
if (-not $Salida) { $Salida = Join-Path (Split-Path $PSScriptRoot -Parent) "informes\$Dominio" }
New-Item -ItemType Directory -Force $Salida | Out-Null

$md = New-Object System.Collections.Generic.List[string]
$resumen = New-Object System.Collections.Generic.List[object]
function Add([string]$linea) { $md.Add($linea) }
function Resultado([string]$control, [string]$estado, [string]$detalle, [string]$sev = '') {
  $resumen.Add([pscustomobject]@{ Control = $control; Estado = $estado; Detalle = $detalle; Sev = $sev })
}
function Curl-Status([string]$url, [string[]]$extra = @()) {
  $args2 = @('-s', '-o', 'NUL', '-w', '%{http_code} %{size_download}', '--max-time', '15') + $extra + @($url)
  $r = & curl.exe @args2
  $p = "$r".Split(' ')
  return [pscustomobject]@{ Code = [int]$p[0]; Size = [int]$p[1] }
}
function Curl-Headers([string]$url, [string[]]$extra = @()) {
  $args2 = @('-s', '-D', '-', '-o', 'NUL', '--max-time', '15') + $extra + @($url)
  $raw = & curl.exe @args2
  $h = @{}
  $status = ''
  foreach ($l in $raw) {
    if ($l -match '^HTTP/') { $status = $l.Trim(); $h = @{} }
    elseif ($l -match '^([^:]+):\s*(.*)$') { $h[$matches[1].ToLower()] = $matches[2].Trim() }
  }
  return [pscustomobject]@{ Status = $status; H = $h }
}

Write-Host "Chequeo pasivo de $Dominio ..." -ForegroundColor Cyan

# ---------------- DNS ----------------
Add "## DNS"
$a = @(Resolve-DnsName $Dominio -Type A -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'A' | % IPAddress)
$aaaa = @(Resolve-DnsName $Dominio -Type AAAA -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'AAAA' | % IPAddress)
$cname = @(Resolve-DnsName $Dominio -Type CNAME -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'CNAME' | % NameHost)
$mx = @(Resolve-DnsName $Dominio -Type MX -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'MX' | % { "$($_.Preference) $($_.NameExchange)" })
$ns = @(Resolve-DnsName $Dominio -Type NS -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'NS' | % NameHost)
$txt = @(Resolve-DnsName $Dominio -Type TXT -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'TXT' | % { $_.Strings -join '' })
$caa = @()
try { $caa = @((Invoke-RestMethod "https://dns.google/resolve?name=$Dominio&type=CAA" -TimeoutSec 15).Answer | ? { $_.type -eq 257 } | % data) } catch { }
$dmarc = @(Resolve-DnsName "_dmarc.$Dominio" -Type TXT -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'TXT' | % { $_.Strings -join '' })
$spf = @($txt | ? { $_ -like 'v=spf1*' })
$rnd = "zz-noexiste-$(Get-Random)." + $Dominio
$wild = @(Resolve-DnsName $rnd -Type A -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'A')

Add "| Registro | Valor |"
Add "|---|---|"
Add "| A | $($a -join ', ') |"
Add "| AAAA | $($aaaa -join ', ') |"
if ($cname) { Add "| CNAME | $($cname -join ', ') |" }
Add "| MX | $($mx -join '<br>') |"
Add "| NS | $($ns -join ', ') |"
Add "| SPF | $(if ($spf.Count) { '`' + ($spf -join ' / ') + '`' } else { '—' }) |"
Add "| DMARC | $(if ($dmarc.Count) { '`' + ($dmarc -join ' / ') + '`' } else { '—' }) |"
Add "| CAA | $(if ($caa.Count) { $caa -join ', ' } else { '—' }) |"
Add "| Wildcard | $(if ($wild.Count) { 'sí (un subdominio inventado resuelve)' } else { 'no' }) |"
Add ""

$privadas = @($a | ? { $_ -match '^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|127\.)' })
if ($privadas.Count) { Resultado 'DNS público sin IPs privadas' '❌' "Resuelve a $($privadas -join ', ')" 'media' } else { Resultado 'DNS público sin IPs privadas' '✅' "A: $($a -join ', ')" }
if ($spf.Count -eq 0) { Resultado 'SPF' '❌' 'No hay registro SPF' 'media' }
elseif ($spf.Count -gt 1) { Resultado 'SPF' '❌' 'Hay más de un registro SPF (inválido)' 'media' }
elseif ($spf[0] -match '\+all') { Resultado 'SPF' '❌' 'SPF con +all: autoriza a cualquiera' 'alta' }
else { Resultado 'SPF' '✅' $spf[0] }
if ($dmarc.Count -eq 0) { Resultado 'DMARC' '❌' 'No hay registro DMARC' 'media' }
elseif ($dmarc[0] -match 'p=none') { Resultado 'DMARC' '⚠️' "Solo monitoreo: $($dmarc[0])" 'baja' }
else { Resultado 'DMARC' '✅' $dmarc[0] }
if ($caa.Count) { Resultado 'CAA' '✅' 'Presente' } else { Resultado 'CAA' '⚠️' 'Sin CAA: cualquier CA puede emitir certificados' 'baja' }

# ---------------- OSINT (nivel 0) ----------------
$subs = @()
if (-not $SinOsint) {
  Add "## OSINT (fuentes públicas)"
  try {
    $ct = Invoke-RestMethod "https://crt.sh/?q=%25.$Dominio&output=json" -TimeoutSec 40
    $subs = @($ct | % { $_.name_value -split "`n" } | % { $_.Trim().ToLower() } | ? { $_ -and $_ -notlike '*@*' } | Sort-Object -Unique)
    Add "**Certificate Transparency (crt.sh):** $($subs.Count) nombres"
    Add ""
    if ($subs.Count) {
      Add "| Nombre | Resuelve a |"
      Add "|---|---|"
      foreach ($s in ($subs | Select-Object -First 60)) {
        if ($s.StartsWith('*.')) { Add "| ``$s`` | (wildcard) |"; continue }
        $ip = @(Resolve-DnsName $s -Type A -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'A' | % IPAddress)
        $cn = @(Resolve-DnsName $s -Type CNAME -DnsOnly -ErrorAction SilentlyContinue | ? Type -eq 'CNAME' | % NameHost)
        $dest = (@($cn | % { "CNAME $_" }) + $ip) -join ', '
        if (-not $dest) { $dest = 'no resuelve' }
        Add "| ``$s`` | $dest |"
      }
      if ($subs.Count -gt 60) { Add "| … | $($subs.Count - 60) más |" }
    }
    Resultado 'Subdominios inventariados (CT)' '⏳' "$($subs.Count) nombres en crt.sh: revisar que todos sean conocidos y estén en uso" ''
  } catch {
    Add "crt.sh no respondió: $($_.Exception.Message)"
    Resultado 'Subdominios inventariados (CT)' '⏳' 'crt.sh no respondió; reintentar' ''
  }
  Add ""
  foreach ($ip in $a) {
    try {
      $idb = Invoke-RestMethod "https://internetdb.shodan.io/$ip" -TimeoutSec 20
      Add "**InternetDB (Shodan) $($ip):** puertos $($idb.ports -join ', ') · CPEs $($idb.cpes -join ', ') · vulns $(@($idb.vulns).Count)"
      $raros = @($idb.ports | ? { $_ -notin 80, 443 })
      if ($raros.Count) { Resultado "Puertos indexados en $ip" '⚠️' "Shodan ve abiertos: $($raros -join ', ') (confirmar a mano)" 'media' }
      else { Resultado "Puertos indexados en $ip" '✅' 'Solo 80/443 según Shodan' }
      if (@($idb.vulns).Count) { Resultado "CVEs indexados en $ip" '⚠️' "$(@($idb.vulns).Count) CVEs por versión de banner (pueden ser falsos positivos): $((@($idb.vulns) | Select -First 8) -join ', ')" 'media' }
    } catch {
      Add "**InternetDB (Shodan) $($ip):** sin datos (IP no indexada o sin puertos)"
    }
  }
  Add ""
}

# ---------------- HTTP → HTTPS ----------------
Add "## HTTP y TLS"
$http = Curl-Headers "http://$Dominio/"
$loc = $http.H['location']
Add "- ``http://$Dominio/`` → $($http.Status) $(if ($loc) { "→ $loc" })"
if ($http.Status -match ' 30[18] ' -and $loc -like 'https://*') { Resultado 'HTTP redirige a HTTPS' '✅' "$($http.Status) → $loc" }
elseif (-not $http.Status) { Resultado 'HTTP redirige a HTTPS' '⏳' 'El puerto 80 no respondió' '' }
else { Resultado 'HTTP redirige a HTTPS' '❌' "Responde $($http.Status) sin redirigir" 'baja' }

# ---------------- TLS ----------------
try {
  $c = New-Object Net.Sockets.TcpClient
  if (-not $c.ConnectAsync($Dominio, 443).Wait(8000)) { throw 'timeout al puerto 443' }
  $s = New-Object Net.Security.SslStream($c.GetStream(), $false, ({ $true }))
  $s.AuthenticateAsClient($Dominio)
  $x = New-Object Security.Cryptography.X509Certificates.X509Certificate2($s.RemoteCertificate)
  $san = ($x.Extensions | ? { $_.Oid.Value -eq '2.5.29.17' } | % { $_.Format($false) }) -join ''
  $dias = [int]($x.NotAfter - (Get-Date)).TotalDays
  $valido = $x.Verify()
  Add "- Protocolo negociado: **$($s.SslProtocol)**"
  Add "- Certificado: ``$($x.Subject)`` · emisor ``$($x.Issuer)`` · vence **$($x.NotAfter.ToString('yyyy-MM-dd'))** ($dias días)"
  Add "- SAN: $san"
  $c.Close()
  if (-not $valido) { Resultado 'Certificado válido' '❌' 'La cadena no valida en Windows' 'alta' } else { Resultado 'Certificado válido' '✅' $x.Issuer }
  if ($dias -lt 15) { Resultado 'Vencimiento del certificado' '❌' "Vence en $dias días" 'alta' }
  elseif ($dias -lt 30) { Resultado 'Vencimiento del certificado' '⚠️' "Vence en $dias días: confirmar la renovación automática" 'media' }
  else { Resultado 'Vencimiento del certificado' '✅' "$dias días" }
} catch {
  Add "- TLS: error $($_.Exception.Message)"
  Resultado 'TLS' '❌' "No se pudo negociar TLS: $($_.Exception.Message)" 'alta'
}
& curl.exe -s -o NUL --max-time 10 --tlsv1.0 --tls-max 1.1 "https://$Dominio/" 2>$null
if ($LASTEXITCODE -eq 0) { Resultado 'TLS 1.0/1.1 rechazado' '❌' 'El servidor acepta TLS ≤ 1.1' 'media' } else { Resultado 'TLS 1.0/1.1 rechazado' '✅' "curl con TLS ≤ 1.1 falla (código $LASTEXITCODE)" }
Add ""

# ---------------- Cabeceras ----------------
Add "## Cabeceras"
$principal = Curl-Headers "https://$Dominio/"
$noexiste = "/zz-noexiste-$(Get-Random)"
$err = Curl-Headers "https://$Dominio$noexiste"
$seg = 'strict-transport-security', 'content-security-policy', 'x-content-type-options', 'x-frame-options', 'referrer-policy', 'permissions-policy'
Add "| Cabecera | Home ($($principal.Status)) | Error ($($err.Status)) |"
Add "|---|---|---|"
foreach ($n in $seg) {
  $v1 = $principal.H[$n]; $v2 = $err.H[$n]
  $t1 = if ($v1) { '✅ ' + ($v1.Substring(0, [Math]::Min(60, $v1.Length))) } else { '❌' }
  $t2 = if ($v2) { '✅' } else { '❌' }
  Add "| ``$n`` | $t1 | $t2 |"
}
foreach ($n in 'server', 'x-powered-by', 'via', 'x-generator') { if ($principal.H[$n]) { Add "| ``$n`` | $($principal.H[$n]) | |" } }
Add ""
$faltan = @($seg | ? { -not $principal.H[$_] } | ? { $_ -ne 'permissions-policy' })
if ($faltan.Count) { Resultado 'Cabeceras de seguridad' '❌' "Faltan: $($faltan -join ', ')" 'baja' } else { Resultado 'Cabeceras de seguridad' '✅' 'HSTS, CSP, nosniff, XFO y Referrer-Policy presentes' }
$ver = @('server', 'x-powered-by') | ? { $principal.H[$_] -match '\d' } | % { "$_ = $($principal.H[$_])" }
if ($ver) { Resultado 'Banners sin versión' '⚠️' ($ver -join '; ') 'baja' } else { Resultado 'Banners sin versión' '✅' 'Sin números de versión en Server / X-Powered-By' }
$cookies = @($principal.H.Keys | ? { $_ -eq 'set-cookie' } | % { $principal.H[$_] })
foreach ($ck in $cookies) {
  $falt = @('Secure', 'HttpOnly', 'SameSite') | ? { $ck -notmatch $_ }
  if ($falt.Count) { Resultado 'Flags de cookies' '⚠️' "Cookie sin $($falt -join ', '): $($ck.Split('=')[0])" 'baja' }
}

# ---------------- CORS ----------------
$cors = Curl-Headers "https://$Dominio/" @('-H', 'Origin: https://evil.example')
$acao = $cors.H['access-control-allow-origin']; $acac = $cors.H['access-control-allow-credentials']
if ($acao -eq 'https://evil.example' -and $acac -eq 'true') { Resultado 'CORS' '❌' 'Refleja un origen externo con credenciales' 'alta' }
elseif ($acao -eq 'https://evil.example') { Resultado 'CORS' '⚠️' 'Refleja un origen externo (sin credenciales)' 'baja' }
elseif ($acao -eq '*') { Resultado 'CORS' '⚠️' 'Access-Control-Allow-Origin: * en la home' 'info' }
else { Resultado 'CORS' '✅' 'No refleja un origen externo en la home (revisar también la API)' }

# ---------------- Rutas expuestas ----------------
Add "## Rutas sensibles"
$base = Curl-Status "https://$Dominio$noexiste"
Add "Línea base (ruta inventada): **$($base.Code)**, $($base.Size) bytes. Un 200 con un tamaño parecido es un '200 falso'."
Add ""
Add "| Ruta | Código | Bytes | Lectura |"
Add "|---|---|---|---|"
$rutas = '/.env', '/.env.production', '/production.env', '/.git/HEAD', '/.git/config', '/.svn/entries',
'/backup.zip', '/backup.sql', '/dump.sql', '/db.sql', '/docker-compose.yml', '/Dockerfile',
'/phpinfo.php', '/info.php', '/server-status', '/wp-config.php.bak', '/.DS_Store',
'/phpmyadmin/', '/adminer.php', '/swagger', '/api-docs', '/graphql',
'/wp-login.php', '/xmlrpc.php', '/wp-json/wp/v2/users',
'/robots.txt', '/sitemap.xml', '/.well-known/security.txt'
$criticas = '/.env', '/.env.production', '/production.env', '/.git/HEAD', '/.git/config', '/.svn/entries', '/backup.zip', '/backup.sql', '/dump.sql', '/db.sql', '/wp-config.php.bak'
$expuestas = @()
foreach ($r in $rutas) {
  $st = Curl-Status "https://$Dominio$r"
  $parecido = ($base.Code -eq 200 -and [Math]::Abs($st.Size - $base.Size) -le [Math]::Max(200, $base.Size * 0.05))
  $lectura = ''
  if ($st.Code -eq 200 -and $r -in '/robots.txt', '/sitemap.xml', '/.well-known/security.txt') { $lectura = 'público (normal)' }
  elseif ($st.Code -eq 200 -and -not $parecido) { $lectura = '**responde: revisar**'; if ($r -notin '/robots.txt', '/sitemap.xml', '/.well-known/security.txt', '/wp-login.php') { $expuestas += $r } }
  elseif ($st.Code -eq 200) { $lectura = '200 falso' }
  elseif ($st.Code -in 401, 403) { $lectura = 'existe, protegida' }
  Add "| ``$r`` | $($st.Code) | $($st.Size) | $lectura |"
}
Add ""
$crit = @($expuestas | ? { $_ -in $criticas })
if ($crit.Count) { Resultado 'Archivos sensibles expuestos' '❌' "Responden con contenido: $($crit -join ', ') (confirmar a mano SIN guardar el contenido)" 'critica' }
else { Resultado 'Archivos sensibles expuestos' '✅' 'Ninguno de los archivos críticos probados responde con contenido' }
$otras = @($expuestas | ? { $_ -notin $criticas })
if ($otras.Count) { Resultado 'Rutas de gestión o documentación' '⚠️' "Responden: $($otras -join ', ')" 'media' }
$sec = Curl-Status "https://$Dominio/.well-known/security.txt"
if ($sec.Code -eq 200 -and -not ($base.Code -eq 200 -and [Math]::Abs($sec.Size - $base.Size) -le 200)) { Resultado 'security.txt' '✅' 'Publicado' } else { Resultado 'security.txt' '⚠️' 'No publicado (recomendado, RFC 9116)' 'info' }

# ---------------- Nota final ----------------
$orden = @{ 'critica' = 0; 'alta' = 1; 'media' = 2; 'baja' = 3; 'info' = 4; '' = 5 }
$problemas = @($resumen | ? { $_.Estado -in '❌', '⚠️' })
$cuerpo = New-Object System.Collections.Generic.List[string]
$cuerpo.Add("---")
$cuerpo.Add("tipo: chequeo")
$cuerpo.Add("objetivo: $Dominio")
$cuerpo.Add("fecha: $fecha")
$cuerpo.Add("nivel: 1")
$cuerpo.Add("herramienta: chequeo-pasivo.ps1")
$cuerpo.Add("problemas: $($problemas.Count)")
$cuerpo.Add("---")
$cuerpo.Add("# Chequeo pasivo · $Dominio · $fecha $hora")
$cuerpo.Add("")
$cuerpo.Add("Nivel 0-1 (ver metodologia/niveles-de-prueba.md). Origen: $env:COMPUTERNAME. Lo marcado ❌/⚠️ es una **señal**: confirmala a mano antes de registrarla como hallazgo.")
$cuerpo.Add("")
$cuerpo.Add("## Resumen")
$cuerpo.Add("| Control | Estado | Severidad sugerida | Detalle |")
$cuerpo.Add("|---|---|---|---|")
foreach ($r in ($resumen | Sort-Object { $orden[$_.Sev] })) { $cuerpo.Add("| $($r.Control) | $($r.Estado) | $($r.Sev) | $($r.Detalle -replace '\|', '/') |") }
$cuerpo.Add("")
$cuerpo.Add("> Lo que este script **no** cubre queda ⏳: puertos (requiere nivel 2 y autorización), DKIM, subdomain takeover, fingerprint de versiones y CVEs, paneles y login.")
$cuerpo.Add("")
$cuerpo.AddRange($md)

$archivo = Join-Path $Salida "Chequeo pasivo $fecha.md"
$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllLines($archivo, $cuerpo, $utf8)
Write-Host "Listo: $archivo" -ForegroundColor Green
Write-Host ("Problemas: {0}  (❌ {1} · ⚠️ {2})" -f $problemas.Count, @($problemas | ? Estado -eq '❌').Count, @($problemas | ? Estado -eq '⚠️').Count)
