import json
import os
import urllib.request
import urllib.parse
import boto3

PROMETHEUS_URL  = os.environ.get('PROMETHEUS_URL', 'http://10.1.23.243:30090')
DISTRIBUTION_ID = os.environ['CLOUDFRONT_DISTRIBUTION_ID']
VPC1_ORIGIN_ID  = os.environ.get('VPC1_ORIGIN_ID', 'VPC1-Cloud-ALB-Origin')
ORIGIN_GROUP_ID = os.environ.get('ORIGIN_GROUP_ID', 'bookjjeok-backend-origin-group')
REGION          = os.environ.get('AWS_DEFAULT_REGION', 'ap-northeast-2')

BACKEND_PATHS   = ['/api/*', '/login/*', '/oauth2/*']
SSM_WEIGHTS_KEY = '/bookjjeok/routing/weights'

cf_client  = boto3.client('cloudfront')
ssm_client = boto3.client('ssm', region_name=REGION)


def query_prometheus(query):
    url = f"{PROMETHEUS_URL}/api/v1/query?query={urllib.parse.quote(query)}"
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            data = json.loads(resp.read())
            if data['status'] == 'success' and data['data']['result']:
                val = float(data['data']['result'][0]['value'][1])
                return None if val != val else val  # NaN 처리
    except Exception as e:
        print(f"Prometheus query failed: {e}")
    return None


def score_to_weights(score):
    if score >= 80:
        return {'vpc2': 100, 'vpc1': 0}
    elif score >= 60:
        return {'vpc2': 70, 'vpc1': 30}
    elif score >= 40:
        return {'vpc2': 30, 'vpc1': 70}
    else:
        return {'vpc2': 0, 'vpc1': 100}


def get_weights():
    try:
        val = ssm_client.get_parameter(Name=SSM_WEIGHTS_KEY)['Parameter']['Value']
        return json.loads(val)
    except Exception:
        return {'vpc2': 100, 'vpc1': 0}


def set_weights(weights):
    ssm_client.put_parameter(
        Name=SSM_WEIGHTS_KEY,
        Value=json.dumps(weights),
        Type='String',
        Overwrite=True
    )


def update_cf_origin(target_origin_id):
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
        print(f"CloudFront → {target_origin_id}")


def lambda_handler(event, context):
    score           = query_prometheus('job:bookjjeok_health_score')
    current_weights = get_weights()

    print(f"[Health] Score={score} | Weights={current_weights}")

    if score is None:
        print("Cannot reach Prometheus, keeping current weights")
        return {'score': None, 'weights': current_weights, 'action': 'no_change'}

    new_weights = score_to_weights(score)
    action      = 'no_change'

    if new_weights != current_weights:
        set_weights(new_weights)
        action = f"{current_weights} → {new_weights}"
        print(f"Weights updated: {action}")

        if new_weights['vpc2'] == 0:
            update_cf_origin(ORIGIN_GROUP_ID)
            print("Emergency: CloudFront → Origin Group")
        elif current_weights['vpc2'] == 0 and new_weights['vpc2'] > 0:
            update_cf_origin(VPC1_ORIGIN_ID)
            print("Recovery: CloudFront → VPC1 (Lambda@Edge will handle weighting)")

    return {
        'score':   score,
        'weights': new_weights,
        'action':  action,
    }
