# 🚀 GitHub Actions 자동 배포 빠른 시작 가이드

## 전제 조건

- ✅ GitHub 계정
- ✅ AWS 계정
- ✅ EC2 인스턴스 (t2.small 이상)
- ✅ EC2 SSH 키 파일 (.pem)

---

## 📋 5분 설정 체크리스트

### 1️⃣ AWS IAM 사용자 생성 (2분)

**AWS Console → IAM → Users → Add users**

1. User name: `github-actions-deployer`
2. Access type: ✅ **Programmatic access**
3. Permissions: **Attach existing policies directly** → Create policy

**IAM Policy (복사해서 붙여넣기):**
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

4. **Download .csv** → Access Key ID, Secret Access Key 저장

---

### 2️⃣ EC2 Security Group ID 확인 (1분)

**AWS Console → EC2 → Security Groups**

1. 사용 중인 EC2 인스턴스의 Security Group 클릭
2. **Security group ID** 복사 (예: `sg-0123456789abcdef0`)

---

### 3️⃣ GitHub Secrets 등록 (2분)

**GitHub Repository → Settings → Secrets and variables → Actions → New repository secret**

8개의 Secret을 차례로 추가:

| Secret 이름 | 값 예시 | 설명 |
|-------------|---------|------|
| `AWS_ACCESS_KEY_ID` | `AKIAIOSFODNN7EXAMPLE` | IAM Access Key |
| `AWS_SECRET_ACCESS_KEY` | `wJalrXUtnFEMI/K7MDENG/...` | IAM Secret Key |
| `AWS_REGION` | `us-east-1` | EC2 리전 |
| `EC2_SECURITY_GROUP_ID` | `sg-0123456789abcdef0` | Security Group ID |
| `TEST_SERVER_HOST` | `ec2-98-94-160-132.compute-1.amazonaws.com` | EC2 Public DNS |
| `TEST_SERVER_PORT` | `22` | SSH 포트 |
| `TEST_SERVER_USER` | `ec2-user` | SSH 사용자명 |
| `TEST_SERVER_SSH_KEY` | `-----BEGIN RSA PRIVATE KEY-----...` | PEM 파일 전체 내용 |

**SSH Key 복사 방법 (Windows):**
```powershell
Get-Content C:\study\ezstay_test-key.pem | Set-Clipboard
# GitHub Secrets에 붙여넣기
```

**SSH Key 복사 방법 (Linux/Mac):**
```bash
cat ~/your-key.pem
# 출력 전체를 복사하여 GitHub Secrets에 붙여넣기
```

---

## 🎯 배포 테스트

### 1. 자동 배포 테스트

```bash
# 파일 수정
echo "# Test" >> README.md

# 커밋 & 푸시
git add .
git commit -m "test: GitHub Actions 배포 테스트"
git push origin develop
```

### 2. 배포 확인

**GitHub → Actions 탭**

- 워크플로우가 자동 실행되는지 확인
- 각 단계가 성공하는지 모니터링 (약 5-8분)

**예상 단계:**
1. ✅ Checkout code
2. ✅ Get GitHub Actions Runner IP
3. ✅ Add Runner IP to AWS Security Group
4. ✅ Setup Flutter
5. ✅ Install dependencies
6. ✅ Run tests
7. ✅ Build Flutter web
8. ✅ Setup SSH key
9. ✅ Clean old files on server
10. ✅ Upload build to EC2
11. ✅ Deploy to Nginx
12. ✅ Verify deployment
13. ✅ Remove Runner IP from Security Group
14. ✅ Deployment summary

### 3. 웹사이트 확인

```
http://your-ec2-ip/app/
```

브라우저에서 정상 작동 확인!

---

## ❓ 문제 해결 (빠른 체크리스트)

### 배포 실패 시 확인 사항

**1. Security Group 규칙 추가 실패**
- ✅ IAM 정책이 올바른지 확인
- ✅ `EC2_SECURITY_GROUP_ID`가 정확한지 확인

**2. SSH 연결 실패**
```
Permission denied (publickey)
```
- ✅ `TEST_SERVER_SSH_KEY`에 PEM 파일 **전체 내용** 포함되었는지 확인
- ✅ `TEST_SERVER_USER`가 올바른지 확인 (`ec2-user` 또는 `ubuntu`)
- ✅ EC2 인스턴스에서 SSH 포트(22)가 열려있는지 확인

**3. Nginx 재시작 실패**
```bash
# EC2에 직접 접속하여 확인
ssh -i your-key.pem ec2-user@your-server

# Nginx 상태 확인
sudo systemctl status nginx

# Nginx 재시작
sudo systemctl restart nginx
```

**4. 빌드 실패**
- ✅ Flutter 버전 확인 (`3.9.2` 필요)
- ✅ `pubspec.yaml`에 문법 오류 없는지 확인

---

## 📊 배포 모니터링

### GitHub Actions 로그

**성공 예시:**
```
✅ Runner IP: 20.12.34.56
✅ Security Group: sg-xxx
✅ Build completed
✅ Upload completed
✅ Nginx reloaded successfully
✅ Deployment completed
```

### EC2 서버 로그

```bash
# SSH 접속
ssh -i your-key.pem ec2-user@your-server

# Nginx 액세스 로그
sudo tail -f /var/log/nginx/access.log

# Nginx 에러 로그
sudo tail -f /var/log/nginx/error.log

# 배포 파일 확인
ls -lh /var/www/flutter/
```

---

## 🎉 성공!

이제 `git push`만 하면 자동으로 배포됩니다!

```bash
# 개발 → 커밋 → 푸시
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin develop

# 5-8분 후 자동 배포 완료!
```

---

## 📚 더 알아보기

- [전체 배포 가이드](building_map_app/DEPLOYMENT.md)
- [프로젝트 개발 가이드](CLAUDE.md)
- [GitHub Actions 공식 문서](https://docs.github.com/en/actions)

---

## 🆘 도움말

문제가 계속되면:
1. GitHub Actions 로그 전체 복사
2. EC2 Nginx 에러 로그 확인
3. GitHub Issues에 질문 등록

**Happy Deploying! 🚀**
