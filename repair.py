import re

with open(r'c:\bookjjeok\README.md', 'r', encoding='utf-8') as f:
    text = f.read()

new_members = '''## 👥 팀원 소개 (Team Members)
본 프로젝트는 **총 6명의 팀원**으로 구성되어 있습니다.

| 이름 | 역할 및 담당 업무 | 비고 |
|------|-------------------|------|
| **홍경락** | VPC1 EKS 인프라 구축 및 VPC3 로깅 파이프라인 연동 | |
| **이원우** | VPC3 카오스 에이전트(Chaos Mesh) 설계 및 장애 테스트 구현 | |
| **임유나** | VPC2 온프레미스 기반 Kubernetes(K8s) 클러스터 구축 | |
| **안시완** | 프로덕션 프론트엔드 및 백엔드 애플리케이션 개발 담당 | |
| **김도영** | 데이터 계층(ElastiCache Redis, RDS PostgreSQL) 인프라 구축 | |
| **최유진** | VPC3 중앙 모니터링(Prometheus/Grafana) 및 테스트 시나리오 설계 | |

## 📐 인프라 아키텍처 (Architecture)'''

text = re.sub(r'## 👥 팀원 소개 \(Team Members\).*?## 📐 인프라 아키텍처 \(Architecture\)', new_members, text, flags=re.DOTALL)

with open(r'c:\bookjjeok\README.md', 'w', encoding='utf-8') as f:
    f.write(text)
