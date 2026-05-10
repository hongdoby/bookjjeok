#!/bin/bash
GRAFANA_URL="http://bookjjeok-cloud-vpc3-alb-570474290.ap-northeast-2.elb.amazonaws.com/grafana"
GRAFANA_TOKEN="YOUR_GRAFANA_TOKEN"
ACTION=$1
TAG=$2
if [ "$ACTION" = "start" ]; then
  TEXT="[START] $TAG"
  TAGS='["chaos","start","'"$TAG"'"]'
elif [ "$ACTION" = "end" ]; then
  TEXT="[END] $TAG"
  TAGS='["chaos","end","'"$TAG"'"]'
else
  echo "Usage: ./chaos_annotate.sh start|end <tag>"
  exit 1
fi
NOW=$(date +%s%3N)
curl -s -X POST "$GRAFANA_URL/api/annotations" \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$TEXT\", \"tags\": $TAGS, \"time\": $NOW}"
echo ""
echo "Annotation '$TEXT' sent at $(date)"
