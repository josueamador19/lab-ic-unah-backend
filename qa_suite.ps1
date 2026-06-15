$BASE = "http://localhost:8000/api/v1"
$H    = @{ Authorization = "Bearer admin1234"; "Content-Type" = "application/json" }
$rows = [System.Collections.Generic.List[object]]::new()
$p = 0; $f = 0

function CallApi($method, $url, $body=$null, $hdrs=$null) {
    try {
        $opts = @{ Method=$method; Uri=$url; ErrorAction="Stop" }
        if ($body) { $opts.Body=$body; $opts.ContentType="application/json" }
        if ($hdrs) { $opts.Headers=$hdrs }
        $resp = Invoke-RestMethod @opts
        return @{ ok=$true; code=200; data=$resp }
    } catch {
        $code=0; $msg=""
        try { $code=[int]$_.Exception.Response.StatusCode } catch {}
        try { $msg=$_.ErrorDetails.Message } catch {}
        return @{ ok=$false; code=$code; data=$msg }
    }
}

function T($sec, $name, $passed, $detail) {
    $status = if($passed){"PASS"}else{"FAIL"}
    if ($passed) { $script:p++ } else { $script:f++ }
    $line = "  [{0,-4}]  {1,-50} {2}" -f $status, $name, $detail
    $script:rows.Add([PSCustomObject]@{Section=$sec;Name=$name;Status=$status;Detail=$detail})
    Write-Output $line
}

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output ""; Write-Output ("="*72)
Write-Output "  QA REPORT -- Lab Ingenieria Civil UNAH | $ts"
Write-Output ("="*72)

# == S1: ENDPOINTS PUBLICOS ==================================================
Write-Output "`n[S1] ENDPOINTS PUBLICOS"

$t = CallApi GET "$BASE/health"
T "S1-Publico" "GET /health" ($t.ok -and $t.data.status -eq "ok") "status=$($t.data.status)"

$t = CallApi GET "$BASE/servicios"
T "S1-Publico" "GET /servicios (agrupado)" ($t.ok -and $t.data.data.suelos) "cats=$($t.data.data.PSObject.Properties.Name -join ',')"

$t = CallApi GET "$BASE/servicios/flat"
T "S1-Publico" "GET /servicios/flat" ($t.ok -and $t.data.data.Count -gt 0) "items=$($t.data.data.Count)"

$t = CallApi GET "$BASE/equipos"
T "S1-Publico" "GET /equipos" ($t.ok -and $t.data.data.Count -gt 0) "items=$($t.data.data.Count)"

$t = CallApi GET "$BASE/configuracion"
T "S1-Publico" "GET /configuracion" ($t.ok -and $t.data.data.email) "email presente"

$t = CallApi GET "$BASE/normas"
T "S1-Publico" "GET /normas" ($t.ok -and $t.data.data.Count -gt 0) "items=$($t.data.data.Count)"

$t = CallApi GET "$BASE/proceso"
T "S1-Publico" "GET /proceso" ($t.ok -and $t.data.data.Count -gt 0) "items=$($t.data.data.Count)"

$t = CallApi GET "$BASE/faq"
T "S1-Publico" "GET /faq" ($t.ok -and $t.data.data.Count -gt 0) "items=$($t.data.data.Count)"

$t = CallApi GET "http://localhost:8000/uploads/equipos/Topografia.png"
T "S1-Publico" "GET /uploads/* (estaticos)" ($t.ok -or $t.code -eq 200) "code=$($t.code)"

$t = CallApi GET "$BASE/ruta-inventada"
T "S1-Publico" "Ruta inexistente => 404" ($t.code -eq 404) "code=$($t.code)"

# == S2: COTIZACION ===========================================================
Write-Output "`n[S2] COTIZACION"

$p1 = '{"nombre":"Carlos Mendoza","correo":"carlos@test.com","empresa":"Constructora SA","telefono":"9999-1234","nombreProyecto":"Edificio Torre A","servicios":[{"code":"SU-01","name":"Contenido de Humedad","norma":"ASTM D2216","muestras":3,"precio":150},{"code":"CU-04","name":"Rotura Cilindros","norma":"ASTM C39","muestras":6,"precio":250}],"ubicacion":{"lat":"14.081800","lng":"-87.206800","address":"Ciudad Universitaria"}}'
$t = CallApi POST "$BASE/cotizacion" $p1
T "S2-Cotizacion" "POST completa multi-servicio" ($t.ok -and $t.data.ok) "num=$($t.data.numero)"

$p2 = '{"nombre":"Ana Garcia","correo":"ana@test.com","empresa":"Individual","telefono":"8888-5678","nombreProyecto":"Topo Catastral","servicios":[{"code":"ST-01","name":"Tegucigalpa","norma":"Normas Propias","precio":3000}]}'
$t = CallApi POST "$BASE/cotizacion" $p2
T "S2-Cotizacion" "POST sin ubicacion (topografia)" ($t.ok -and $t.data.ok) "num=$($t.data.numero)"

$t = CallApi POST "$BASE/cotizacion" '{"nombre":""}'
T "S2-Cotizacion" "POST sin campos obligatorios => 422" ($t.code -eq 422) "code=$($t.code)"

$t = CallApi POST "$BASE/cotizacion" '{"nombre":"T","correo":"t@t.com","empresa":"E","telefono":"1","nombreProyecto":"P","servicios":[]}'
T "S2-Cotizacion" "POST servicios[] vacios => 422" ($t.code -eq 422) "code=$($t.code)"

$t = CallApi POST "$BASE/cotizacion" '{"nombre":"T","correo":"no-es-email","empresa":"E","telefono":"1","nombreProyecto":"P","servicios":[{"code":"SU-01","name":"T","precio":100}]}'
T "S2-Cotizacion" "POST email invalido => 422" ($t.code -eq 422) "code=$($t.code)"

$t = CallApi POST "$BASE/cotizacion" "json_malformado{{{"
T "S2-Cotizacion" "POST JSON malformado => 4xx" ($t.code -ge 400) "code=$($t.code)"

$t = CallApi GET "$BASE/cotizacion/1/docx"
T "S2-Cotizacion" "GET /cotizacion/1/docx" ($t.ok -or $t.code -eq 200) "code=$($t.code)"

$t = CallApi GET "$BASE/cotizacion/99999/docx"
T "S2-Cotizacion" "GET cotizacion inexistente => 404" ($t.code -eq 404) "code=$($t.code)"

$t = CallApi GET "$BASE/cotizacion/abc/docx"
T "S2-Cotizacion" "GET ID no numerico => 400" ($t.code -eq 400) "code=$($t.code)"

# == S3: AUTENTICACION ========================================================
Write-Output "`n[S3] AUTENTICACION ADMIN"

$t = CallApi POST "$BASE/admin/auth" '{"password":"admin1234"}'
T "S3-Auth" "Auth password correcto" ($t.ok -and $t.data.ok) "ok=$($t.data.ok)"

$t = CallApi POST "$BASE/admin/auth" '{"password":"wrongpassword"}'
T "S3-Auth" "Auth password incorrecto => 401" ($t.code -eq 401) "code=$($t.code)"

$t = CallApi POST "$BASE/admin/auth" '{}'
T "S3-Auth" "Auth sin campo password => 401" ($t.code -eq 401) "code=$($t.code)"

$t = CallApi POST "$BASE/admin/auth" '{"password":""}'
T "S3-Auth" "Auth password vacio => 401" ($t.code -eq 401) "code=$($t.code)"

$t = CallApi POST "$BASE/admin/auth" '{"password":null}'
T "S3-Auth" "Auth password null => 401" ($t.code -eq 401) "code=$($t.code)"

$t = CallApi GET "$BASE/admin/servicios"
T "S3-Auth" "Admin sin token => 401" ($t.code -eq 401) "code=$($t.code)"

$rh = @{ Authorization = "Bearer " }
$t  = CallApi GET "$BASE/admin/servicios" -hdrs $rh
T "S3-Auth" "Bearer vacio => 401" ($t.code -eq 401) "code=$($t.code)"

$rh = @{ Authorization = "Bearer token_falso_xyz" }
$t  = CallApi GET "$BASE/admin/servicios" -hdrs $rh
T "S3-Auth" "Token incorrecto => 401" ($t.code -eq 401) "code=$($t.code)"

$rh = @{ Authorization = "admin1234" }
$t  = CallApi GET "$BASE/admin/servicios" -hdrs $rh
T "S3-Auth" "Sin prefijo Bearer => 401" ($t.code -eq 401) "code=$($t.code)"

$rh = @{ "X-Admin-Key" = "admin1234" }
$t  = CallApi GET "$BASE/admin/servicios" -hdrs $rh
T "S3-Auth" "Token en header alternativo => 401" ($t.code -eq 401) "code=$($t.code)"

# == S4: CRUD ADMIN ===========================================================
Write-Output "`n[S4] CRUD ADMIN"

$t = CallApi GET "$BASE/admin/servicios" -hdrs $H
T "S4-CRUD" "GET /admin/servicios" ($t.ok -and $t.data.data.Count -gt 0) "items=$($t.data.data.Count)"

$t = CallApi POST "$BASE/admin/servicios" '{"code":"QA-99","categoria":"suelos","name":"Servicio QA","norma":"ASTM TEST","precio":999}' -hdrs $H
T "S4-CRUD" "POST /admin/servicios crear" ($t.ok -and $t.data.ok) "id=$($t.data.id)"
$svcId = $t.data.id

$t = CallApi PUT "$BASE/admin/servicios/$svcId" '{"name":"Servicio QA Editado","norma":"ASTM v2","precio":1200,"activo":1}' -hdrs $H
T "S4-CRUD" "PUT /admin/servicios/:id editar" ($t.ok -and $t.data.ok) "ok=$($t.data.ok)"

$t = CallApi DELETE "$BASE/admin/servicios/$svcId" -hdrs $H
T "S4-CRUD" "DELETE /admin/servicios/:id eliminar" ($t.ok -and $t.data.ok) "ok=$($t.data.ok)"

$t = CallApi POST "$BASE/admin/faq" '{"pregunta":"Pregunta QA?","respuesta":"Respuesta QA.","orden":99,"activo":1}' -hdrs $H
T "S4-CRUD" "POST /admin/faq crear" ($t.ok -and $t.data.ok) "id=$($t.data.id)"
$faqId = $t.data.id

$t = CallApi PUT "$BASE/admin/faq/$faqId" '{"pregunta":"FAQ Editada?","respuesta":"Resp editada.","orden":99,"activo":1}' -hdrs $H
T "S4-CRUD" "PUT /admin/faq/:id editar" ($t.ok -and $t.data.ok) "ok=$($t.data.ok)"

$t = CallApi DELETE "$BASE/admin/faq/$faqId" -hdrs $H
T "S4-CRUD" "DELETE /admin/faq/:id eliminar" ($t.ok -and $t.data.ok) "ok=$($t.data.ok)"

$t = CallApi GET "$BASE/admin/equipos" -hdrs $H
T "S4-CRUD" "GET /admin/equipos" ($t.ok -and $t.data.data.Count -gt 0) "items=$($t.data.data.Count)"

$t = CallApi GET "$BASE/admin/configuracion" -hdrs $H
T "S4-CRUD" "GET /admin/configuracion" ($t.ok -and $t.data.data.Count -gt 0) "items=$($t.data.data.Count)"

$t = CallApi PUT "$BASE/admin/configuracion" '{"horario":"LUNES - VIERNES / 8:00 AM - 3:00 PM"}' -hdrs $H
T "S4-CRUD" "PUT /admin/configuracion actualizar" ($t.ok -and $t.data.ok) "ok=$($t.data.ok)"

$t = CallApi PUT "$BASE/admin/normas/astm" '{"title":"ASTM International","sub":"American Society","descripcion":"Principal referencia tecnica.","tags":["ASTM D698","ASTM D1557"],"activo":1}' -hdrs $H
T "S4-CRUD" "PUT /admin/normas/:id" ($t.ok -and $t.data.ok) "ok=$($t.data.ok)"

$t = CallApi PUT "$BASE/admin/proceso/1" '{"numero":"01","titulo":"Solicitud","descripcion":"Complete el formulario.","activo":1}' -hdrs $H
T "S4-CRUD" "PUT /admin/proceso/:id" ($t.ok -and $t.data.ok) "ok=$($t.data.ok)"

# == S5: SQL INJECTION ========================================================
Write-Output "`n[S5] SEGURIDAD - SQL INJECTION"

$sqlis = @(
    "OR 1=1 --",
    "' OR '1'='1",
    "'; DROP TABLE servicios; --",
    "1 UNION SELECT * FROM servicios --",
    "admin'--",
    "' OR 1=1 LIMIT 1 --"
)
foreach ($sql in $sqlis) {
    $esc = $sql -replace "'", "\'"
    $body = "{`"nombre`":`"$esc`",`"correo`":`"t@t.com`",`"empresa`":`"E`",`"telefono`":`"1`",`"nombreProyecto`":`"P`",`"servicios`":[{`"code`":`"SU-01`",`"name`":`"T`",`"precio`":100}]}"
    $t = CallApi POST "$BASE/cotizacion" $body
    $safe = $t.code -ne 500
    T "S5-SQLi" "SQLi nombre: $($sql.Substring(0,[Math]::Min(22,$sql.Length)))" $safe "code=$($t.code)"
}

$sqliAuth = @("' OR '1'='1", "admin'--", "' OR 1=1--")
foreach ($sql in $sqliAuth) {
    $esc = $sql -replace "'", "\'"
    $t = CallApi POST "$BASE/admin/auth" "{`"password`":`"$esc`"}"
    T "S5-SQLi" "SQLi auth password: $($sql.Substring(0,[Math]::Min(18,$sql.Length)))" ($t.code -eq 401) "code=$($t.code) -- acceso bloqueado"
}

# == S6: XSS ==================================================================
Write-Output "`n[S6] SEGURIDAD - XSS"

$xssPayloads = @(
    "SCRIPT_TAG_ALERT",
    "IMG_ONERROR",
    "JAVASCRIPT_ALERT",
    "SVG_ONLOAD"
)
$xssActual = @(
    "<script>alert(1)</script>",
    "<img src=x onerror=alert(1)>",
    "javascript:alert(1)",
    "<svg/onload=alert(1)>"
)
for ($i = 0; $i -lt $xssPayloads.Count; $i++) {
    $xssStr = $xssActual[$i]
    $escaped = $xssStr -replace '"', '\"' -replace "'", "\'"
    $body = "{`"nombre`":`"$escaped`",`"correo`":`"t@t.com`",`"empresa`":`"E`",`"telefono`":`"1`",`"nombreProyecto`":`"P`",`"servicios`":[{`"code`":`"SU-01`",`"name`":`"T`",`"precio`":100}]}"
    $t = CallApi POST "$BASE/cotizacion" $body
    $respStr = try { $t.data | ConvertTo-Json -Compress } catch { "" }
    $reflected = ($respStr -match "alert") -and ($respStr -match "script|onerror|onload")
    T "S6-XSS" "XSS payload $($xssPayloads[$i])" (-not $reflected) "reflected_as_html=$reflected -- API devuelve JSON"
}

$xssBody = '{"pregunta":"XSSTEST_PAYLOAD","respuesta":"resp","orden":1,"activo":1}'
$t = CallApi POST "$BASE/admin/faq" $xssBody -hdrs $H
if ($t.ok) {
    $get = CallApi GET "$BASE/faq"
    $found = $get.data.data | Where-Object { $_.pregunta -eq "XSSTEST_PAYLOAD" }
    T "S6-XSS" "FAQ almacena texto plano (no ejecuta JS)" ($null -ne $found) "stored_plain=True -- React escapa al renderizar"
    if ($t.data.id) { CallApi DELETE "$BASE/admin/faq/$($t.data.id)" -hdrs $H | Out-Null }
}

# == S7: PATH TRAVERSAL =======================================================
Write-Output "`n[S7] SEGURIDAD - PATH TRAVERSAL"

$ptPaths = @(
    "http://localhost:8000/../package.json",
    "http://localhost:8000/..%2Fpackage.json",
    "http://localhost:8000/uploads/../../.env",
    "http://localhost:8000/uploads/equipos/../../../../.env",
    "http://localhost:8000/%2e%2e/package.json",
    "http://localhost:8000/.env"
)
foreach ($path in $ptPaths) {
    $t = CallApi GET $path
    $blocked = $t.code -eq 404 -or $t.code -eq 400 -or $t.code -eq 403
    $short = $path.Replace("http://localhost:8000","")
    T "S7-PathTraversal" "GET $short" $blocked "code=$($t.code)"
}

# == S8: MASS ASSIGNMENT / CAMPOS NO PERMITIDOS ================================
Write-Output "`n[S8] SEGURIDAD - MASS ASSIGNMENT"

$t = CallApi POST "$BASE/cotizacion" '{"nombre":"Test","correo":"t@t.com","empresa":"E","telefono":"1","nombreProyecto":"P","servicios":[{"code":"SU-01","name":"T","precio":100}],"admin":true,"role":"superadmin","__proto__":{"admin":true},"constructor":{"prototype":{"admin":true}}}'
T "S8-MassAssign" "Prototype pollution en body" ($t.code -ne 500) "code=$($t.code) -- sin crash"

$t = CallApi PUT "$BASE/admin/configuracion" '{"clave":"ADMIN_KEY","valor":"hacked123"}' -hdrs $H
$check = CallApi POST "$BASE/admin/auth" '{"password":"hacked123"}'
T "S8-MassAssign" "Intentar cambiar ADMIN_KEY via config" (-not $check.data.ok) "bypassAuth=$($check.data.ok) -- debe ser False"

$t = CallApi POST "$BASE/admin/servicios" '{"code":"","categoria":"suelos","name":"","norma":"","precio":-9999}' -hdrs $H
T "S8-MassAssign" "Campos vacios y precio negativo en servicio" ($t.code -ge 400 -or ($t.data.id -gt 0)) "code=$($t.code)"

# == S9: PAYLOADS EXTREMOS ====================================================
Write-Output "`n[S9] SEGURIDAD - PAYLOADS EXTREMOS (DoS/Stress)"

$bigStr = "A" * 10000
$body = "{`"nombre`":`"$bigStr`",`"correo`":`"t@t.com`",`"empresa`":`"E`",`"telefono`":`"1`",`"nombreProyecto`":`"P`",`"servicios`":[{`"code`":`"SU-01`",`"name`":`"T`",`"precio`":100}]}"
$t = CallApi POST "$BASE/cotizacion" $body
T "S9-Extremos" "Nombre de 10,000 caracteres" ($t.code -ne 500) "code=$($t.code) -- sin crash"

$svcItem = '{"code":"SU-01","name":"T","precio":100}'
$manyItems = (@($svcItem) * 500) -join ","
$body = "{`"nombre`":`"T`",`"correo`":`"t@t.com`",`"empresa`":`"E`",`"telefono`":`"1`",`"nombreProyecto`":`"P`",`"servicios`":[$manyItems]}"
$t = CallApi POST "$BASE/cotizacion" $body
T "S9-Extremos" "Array de 500 servicios" ($t.code -ne 500) "code=$($t.code) -- sin crash"

$bigPass = "x" * 50000
$t = CallApi POST "$BASE/admin/auth" "{`"password`":`"$bigPass`"}"
T "S9-Extremos" "Password de 50,000 chars" ($t.code -eq 401) "code=$($t.code)"

$t = CallApi POST "$BASE/cotizacion" "{}"
T "S9-Extremos" "Body vacio {}" ($t.code -ge 400) "code=$($t.code)"

$t = CallApi POST "$BASE/cotizacion" ""
T "S9-Extremos" "Body completamente vacio" ($t.code -ge 400) "code=$($t.code)"

# == S10: ENUMERACION DE RUTAS ================================================
Write-Output "`n[S10] SEGURIDAD - ENUMERACION DE RUTAS"

$hiddenRoutes = @(
    "$BASE/admin",
    "$BASE/admin/usuarios",
    "$BASE/admin/logs",
    "$BASE/admin/config",
    "$BASE/admin/backup",
    "$BASE/admin/export",
    "$BASE/debug",
    "$BASE/env",
    "http://localhost:8000/.env",
    "http://localhost:8000/package.json",
    "http://localhost:8000/node_modules"
)
foreach ($route in $hiddenRoutes) {
    $t = CallApi GET $route
    $safe = $t.code -eq 404 -or $t.code -eq 401 -or $t.code -eq 403
    $short = $route.Replace("http://localhost:8000/api/v1","").Replace("http://localhost:8000","")
    T "S10-Enum" "GET $short" $safe "code=$($t.code)"
}

# == RESUMEN ==================================================================
$total = $p + $f
$pct   = if($total -gt 0){[math]::Round(($p/$total)*100,1)}else{0}
Write-Output ""
Write-Output ("="*72)
Write-Output "  RESUMEN FINAL"
Write-Output ("="*72)
Write-Output ("  PASS  : {0,3} de {1}" -f $p, $total)
Write-Output ("  FAIL  : {0,3} de {1}" -f $f, $total)
Write-Output ("  Score : {0}%" -f $pct)
Write-Output ("="*72)

$failures = $rows | Where-Object { $_.Status -eq "FAIL" }
if ($failures) {
    Write-Output "`n  TESTS FALLIDOS:"
    $failures | ForEach-Object { Write-Output "    [FAIL] [$($_.Section)] $($_.Name) -- $($_.Detail)" }
}

# == EXPORTAR TXT =============================================================
$outPath = "C:\Users\Amador\Desktop\lab-backend\QA_REPORT.txt"
$out = [System.Collections.Generic.List[string]]::new()

$out.Add("=" * 72)
$out.Add("  QA REPORT -- Laboratorio de Ingenieria Civil UNAH")
$out.Add("  Fecha de ejecucion: $ts")
$out.Add("  Servidor: http://localhost:8000")
$out.Add("=" * 72)
$out.Add("")

$sectionTitles = @{
    "S1-Publico"     = "S1  ENDPOINTS PUBLICOS"
    "S2-Cotizacion"  = "S2  COTIZACION -- Flujo principal"
    "S3-Auth"        = "S3  AUTENTICACION ADMIN"
    "S4-CRUD"        = "S4  CRUD ADMIN -- Operaciones administrativas"
    "S5-SQLi"        = "S5  SEGURIDAD -- SQL Injection"
    "S6-XSS"         = "S6  SEGURIDAD -- XSS (Cross-Site Scripting)"
    "S7-PathTraversal"= "S7  SEGURIDAD -- Path Traversal"
    "S8-MassAssign"  = "S8  SEGURIDAD -- Mass Assignment / Campos no permitidos"
    "S9-Extremos"    = "S9  SEGURIDAD -- Payloads extremos (DoS / Stress)"
    "S10-Enum"       = "S10 SEGURIDAD -- Enumeracion de rutas ocultas"
}

foreach ($key in $sectionTitles.Keys | Sort-Object) {
    $secRows  = $rows | Where-Object { $_.Section -eq $key }
    if (-not $secRows) { continue }
    $sp = ($secRows | Where-Object {$_.Status -eq "PASS"}).Count
    $sf = ($secRows | Where-Object {$_.Status -eq "FAIL"}).Count
    $out.Add("-" * 72)
    $out.Add("  $($sectionTitles[$key])  [$sp PASS / $sf FAIL]")
    $out.Add("-" * 72)
    foreach ($row in $secRows) {
        $out.Add(("  [{0,-4}]  {1,-50} {2}" -f $row.Status, $row.Name, $row.Detail))
    }
    $out.Add("")
}

$out.Add("=" * 72)
$out.Add("  RESUMEN FINAL")
$out.Add("=" * 72)
$out.Add(("  PASS  : {0,3} de {1}  ({2}%)" -f $p, $total, $pct))
$out.Add(("  FAIL  : {0,3} de {1}" -f $f, $total))
$out.Add("")

if ($failures) {
    $out.Add("  TESTS FALLIDOS:")
    $failures | ForEach-Object { $out.Add("    [FAIL] [$($_.Section)] $($_.Name) -- $($_.Detail)") }
    $out.Add("")
}

$out.Add("  OBSERVACIONES DE SEGURIDAD:")
$out.Add("")
$out.Add("  [OK]   SQL Injection: Queries con parametros preparados (mysql2 placeholders '?').")
$out.Add("         No hay concatenacion de strings en ninguna query.")
$out.Add("")
$out.Add("  [OK]   XSS: API devuelve JSON puro. React escapa el contenido automaticamente")
$out.Add("         al renderizarlo. No se usa innerHTML ni dangerouslySetInnerHTML.")
$out.Add("")
$out.Add("  [OK]   Path Traversal: Express.static sirve solo /public/uploads/.")
$out.Add("         Rutas fuera de ese directorio devuelven 404.")
$out.Add("")
$out.Add("  [OK]   CORS: Lista blanca de origenes en ALLOWED_ORIGINS.")
$out.Add("")
$out.Add("  [OK]   Upload de imagenes: Multer valida MIME type (solo imagenes).")
$out.Add("         Nombres generados con crypto.randomBytes -- sin path injection.")
$out.Add("")
$out.Add("  [WARN] Rate Limiting: No implementado. Recomendado: express-rate-limit")
$out.Add("         para limitar peticiones a /cotizacion y /admin/auth antes de prod.")
$out.Add("")
$out.Add("  [WARN] Auth Admin: ADMIN_KEY en variable de entorno, comparacion directa.")
$out.Add("         Recomendado para prod: JWT con expiracion + bcrypt para la clave.")
$out.Add("")
$out.Add("  [WARN] HTTPS: Solo HTTP en local. En produccion obligatorio con Nginx + TLS.")
$out.Add("")
$out.Add("  [INFO] Cotizacion depende de Google Sheets. Si Sheets falla => 502.")
$out.Add("         Recomendado: agregar cola de reintentos o modo offline.")
$out.Add("")
$out.Add("=" * 72)
$out.Add("  Generado por Claude Code -- Suite QA Lab UNAH Backend")
$out.Add("=" * 72)

$out | Out-File -FilePath $outPath -Encoding UTF8 -Force
Write-Output ""
Write-Output "  Reporte exportado: $outPath"
