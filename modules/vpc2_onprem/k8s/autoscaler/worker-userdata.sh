#!/bin/bash
set -e

# K8s 기존 상태 초기화 (AMI에서 남은 상태 제거)
kubeadm reset -f 2>/dev/null || true
rm -rf /etc/kubernetes/manifests/ /etc/kubernetes/pki/ 2>/dev/null || true
systemctl stop kubelet 2>/dev/null || true

# SSM에서 join 커맨드 가져오기 (최대 10회 재시도)
for i in $(seq 1 10); do
  JOIN_CMD=$(aws ssm get-parameter \
    --name "/bookjjeok/k8s/join-command" \
    --with-decryption \
    --region ap-northeast-2 \
    --query 'Parameter.Value' \
    --output text 2>/dev/null)
  if [ -n "$JOIN_CMD" ]; then
    echo "Join command retrieved from SSM"
    break
  fi
  echo "Waiting for SSM parameter... attempt $i"
  sleep 10
done

# kubelet 재시작 및 클러스터 합류
systemctl start kubelet
eval $JOIN_CMD
