# chaos_annotate.ps1
# 카오스 실험 시작/종료 시점을 Grafana에 Annotation으로 기록
#
# 사용법:
#   .\chaos_annotate.ps1 start "scenario-01-phase1"
#   .\chaos_annotate.ps1 end "scenario-01-phase1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "end")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$Scenario
)

$GRAFANA_URL = "http://bookjjeok-cloud-vpc3-alb-570474290.ap-northeast-2.elb.amazonaws.com/grafana"
$GRAFANA_TOKEN = "YOUR_GRAFANA_TOKEN"

$timestamp = [long](Get-Date -UFormat %s) * 1000

if ($Action -eq "start") {
    $text = "CHAOS START: $Scenario"
    $tags = @("chaos", $Scenario, "start")
} else {
    $text = "CHAOS END: $Scenario"
    $tags = @("chaos", $Scenario, "end")
}

$body = @{
    text = $text
    tags = $tags
    time = $timestamp
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "$GRAFANA_URL/api/annotations" `
    -Method Post `
    -Headers @{ "Authorization" = "Bearer $GRAFANA_TOKEN"; "Content-Type" = "application/json" } `
    -Body $body

Write-Host "[$Action] $Scenario - Annotation ID: $($response.id)"
