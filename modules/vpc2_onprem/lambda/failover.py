import json
import os
import urllib.request
import urllib.parse
import boto3

# ── 설정값 (Lambda 환경변수로 주입)
PROMETHEUS_URL    = os.environ.get('PROMETHEUS_URL', 'http://10.1.23.243:30090')
DISTRIBUTION_ID   = os.environ['CLOUDFRONT_DISTRIBUTION_ID']       # E21FET8W62SYTV
VPC1_ORIGIN_ID    = os.environ.get('VPC1_ORIGIN_ID', 'VPC1-Cloud-ALB-Origin')
ORIGIN_GROUP_ID   = os.environ.get('ORIGIN_GROUP_ID', 'bookjjeok-backend-origin-group')
REGION            = os.environ.get('AWS_DEFAULT_REGION', 'ap-northeast-2')

# 임계치
CPU_THRESHOLD        = float(os.environ.get('CPU_THRESHOLD', '0.80'))     # 80%
ERROR_RATE_THRESHOLD = float(os.environ.get('ERROR_RATE_THRESHOLD', '0.05'))  # 5%
LATENCY_THRESHOLD_MS = float(os.environ.get('LATENCY_THRESHOLD_MS', '2000'))  # 2초

# 페일백: 연속 N회 정상 확인 후 복구
RECOVERY_THRESHOLD = int(os.environ.get('RECOVERY_THRESHOLD', '5'))

BACKEND_PATHS = ['/api/*', '/login/*', '/oauth2/*']
SSM_STATE_KEY    = '/bookjjeok/routing/state'
SSM_RECOVERY_KEY = '/bookjjeok/routing/recovery-count'

cf_client  = boto3.client('cloudfront')
ssm_client = boto3.client('ssm', region_name=REGION)


# ── Prometheus 쿼리
def query_prometheus(query):
    url = f"{PROMETHEUS_URL}/api/v1/query?query={urllib.parse.quote(query)}"
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            data = json.loads(resp.read())
            if data['status'] == 'success' and data['data']['result']:
                return float(data['data']['result'][0]['value'][1])
    except Exception as e:
        print(f"Prometheus query failed ({query}): {e}")
    return None


def get_metrics():
    # CPU 사용률 (전체 노드 평균)
    cpu = query_prometheus(
        '1 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))'
    )
    # 에러율 (5xx / 전체)
    error_rate = query_prometheus(
        'sum(rate(envoy_http_downstream_rq_xx{envoy_response_code_class="5"}[5m])) '
        '/ sum(rate(envoy_http_downstream_rq_total[5m]))'
    )
    # P95 응답시간 (ms)
    latency = query_prometheus(
        'histogram_quantile(0.95, sum(rate(envoy_http_downstream_rq_time_bucket[5m])) by (le))'
    )
    return cpu, error_rate, latency


# ── SSM 상태 관리
def get_state():
    try:
        return ssm_client.get_parameter(Name=SSM_STATE_KEY)['Parameter']['Value']
    except Exception:
        return 'vpc2'


def set_state(state):
    ssm_client.put_parameter(Name=SSM_STATE_KEY, Value=state, Type='String', Overwrite=True)


def get_recovery_count():
    try:
        return int(ssm_client.get_parameter(Name=SSM_RECOVERY_KEY)['Parameter']['Value'])
    except Exception:
        return 0


def set_recovery_count(n):
    ssm_client.put_parameter(Name=SSM_RECOVERY_KEY, Value=str(n), Type='String', Overwrite=True)


# ── CloudFront behavior 교체
def update_behaviors(target_origin_id):
    resp   = cf_client.get_distribution_config(Id=DISTRIBUTION_ID)
    config = resp['DistributionConfig']
    etag   = resp['ETag']

    changed = False
    for behavior in config['CacheBehaviors']['Items']:
        if behavior['PathPattern'] in BACKEND_PATHS:
            if behavior['TargetOriginId'] != target_origin_id:
                behavior['TargetOriginId'] = target_origin_id
                changed = True

    if changed:
        cf_client.update_distribution(
            DistributionConfig=config,
            Id=DISTRIBUTION_ID,
            IfMatch=etag
        )
        print(f"CloudFront behaviors updated → {target_origin_id}")
    else:
        print(f"Already pointing to {target_origin_id}, no update needed")


# ── Lambda 핸들러
def lambda_handler(event, context):
    cpu, error_rate, latency = get_metrics()
    state = get_state()

    print(f"[Metrics] CPU={cpu}, ErrorRate={error_rate}, P95Latency={latency}ms | State={state}")

    # None 처리: 메트릭 못 가져오면 현 상태 유지
    if cpu is None and error_rate is None:
        print("Cannot reach Prometheus, keeping current state")
        return {'state': state, 'action': 'no_change'}

    is_degraded = (
        (cpu is not None and cpu > CPU_THRESHOLD) or
        (error_rate is not None and error_rate > ERROR_RATE_THRESHOLD) or
        (latency is not None and latency > LATENCY_THRESHOLD_MS)
    )

    action = 'no_change'

    if is_degraded and state == 'vpc2':
        print(f"Degraded → failover to VPC1")
        update_behaviors(VPC1_ORIGIN_ID)
        set_state('vpc1')
        set_recovery_count(0)
        action = 'failover'

    elif not is_degraded and state == 'vpc1':
        count = get_recovery_count() + 1
        set_recovery_count(count)
        print(f"Recovering ({count}/{RECOVERY_THRESHOLD})")

        if count >= RECOVERY_THRESHOLD:
            print(f"Stable for {RECOVERY_THRESHOLD} checks → failback to VPC2")
            update_behaviors(ORIGIN_GROUP_ID)
            set_state('vpc2')
            set_recovery_count(0)
            action = 'failback'

    return {
        'state':      get_state(),
        'action':     action,
        'cpu':        cpu,
        'error_rate': error_rate,
        'latency_ms': latency,
    }
