# 북적북적(Bookjjeok) AWS 인프라 구축 프로젝트

이 레포지토리는 **AWS SAA 관점에서 설계된 본 프로젝트의 하이브리드 멀티 클러스터 아키텍처**를 위한 Terraform(IaC) 코드를 관리합니다.

## 👥 팀원 소개 (Team Members)
본 프로젝트는 **총 5명의 팀원**으로 구성되어 있습니다.

| 이름 | 역할 및 담당 업무 | 비고 |
|------|-------------------|------|
| 팀원 1 | 인프라 설계 및 테라폼 모듈 구축 | |
| 팀원 2 | 인프라 설계 및 테라폼 모듈 구축 | |
| 팀원 3 | 인프라 설계 및 테라폼 모듈 구축 | |
| 팀원 4 | 인프라 설계 및 테라폼 모듈 구축 | |
| 팀원 5 | 인프라 설계 및 테라폼 모듈 구축 | |
*(※ 실제 팀원 명단과 각 상세 역할에 맞게 변경하여 사용해주세요.)*

## 📐 인프라 아키텍처 (Architecture)
본 인프라는 환경에 따라 **3개의 VPC(Cloud, On-premise, Shared Hub)**로 세분화하여 구성합니다.
클러스터 별 상세 컴포넌트와 네트워크 흐름 등 전체 인프라 구성도는 [architecture.md](./architecture.md) 파일에서 확인하실 수 있습니다.

## 🎯 리소스 명명 규칙 (Naming Convention)
AWS 리소스를 생성하고 관리할 때 일관성을 유지하기 위해 모든 리소스 트랙에 공통된 프리픽스(Prefix)를 적용합니다.

> **공통 프리픽스 파맷**: `bookjjeok-cloud-<리소스명>`

### 명명 예시 (Examples)
- **네트워크 (VPC, Subnet)**:
  - `bookjjeok-cloud-vpc`
  - `bookjjeok-cloud-vpc1-cloud`
- **데이터베이스 (PostgreSQL 등 긴 이름은 약어 활용)**:
  - `bookjjeok-cloud-pg-primary`
  - `bookjjeok-cloud-redis-cluster`
- **컨테이너 오케스트레이션 (EKS 등)**:
  - `bookjjeok-cloud-eks-cluster`
  - `bookjjeok-cloud-eks-nodegroup`

## 📁 폴더 & 모듈 구조 (Directory Structure)
- `environments/prod/`: 프로덕션 클러스터를 프로비저닝하는 Root Terraform 코드 공간
- `modules/`: 기능 단위별로 추상화한 재사용 가능한 모듈
  - `/vpc1_cloud/`: ☁️ 프로덕션 클라우드 환경 리소스
  - `/vpc2_onprem/`: 🏢 온프레미스 시뮬레이션 환경 리소스
  - `/vpc3_shared/`: 🛠 DB 및 모니터링/CICD 공유 환경 리소스
  - `/networking/`: VPC Peering 및 Site-to-Site VPN 등 모듈 간 네트워크
  - `/global/`: Route53, WAF, CloudFront 멀티 오리진 등

## 🚀 테라폼 실행 방법 (Usage)
```bash
# 프로덕션 환경 디렉터리로 이동
cd environments/prod

# 테라폼 플러그인 초기화
terraform init

# 변경 사항 확인
terraform plan

# 인프라 배포
terraform apply
```
