import json
import boto3

SSM_STATE_KEY = '/bookjjeok/routing/state'
VPC1_ALB      = 'bookjjeok-cloud-vpc3-alb-570474290.ap-northeast-2.elb.amazonaws.com'

ssm = boto3.client('ssm', region_name='ap-northeast-2')

# 30초 캐시 (Lambda@Edge 컨테이너 재사용 시 SSM 호출 절감)
_cache = {'state': None, 'expiry': 0}


def get_routing_state():
    import time
    now = time.time()
    if _cache['state'] and now < _cache['expiry']:
        return _cache['state']
    try:
        val = ssm.get_parameter(Name=SSM_STATE_KEY)['Parameter']['Value']
    except Exception as e:
        print(f"SSM read failed: {e}")
        val = 'vpc2'
    _cache['state'] = val
    _cache['expiry'] = now + 30
    return val


def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    state   = get_routing_state()

    if state == 'vpc1':
        request['origin'] = {
            'custom': {
                'domainName':        VPC1_ALB,
                'port':              80,
                'protocol':          'http',
                'readTimeout':       30,
                'keepaliveTimeout':  5,
                'customHeaders':     {},
                'sslProtocols':      ['TLSv1.2'],
                'path':              '',
            }
        }
        request['headers']['host'] = [{'key': 'Host', 'value': 'bookjjeok.cloud'}]
        print(f"Routed to VPC1 ALB")
    else:
        print(f"Routed to VPC2 (default origin)")

    return request
