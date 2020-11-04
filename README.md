# 목표

- Windows Server 로그 수집
- 중앙 서버에서 2주에 1번 일괄로 수집 (트래픽 감소 기대)

# 사용법

### 1. init.ps1 또는 init_pwsh7.ps1에서 Path 변경

```powershell
[String]$path = "<Your Home Dir>",
```

### 2. conf.xml에 AD 정보 입력

```xml
<ad>
  <domain>example.com</domain>
  <id>id</id>
  <pw>pw</pw>
</ad>
```

### 3. conf.xml에 수집할 대상 서버 리스트 입력

```xml
<servers>
  <server>server1</server>
  <server>server2</server>
  <server>server3</server>
</servers>
```