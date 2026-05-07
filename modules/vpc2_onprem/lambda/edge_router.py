import json
import random
import time
import boto3

SSM_WEIGHTS_KEY = '/bookjjeok/routing/weights'
VPC1_ALB        = 'bookjjeok-cloud-vpc3-alb-570474290.ap-northeast-2.elb.amazonaws.com'

ssm    = boto3.client('ssm', region_name='ap-northeast-2')
_cache = {'weights': None, 'expiry': 0}


def get_weights():
    now = time.time()
    if _cache['weights'] and now < _cache['expiry']:
        return _cache['weights']
    try:
        val     = ssm.get_parameter(Name=SSM_WEIGHTS_KEY)['Parameter']['Value']
        weights = json.loads(val)
    except Exception as e:
        print(f"SSM read failed: {e}")
        weights = {'vpc2': 100, 'vpc1': 0}
    _cache['weights'] = weights
    _cache['expiry']  = now + 30
    return weights


def lambda_handler(event, context):
    request    = event['Records'][0]['cf']['request']
    weights    = get_weights()
    vpc1_weight = weights.get('vpc1', 0)

    if vpc1_weight > 0 and random.randint(1, 100) <= vpc1_weight:
        request['origin'] = {
            'custom': {
                'domainName':       VPC1_ALB,
                'port':             80,
                'protocol':         'http',
                'readTimeout':      30,
                'keepaliveTimeout': 5,
                'customHeaders':    {},
                'sslProtocols':     ['TLSv1.2'],
                'path':             '',
            }
        }
        request['headers']['host'] = [{'key': 'Host', 'value': 'bookjjeok.cloud'}]
        print(f"Routed to VPC1 ALB (vpc1={vpc1_weight}%)")
    else:
        print(f"Routed to VPC2 (vpc2={100 - vpc1_weight}%)")

    return request
