$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http

function Assert-True([bool]$Condition,[string]$Message) {
  if(-not $Condition){ throw "ASSERTION_FAILED: $Message" }
}

$savedPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$statusLines = & npx.cmd --yes supabase@latest status -o env 2>$null
$statusExitCode = $LASTEXITCODE
$ErrorActionPreference = $savedPreference
Assert-True ($statusExitCode -eq 0) 'local Supabase status command failed'
$local = @{}
foreach($line in $statusLines){
  if($line -match '^([A-Z_]+)="?(.*?)"?$'){
    $local[$matches[1]] = $matches[2].TrimEnd('"')
  }
}

$apiUrl = $local.API_URL
$mailpitUrl = $local.MAILPIT_URL
$anonKey = $local.ANON_KEY
Assert-True ($apiUrl -match '^https?://127\.0\.0\.1:54321$') 'refusing to test a non-local Supabase API'
Assert-True ($mailpitUrl -match '^http://127\.0\.0\.1:54324$') 'refusing to test a non-local Mailpit API'
Assert-True (-not [string]::IsNullOrWhiteSpace($anonKey)) 'local anon key unavailable'
# Local API TLS is disabled in supabase/config.toml; CLI v3 may still render API_URL as https.
$apiUrl = 'http://127.0.0.1:54321'

$email = 'artist.rehearsal.' + [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() + '@example.test'
$password = 'Synthetic-Auth-Only-2026!'
$commonHeaders = @{ apikey = $anonKey; Authorization = "Bearer $anonKey" }
$signupBody = @{ email=$email; password=$password; data=@{display_name='HTTP Rehearsal Artist'} } | ConvertTo-Json -Depth 4
$signup = Invoke-RestMethod -Method Post -Uri "$apiUrl/auth/v1/signup" -Headers $commonHeaders -ContentType 'application/json' -Body $signupBody
Assert-True ($null -ne $signup.user -or $null -ne $signup.id) 'signup did not create a Supabase Auth user'
Assert-True ([string]::IsNullOrWhiteSpace([string]$signup.access_token)) 'unverified signup unexpectedly received a session'

$unverifiedRejected = $false
try {
  Invoke-RestMethod -Method Post -Uri "$apiUrl/auth/v1/token?grant_type=password" -Headers $commonHeaders -ContentType 'application/json' -Body (@{email=$email;password=$password}|ConvertTo-Json) | Out-Null
} catch {
  $unverifiedRejected = $true
}
Assert-True $unverifiedRejected 'unverified user obtained a password session'

$message = $null
for($attempt=0;$attempt -lt 20 -and $null -eq $message;$attempt++){
  Start-Sleep -Milliseconds 500
  $mail = Invoke-RestMethod -Method Get -Uri "$mailpitUrl/api/v1/messages"
  foreach($item in $mail.messages){
    $addresses = @($item.To | ForEach-Object { $_.Address })
    if($addresses -contains $email){ $message=$item; break }
  }
}
Assert-True ($null -ne $message) 'confirmation email was not captured by local Mailpit'
$fullMessage = Invoke-RestMethod -Method Get -Uri "$mailpitUrl/api/v1/message/$($message.ID)"
$content = [string]$fullMessage.HTML + "`n" + [string]$fullMessage.Text
$match = [regex]::Match($content,'https?://[^"''<>\s]+/auth/v1/verify[^"''<>\s]+')
Assert-True $match.Success 'confirmation action link was not found'
$verifyUrl = [Net.WebUtility]::HtmlDecode($match.Value)
Assert-True ($verifyUrl -match '^http://127\.0\.0\.1:54321/auth/v1/verify') 'confirmation link did not target local Auth'

$handler = [System.Net.Http.HttpClientHandler]::new()
$handler.AllowAutoRedirect = $false
$client = [System.Net.Http.HttpClient]::new($handler)
$verifyResponse = $client.GetAsync($verifyUrl).GetAwaiter().GetResult()
Assert-True ([int]$verifyResponse.StatusCode -in 200,302,303,307) 'local confirmation endpoint rejected the token'
$client.Dispose()
$handler.Dispose()

$token = Invoke-RestMethod -Method Post -Uri "$apiUrl/auth/v1/token?grant_type=password" -Headers $commonHeaders -ContentType 'application/json' -Body (@{email=$email;password=$password}|ConvertTo-Json)
Assert-True (-not [string]::IsNullOrWhiteSpace([string]$token.access_token)) 'verified user did not receive a session'
$authHeaders = @{ apikey=$anonKey; Authorization="Bearer $($token.access_token)" }
$registrationBody = @{p_display_name='HTTP Rehearsal Artist'} | ConvertTo-Json
$first = Invoke-RestMethod -Method Post -Uri "$apiUrl/rest/v1/rpc/register_current_user_as_artist" -Headers $authHeaders -ContentType 'application/json' -Body $registrationBody
$second = Invoke-RestMethod -Method Post -Uri "$apiUrl/rest/v1/rpc/register_current_user_as_artist" -Headers $authHeaders -ContentType 'application/json' -Body $registrationBody
Assert-True ([string]$first -eq [string]$second) 'repeated HTTP registration returned a different artist profile'
$roles = @(Invoke-RestMethod -Method Get -Uri "$apiUrl/rest/v1/user_roles?select=role" -Headers $authHeaders)
Assert-True ($roles.Count -eq 1 -and $roles[0].role -eq 'artist') 'HTTP registration assigned an unexpected role'
$onboarding = @(Invoke-RestMethod -Method Get -Uri "$apiUrl/rest/v1/artist_onboarding_requests?select=id,artist_id,status" -Headers $authHeaders)
Assert-True ($onboarding.Count -eq 1 -and $onboarding[0].status -eq 'draft') 'HTTP registration did not create one readable draft onboarding row'

[pscustomobject]@{
  test_suite='artist_auth_http_rehearsal'
  result='PASS'
  signup_unverified=$true
  email_confirmation=$true
  verified_session=$true
  registration_idempotent=$true
  artist_only_role=$true
  onboarding_created=$true
}
