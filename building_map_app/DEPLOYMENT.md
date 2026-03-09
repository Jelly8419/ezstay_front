 EZStay 자동 배포 가이드

## 개요

GitHub Actions를 사용한 완전 자동화된 EC2 배포 워크플로우입니다.

## 배포 아키텍처

```
GitHub Push → GitHub Actions Runner
    ↓
1. Runner IP 획득
2. AWS Security Group에 임시 SSH 허용 추가
3. Flutter 웹 빌드
4. EC2로 SCP 전송
5. Nginx 배포
6. Security Group에서 IP 제거
```

## GitHub Secrets 설정

**Repository → Settings → Secrets and variables → Actions → New repository secret**

### 필수 Secrets

| Secret 이름 | 설명 | 예시 |
|-------------|------|------|
| `AWS_ACCESS_KEY_ID` | AWS IAM Access Key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM Secret Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS 리전 | `us-east-1` |
| `EC2_SECURITY_GROUP_ID` | EC2 보안 그룹 ID | `sg-0123456789abcdef0` |
| `TEST_SERVER_HOST` | EC2 서버 호스트명 | `ec2-98-94-160-132.compute-1.amazonaws.com` |
| `TEST_SERVER_PORT` | SSH 포트 | `22` |
| `TEST_SERVER_USER` | SSH 사용자 | `ec2-user` |
| `TEST_SERVER_SSH_KEY` | SSH Private Key (PEM) | `-----BEGIN RSA PRIVATE KEY-----...` |

### SSH Key Secret 생성 방법

**Windows (PowerShell):**
```powershell
# PEM 파일 내용 복사
Get-Content C:\study\ezstay_test-key.pem | Set-Clipboard
# GitHub Secrets에 붙여넣기
```

**Linux/Mac:**
```bash
# PEM 파일 내용 복사
cat ~/your-key.pem | pbcopy  # macOS
cat ~/your-key.pem | xclip    # Linux
# GitHub Secrets에 붙여넣기
```

**중요:** PEM 파일 전체 내용을 복사해야 합니다 (BEGIN ~ END 포함).

## AWS IAM 권한 설정

배포에 필요한 최소 IAM 권한:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
```

### IAM 사용자 생성 단계

1. **AWS Console → IAM → Users → Add users**
2. User name: `github-actions-deployer`
3. Access type: **Programmatic access**
4. Permissions: **Attach existing policies directly** → Create custom policy (위 JSON 사용)
5. **Download .csv** (Access Key ID, Secret Access Key 저장)

## 배포 방법

### 1. 자동 배포 (권장)

**main 또는 develop 브랜치에 push하면 자동 배포:**

```bash
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin develop  # 자동으로 test 환경 배포
```

### 2. 수동 배포 (환경 선택)

**GitHub → Actions → Deploy Flutter Web to EC2 → Run workflow**

- **Branch**: 배포할 브랜치 선택
- **Environment**: `test` 또는 `production` 선택

### 3. 로컬 배포 (레거시)

```powershell
# Windows
.\deploy_to_ec2.ps1 test

# Linux/Mac
bash deploy_to_ec2.sh test
```

## 배포 환경 설정

### Test 환경
- **브랜치**: `develop`
- **API URL**: `https://ezstay-api.duckdns.org`
- **Base Href**: `/app/`

### Production 환경
- **브랜치**: `main`
- **API URL**: `https://api.ezstay.com`
- **Base Href**: `/app/`

## 배포 프로세스

### 전체 워크플로우 (약 5-8분)

1. **환경 설정** (30초)
   - 코드 체크아웃
   - Runner IP 획득
   - Security Group 규칙 추가

2. **Flutter 빌드** (3-5분)
   - Flutter SDK 설치 (캐시됨)
   - 의존성 설치
   - 테스트 실행
   - 웹 빌드 (--release)

3. **SSH 설정** (10초)
   - SSH 키 생성
   - known_hosts 추가

4. **EC2 배포** (1-2분)
   - 기존 파일 삭제
   - 빌드 파일 업로드 (SCP)
   - Nginx 배포
   - 권한 설정
   - Nginx 재시작

5. **정리 및 확인** (10초)
   - Security Group에서 IP 제거
   - 배포 확인

## 보안 고려사항

### 1. Security Group 동적 관리

**문제:** GitHub Actions Runner IP는 매번 변경됨
**해결:** 워크플로우가 자동으로 IP를 추가/제거

```yaml
# 배포 시작 시
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --cidr "RUNNER_IP/32"

# 배포 완료 후 (항상 실행)
aws ec2 revoke-security-group-ingress \
  --group-id sg-xxx \
  --cidr "RUNNER_IP/32"
```

### 2. SSH Key 보안

- ✅ GitHub Secrets에 암호화 저장
- ✅ 배포 후 임시 파일 자동 삭제
- ✅ 600 권한으로 파일 생성

### 3. API 키 관리

**중요:** `.env` 파일을 절대 커밋하지 마세요!

```bash
# .gitignore에 추가됨
.env
.env.test
.env.production
```

환경 변수는 `--dart-define`으로 빌드 시 주입:

```bash
flutter build web --release \
  --dart-define=ENVIRONMENT=test \
  --dart-define=API_BASE_URL=https://ezstay-api.duckdns.org
```

## 트러블슈팅

### 1. Security Group 규칙 추가 실패

**에러:**
```
An error occurred (InvalidPermission.Duplicate) when calling the AuthorizeSecurityGroupIngress operation
```

**원인:** 동일한 IP 규칙이 이미 존재
**해결:** 워크플로우가 자동으로 처리 (`|| echo "Rule may already exist"`)

### 2. SSH 연결 실패

**에러:**
```
Permission denied (publickey)
```

**확인 사항:**
- `TEST_SERVER_SSH_KEY`에 PEM 파일 전체 내용이 있는지 확인
- PEM 키가 EC2 인스턴스와 일치하는지 확인
- `TEST_SERVER_USER`가 올바른지 확인 (`ec2-user`, `ubuntu` 등)

**디버깅:**
```yaml
# 워크플로우에 임시 추가
- name: Debug SSH
  run: |
    ssh -vvv -i ~/.ssh/deploy_key.pem \
      -p ${{ secrets.TEST_SERVER_PORT }} \
      ${{ secrets.TEST_SERVER_USER }}@${{ secrets.TEST_SERVER_HOST }} \
      "echo 'Connected successfully'"
```

### 3. SCP 전송 실패

**에러:**
```
lost connection
```

**원인:** Security Group에 IP가 추가되지 않음
**해결:**
1. AWS Console → EC2 → Security Groups에서 수동 확인
2. Runner IP가 올바른지 확인: `${{ steps.runner-ip.outputs.ipv4 }}`

### 4. Nginx 재시작 실패

**에러:**
```
nginx: [emerg] bind() to 0.0.0.0:80 failed
```

**원인:** 포트가 이미 사용 중
**해결:**
```bash
# EC2에서 확인
sudo systemctl status nginx
sudo lsof -i :80

# Nginx 강제 재시작
sudo systemctl restart nginx
```

### 5. 빌드 시간 초과

**에러:**
```
The job running on runner has exceeded the maximum execution time of 30 minutes
```

**해결:**
```yaml
# timeout 증가
jobs:
  deploy:
    timeout-minutes: 45  # 기본 30분 → 45분
```

## 배포 확인

### 1. GitHub Actions 로그 확인

**GitHub → Actions → 최근 워크플로우 클릭**

각 단계별 로그 확인:
- ✅ 빌드 성공 여부
- 📤 업로드 파일 크기
- 🚀 Nginx 재시작 성공 여부

### 2. 브라우저 테스트

```
http://98.94.160.132/app/
```

**확인 사항:**
- 페이지 로딩 속도
- 콘솔 에러 없음
- API 통신 정상 작동

### 3. 서버 로그 확인

```bash
# EC2 SSH 접속
ssh -i your-key.pem ec2-user@your-server

# Nginx 액세스 로그
sudo tail -f /var/log/nginx/access.log

# Nginx 에러 로그
sudo tail -f /var/log/nginx/error.log

# 배포된 파일 확인
ls -lh /var/www/flutter/
du -sh /var/www/flutter/
```

## 롤백 방법

### 1. 이전 커밋으로 롤백

```bash
# 로컬에서 이전 커밋으로 되돌리기
git revert HEAD
git push origin develop

# 또는 특정 커밋으로
git revert abc1234
git push origin develop
```

### 2. 수동 롤백 (EC2)

```bash
# EC2에서 백업 확인
ls -lht /opt/ezstay/backups/flutter/

# 백업 복원
cd /var/www/flutter
sudo rm -rf *
sudo tar -xzf /opt/ezstay/backups/flutter/flutter_backup_20250115_143022.tar.gz
sudo systemctl reload nginx
```

## 성능 최적화

### 1. Flutter 빌드 최적화

```yaml
# 캐시 활성화
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    cache: true  # 의존성 캐시
```

**효과:** 빌드 시간 5분 → 3분 단축

### 2. 병렬 업로드

현재는 SCP 사용 중이지만, 대용량 파일의 경우 S3 경유 고려:

```yaml
# S3 업로드 (빠름)
- name: Upload to S3
  run: aws s3 sync build/web s3://my-bucket/

# EC2에서 S3 다운로드
- name: Deploy from S3
  run: |
    ssh ... "aws s3 sync s3://my-bucket/ /var/www/flutter/"
```

### 3. CDN 캐싱

CloudFront 사용 시 빌드 파일을 CDN으로 서빙:

```yaml
- name: Invalidate CloudFront
  run: |
    aws cloudfront create-invalidation \
      --distribution-id E1234567890ABC \
      --paths "/*"
```

## CI/CD 개선 로드맵

### Phase 1: 현재 상태 ✅
- [x] GitHub Actions 자동 배포
- [x] Security Group 동적 관리
- [x] 환경별 빌드 (test/production)

### Phase 2: 안정화 (다음 단계)
- [ ] 자동 테스트 강화
- [ ] Slack/Discord 배포 알림
- [ ] 배포 승인 프로세스 (production)

### Phase 3: 고도화
- [ ] Blue-Green 배포
- [ ] 카나리 배포
- [ ] 자동 롤백 (헬스체크 실패 시)

## 참고 자료

- [GitHub Actions 공식 문서](https://docs.github.com/en/actions)
- [Flutter 빌드 최적화](https://docs.flutter.dev/perf/web-performance)
- [AWS EC2 Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)
- [Nginx 최적화](https://nginx.org/en/docs/)

## 지원

문제 발생 시:
1. GitHub Actions 로그 확인
2. EC2 Nginx 로그 확인
3. Security Group 규칙 수동 확인
4. 이슈 등록: [GitHub Issues](https://github.com/your-repo/issues)
