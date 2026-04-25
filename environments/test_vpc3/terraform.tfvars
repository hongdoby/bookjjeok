# ==========================================
# ArgoCD 설정 변수
# ==========================================

# ArgoCD admin 계정 비밀번호 (사용자님이 설정하신 값을 입력해 주세요)
argocd_admin_password = "SDqj-Np0dUjBHjLX" 

# VPC1 EKS 정보 (자동 수집됨)
vpc1_cluster_endpoint = "https://F58B25CFD6A67BE831C4B188A94E66D9.gr7.ap-northeast-2.eks.amazonaws.com"
vpc1_cluster_ca_data  = "LS0tLS1CRUdJTiBDRVJU...[중략]..." # 테라폼이 실행 시 자동으로 참조합니다.

# ==========================================
# 기타 인프라 설정
# ==========================================

# DB 비밀번호 (사용자님이 설정하신 값을 입력해 주세요)
db_password = "Bookjjeok1234!"
