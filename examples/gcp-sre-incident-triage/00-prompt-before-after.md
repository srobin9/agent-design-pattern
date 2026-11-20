# 실전 비교: 토큰 폭발 프롬프트 vs 아키텍트 5줄 프롬프트

GCP Cloud Run 서비스의 장애 알람이 울렸을 때 초기 원인을 분석해주는 **SRE Incident Triage 에이전트**를 만든다고 가정해 보겠습니다.

---

## ❌ Before: Slop과 토큰 낭비를 부르는 프롬프트

```text
GCP Cloud Run에서 장애가 났을 때 Cloud Logging이랑 Cloud Monitoring 메트릭, 그리고 최근 배포 이력을 조회해서 왜 장애가 났는지 분석하고 해결책까지 제시해주는 멀티에이전트를 ADK로 만들어줘. 보안도 신경 써주고 테스트 코드도 작성해줘.
```

### 왜 실패하는가?
1. **경계 부재**: "해결책까지 제시"라는 말 때문에 AI가 멋대로 `gcloud run services update-traffic`(롤백 실행 도구) 같은 위험한 Write 도구까지 구현합니다.
2. **빅뱅 구현**: 처음부터 Cloud Logging, Cloud Monitoring, Cloud Run Admin API 실제 클라이언트 3개를 한꺼번에 짜다가 GCP 권한·필터 문법 에러에 걸려 수만 토큰 디버깅 루프에 빠집니다.
3. **과잉 아키텍처**: 에이전트 5~6개짜리 거대한 구조를 한 번에 생성해 코드를 파악할 수 없게 됩니다.

---

## ✅ After: 아키텍트·SRE 경험을 살린 5줄 시작 프롬프트

최신 ADK 클래스 이름은 단 하나도 몰라도 됩니다. **경계, 입출력, 안전 제약**만 적어주세요.

```text
lean-agent-architect 스킬로 새 ADK 에이전트 프로젝트를 초기화하고 Gate 1 계약서를 작성해줘.
- 목적: Cloud Run 서비스 에러율 급증 시 최근 에러 로그, 지연시간/인스턴스 메트릭, 최근 리비전 배포 이력을 비교해 초기 원인 가설 Top 2를 도출한다.
- 제외 범위(Non-Goal): 롤백·재배포·트래픽 조정 등 인프라 상태를 변경(Write)하는 동작은 절대 하지 않는다. 웹 UI나 슬랙 봇 연동도 이번 범위에서 제외한다.
- 입출력: 입력은 (project_id, service_name, region, lookback_minutes=30). 출력은 (장애 요약, 유력 원인 가설 2개와 근거 데이터, SRE가 즉시 실행해볼 읽기 전용 gcloud 확인 명령어).
- 안전 제약: 모든 도구는 Read-Only만 허용하며, lookback_minutes가 180분을 넘으면 쿼리 비용 방지를 위해 콜백에서 차단한다.
```

---

## 진행 흐름 요약 (총 3번의 짧은 확인으로 완성)

1. **Gate 1 (계약서 승인 — 약 2분)**  
   AI가 위 5줄을 읽고 옆에 있는 완성 예시 파일인 [.agents-cli-spec.md](.agents-cli-spec.md)처럼 **Scatter-Gather(`ParallelAgent` + `SequentialAgent`) 패턴**과 **3개의 Thin Slice**를 제안합니다. 아키텍트는 계약서만 읽고 `"승인해, Slice 1 진행해"`라고 답합니다.
2. **Slice 1 완료 (Mock 개통 — 약 3분)**  
   GCP 연결 없이 가짜 장애 데이터(DB 커넥션 풀 고갈 시나리오)를 반환하는 스텁 도구와 `lookback_minutes > 180` 차단 콜백을 만들고 테스트를 통과시킵니다. 결과가 기록된 [STATE.md](STATE.md)를 확인한 뒤 `/compact`를 실행합니다.
3. **Slice 2 ~ 3 완료 (실제 GCP 읽기 API 연결 → Eval 2건 통과)**  
   배선이 이미 완벽히 검증되었으므로 실제 `google-cloud-logging` / `monitoring` 조회 코드만 깔끔하게 채워 넣어 디버깅 루프 없이 마무리됩니다.
