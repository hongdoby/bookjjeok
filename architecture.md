# bookjjeock

> **대상 독자**: Claude, Gemini 등 LLM이 아키텍처 컨텍스트를 이해하고 관련 질문에 답변하거나 코드를 생성할 수 있도록 작성된 문서입니다.

---

## 1. 개요 (Overview)

이 아키텍처는 **AWS ap-northeast-2(서울) 리전**에 구축된 **하이브리드 멀티 클러스터 Kubernetes 기반 서비스**입니다.

핵심 특징:
- **3개의 VPC**로 역할을 분리: 프로덕션 클라우드(VPC1), 온프레미스 시뮬레이션(VPC2), 공유 관리(VPC3)
- CloudFront를 통해 VPC1/VPC2로 **50:50 트래픽 분산** (하이브리드 멀티 클러스터 부하분산)
- **GitOps(ArgoCD) + CI/CD(GitHub Actions)** 파이프라인으로 컨테이너 배포 자동화
- **AWS Bedrock API**를 통한 AI 기능 통합
- **Terraform** 기반 IaC(Infrastructure as Code)
- **Chaos Mesh**를 통한 카오스 엔지니어링 테스트

---

## 2. 네트워크 구성 (Network Architecture)

### 2.1 VPC 구성 요약

| VPC   | CIDR 블록      | 역할                     | 특징                             |
|-------|---------------|--------------------------|----------------------------------|
| VPC1  | 10.0.0.0/16   | 프로덕션 클라우드 클러스터  | ALB, NAT Gateway, AWS 네이티브     |
| VPC2  | 10.1.0.0/16   | 온프레미스 시뮬레이션 클러스터 | MetalLB, NAT Instance, Site-to-Site VPN |
| VPC3  | 10.2.0.0/16   | 공유 관리 / 데이터 계층    | DB, 모니터링, CI/CD 도구          |

### 2.2 VPC 간 연결

```
VPC1 ──── VPC Peering ──────────► VPC3
VPC2 ──── Site-to-Site VPN ────► VPC3
VPC2 ──── VPC Peering ──────────► VPC3
```

- **VPC1 ↔ VPC3**: VPC Peering (프로덕션 클러스터 ↔ 관리 계층)
- **VPC2 ↔ VPC3**: Site-to-Site VPN (온프레미스 ↔ 클라우드 보안 터널) + VPC Peering (저지연 내부 통신)
- VPC1 ↔ VPC2 간 직접 연결 없음 → CloudFront 레벨에서 분산

---

## 3. VPC별 상세 구성

### 3.1 VPC1 — 프로덕션 클라우드 Kubernetes 클러스터 (10.0.0.0/16)

AWS 네이티브 서비스를 활용한 완전 관리형 프로덕션 클러스터입니다.

#### 서브넷 구성

| 서브넷 이름         | CIDR           | 가용 영역 | 주요 리소스              |
|---------------------|----------------|-----------|--------------------------|
| Public subnet       | 10.0.0.0/22    | AZ-a      | ALB, NAT Gateway, IGW    |
| Private-A           | 10.0.4.0/22    | AZ-a      | Worker node (BE Pod, AI Pod) |
| Private-A (AZ-b)    | 10.0.8.0/22    | AZ-b      | Worker node1 (BE Pod, AI Pod) |
| Private-B           | 10.0.12.0/22   | AZ-b      | Worker node2 (BE Pod, AI Pod) |

#### 핵심 컴포넌트

- **ALB (Application Load Balancer)**: L7 HTTP/HTTPS 트래픽 분산, CloudFront로부터 수신
- **NAT Gateway**: 프라이빗 서브넷의 아웃바운드 인터넷 접근 (관리형, 고가용성)
- **Worker node1/2**: 멀티 AZ 배치
  - BE Pod: 백엔드 서비스
  - AI Pod: AI 서비스
- **Bedrock API**: AI 기능 통합

---

### 3.2 VPC2 — 온프레미스 시뮬레이션 Kubernetes 클러스터 (10.1.0.0/16)

온프레미스 또는 사설 데이터센터 환경을 AWS 위에서 시뮬레이션하는 클러스터입니다.
NAT Gateway 대신 비용 효율적인 **NAT Instance**를 사용하고, AWS ALB 대신 **MetalLB**를 사용합니다.

#### 서브넷 구성

| 서브넷 이름         | CIDR           | 가용 영역 | 주요 리소스              |
|---------------------|----------------|-----------|--------------------------|
| Public subnet       | 10.1.0.0/22    | AZ-a      | MetalLB, NAT Instance, IGW |
| Private-A           | 10.1.4.0/22    | AZ-a      | Control Plane, Worker node1 (BE Pod, AI Pod) |
| Private-A (AZ-b)    | 10.1.8.0/22    | AZ-b      | Worker node1 (BE Pod, AI Pod) |
| Private-B           | 10.1.12.0/22   | AZ-b      | Worker node2 (BE Pod, AI Pod) |

#### 핵심 컴포넌트

- **MetalLB**: 베어메탈/온프레미스 K8s 환경에서 LoadBalancer 타입 서비스를 제공하는 로드밸런서
- **NAT Instance**: EC2 기반 NAT (NAT Gateway 대비 비용 절감, 온프레미스 환경 특성 반영)
- **Nginx**: Ingress 컨트롤러 역할, 내부 트래픽 라우팅
- **Control Plane**: Kubernetes 마스터 노드 (API Server, etcd, Scheduler, Controller Manager)
- **Worker node1/2**: 각 AZ에 분산 배치된 워커 노드
  - BE Pod: 백엔드 애플리케이션 컨테이너
  - AI Pod: AI 애플리케이션 컨테이너
- **Bedrock API**: AWS Bedrock AI 모델 호출을 위한 API 연동
- **Prometheus**: 클러스터 메트릭 수집 (VPC3의 중앙 Prometheus와 연동)

---

### 3.3 VPC3 — 공유 관리 / 데이터 VPC (10.2.0.0/16)

데이터베이스, 모니터링, CI/CD 도구, 보안 접근을 집중 관리하는 허브 VPC입니다.

#### 서브넷 구성

| 서브넷 이름         | CIDR           | 주요 리소스                          |
|---------------------|----------------|--------------------------------------|
| Public subnet       | 10.2.0.0/24    | Bastion Host, IGW, NAT Gateway       |
| Private subnet-A    | 10.2.4.0/24    | DB, Cache, 모니터링, CI/CD 도구 전체 |

#### 데이터 계층

| 서비스              | 설명                                                      |
|---------------------|-----------------------------------------------------------|
| **RDS PostgreSQL**  | 관계형 데이터베이스 (Primary), Multi-AZ 고가용성 구성     |
| **RDS Multi-AZ**    | 자동 장애조치(Failover)를 위한 스탠바이 복제본            |
| **RDS Proxy**       | DB 연결 풀링, Lambda/Pod의 커넥션 과부하 방지             |
| **ElastiCache Redis** | 세션 캐시, 인메모리 데이터 스토어                      |

#### 모니터링 스택 (Observability)

| 서비스                  | 역할                                             |
|-------------------------|--------------------------------------------------|
| **Prometheus**          | 메트릭 수집 중앙 서버 (VPC1/VPC2 Prometheus와 연동) |
| **Grafana**             | 메트릭 시각화 대시보드                            |
| **OpenSearch**          | 로그 저장 및 분석 엔진 (ElasticSearch 호환)       |
| **OpenSearch Dashboards** | 로그 시각화 및 검색 UI                         |

#### CI/CD 및 운영 도구

| 서비스           | 역할                                                      |
|------------------|-----------------------------------------------------------|
| **ArgoCD**       | GitOps 방식의 K8s 배포 자동화 (Git → Cluster 동기화)      |
| **Chaos Mesh**   | 카오스 엔지니어링 - 장애 주입 테스트 (Pod kill, 네트워크 지연 등) |

#### 접근 보안

- **Bastion Host**: 외부에서 프라이빗 서브넷 내 리소스에 SSH 접근 시 거점 서버로 사용

---

## 4. 글로벌 / 공통 서비스

AWS 리전 외부 또는 계정 레벨에서 동작하는 서비스들입니다.

| 서비스           | 역할                                                           |
|------------------|----------------------------------------------------------------|
| **Route 53**     | DNS 서비스. 사용자 도메인 요청을 CloudFront로 라우팅           |
| **CloudFront**   | CDN + 엣지 캐싱. VPC1(50%)과 VPC2(50%)로 트래픽 분산 (오리진 설정) |
| **WAF**          | CloudFront 앞단에서 SQL Injection, XSS 등 L7 공격 차단        |
| **ACM**          | SSL/TLS 인증서 관리 (CloudFront, ALB에 적용)                  |
| **S3**           | 정적 파일, 로그, 아티팩트, Terraform 상태 파일 저장            |
| **ECR**          | Docker 이미지 레지스트리 (GitHub Actions가 이미지 푸시)        |
| **IAM Role**     | Pod 및 서비스에 최소 권한 부여 (IRSA 패턴 등)                 |
| **EventBridge**  | 이벤트 기반 자동화 (스케줄, 서비스 이벤트 트리거)             |
| **Lambda**       | 서버리스 함수 (EventBridge와 연동, 경량 작업 처리)            |
| **Terraform**    | 전체 인프라 IaC 관리 도구 (AWS 리소스 선언적 프로비저닝)      |

---

## 5. 트래픽 흐름 (Traffic Flow)

### 5.1 사용자 요청 흐름 (Inbound)

```
사용자 (User)
    │
    ▼
Route 53  (DNS 해석)
    │
    ▼
CloudFront  (CDN, 엣지 캐싱)
    │
    ▼
WAF  (L7 웹 방화벽 - SQL Injection, XSS 차단)
    │
    ├──── 50% ────► VPC1 ALB ──► Worker Node (BE Pod → AI Pod)
    │
    └──── 50% ────► VPC2 MetalLB/Nginx ──► Worker Node (BE Pod → AI 포드)
```

- CloudFront 오리진을 VPC1, VPC2 두 개로 설정하여 **50:50 하이브리드 부하분산**
- WAF는 CloudFront 배포에 연결되어 엣지에서 공격 차단

### 5.2 CI/CD 배포 흐름

```
개발자 코드 Push (Git)
    │
    ▼
GitHub Actions
    │
    ├──► Docker Build & Push ──► ECR (이미지 저장)
    │
    └──► ArgoCD (GitOps Sync)
              │
              ├──► VPC1 K8s 클러스터 배포
              └──► VPC2 K8s 클러스터 배포
```

### 5.3 데이터베이스 접근 흐름

```
VPC1/VPC2 BE Pod
    │
    ▼  (VPC Peering / Site-to-Site VPN)
VPC3 RDS Proxy  ──► RDS PostgreSQL Primary (Multi-AZ)
    │
    └──────────────► ElastiCache Redis (캐시 조회)
```

### 5.4 모니터링 흐름

```
VPC1 메트릭 ──────┐
                  ├──► VPC3 중앙 Prometheus ──► Grafana (대시보드)
VPC2 Prometheus ──┘

애플리케이션 로그 ──► OpenSearch ──► OpenSearch Dashboards
```

---

## 6. 보안 설계

| 계층             | 보안 메커니즘                                              |
|------------------|------------------------------------------------------------|
| **엣지(Edge)**   | WAF (웹 방화벽), CloudFront (DDoS 완화), ACM (TLS 암호화) |
| **네트워크**     | VPC 격리, 프라이빗 서브넷, 보안 그룹, NACL                |
| **접근 제어**    | IAM Role (최소 권한), Bastion Host (SSH 게이트웨이)        |
| **데이터베이스** | RDS Proxy (연결 보안 강화), Multi-AZ (이중화)             |
| **컨테이너**     | ECR 이미지 스캔, IRSA (Pod별 IAM 권한)                   |

---

## 7. 고가용성 (HA) 설계

| 구성 요소        | HA 메커니즘                                                |
|------------------|------------------------------------------------------------|
| **애플리케이션** | 멀티 AZ Worker Node 배치, 클러스터 레벨 Pod 복제          |
| **트래픽**       | VPC1/VPC2 이중 클러스터 (50:50), CloudFront 멀티 오리진   |
| **데이터베이스** | RDS Multi-AZ (자동 Failover), ElastiCache 클러스터링      |
| **네트워크**     | Site-to-Site VPN + VPC Peering 이중 경로 (VPC2↔VPC3)      |

---

## 8. 주요 설계 결정 (Design Decisions)

1. **하이브리드 멀티 클러스터**: VPC1(클라우드 네이티브) + VPC2(온프레미스 스타일)를 50:50으로 운영하여 클라우드 마이그레이션 또는 하이브리드 전략을 실현.

2. **VPC3 공유 관리 VPC**: DB, 모니터링, CI/CD를 별도 VPC로 분리함으로써 보안 경계를 명확히 하고 운영 복잡도를 줄임.

3. **GitOps(ArgoCD)**: 애플리케이션 배포를 Git 저장소와 동기화하여 감사 가능성과 롤백 용이성 확보.

4. **Chaos Mesh**: 장애 상황을 사전에 주입 테스트하여 시스템 복원력을 검증.

5. **RDS Proxy**: Pod 수가 증가할 때 DB 연결 수 폭발을 방지하고 연결 풀을 효율적으로 관리.

6. **AWS Bedrock API**: 별도 AI 인프라 없이 AWS 관리형 FM(Foundation Model)을 VPC1/VPC2 양쪽에서 호출.

---

## 9. 기술 스택 요약

```
Infrastructure as Code : Terraform
Container Orchestration : Kubernetes (Self-managed)
Container Registry      : Amazon ECR
Service Mesh / Ingress  : Nginx (VPC2), ALB (VPC1), MetalLB (VPC2)
CI/CD                   : GitHub Actions + ArgoCD (GitOps)
Database                : Amazon RDS PostgreSQL (Multi-AZ) + RDS Proxy
Cache                   : Amazon ElastiCache (Redis)
Monitoring              : Prometheus + Grafana
Logging                 : Amazon OpenSearch + OpenSearch Dashboards
AI / ML                 : Amazon Bedrock API
Security                : AWS WAF + ACM + IAM + Bastion
CDN / DNS               : Amazon CloudFront + Route 53
Event-driven            : Amazon EventBridge + AWS Lambda
Chaos Engineering       : Chaos Mesh
```

---

*이 문서는 draw.io 아키텍처 다이어그램(`4조_아키텍처_수정본v2.drawio`)을 기반으로 AWS SAA 관점에서 분석·작성되었습니다.*
