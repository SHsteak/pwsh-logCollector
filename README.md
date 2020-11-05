# 목표

- Windows Server 로그 수집
- 중앙 서버에서 2주에 1번 일괄로 수집 (트래픽 감소 기대)

# 사용법

### 1. 환경 변수 등록

- 기본

    ```powershell
    [System.Environment]::SetEnvironmentVariable("LC_HOME", "<your log_collercot home>", "Machine")
    ```

- 예제

    ```powershell
    # 환경변수 등록
    [System.Environment]::SetEnvironmentVariable("LC_HOME", "D:\example", "Machine")

    # 확인
    $env:LC_HOME

    D:\example
    ```

### 2. conf.xml에 AD 정보 입력

```xml
<ad>
  <domain>example.com</domain>
  <id>id</id>
  <pw>password</pw>
</ad>
```

### 3. conf.xml에 수집할 대상 서버 리스트 입력

```xml
<servers>
  <!-- AD 조인 O -->
  <server>
    <hostname>server1</hostname>
  </server>
  <!-- AD 조인 X -->
  <server>
    <hostname>server2</hostname>
    <ipAddress>51.2.x.x</ipAddress>
    <id>id</id>
    <pw>password</pw>
  </server>
</servers>
```