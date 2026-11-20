# Project Execution State (`STATE.md`) — Slice 1 완료 시점 예시

> 이 파일은 슬라이스 종료 후 `/compact` 또는 새 대화창에서 `"@STATE.md 읽고 Slice 2 진행해줘"` 한 줄로 작업을 이어받기 위한 실제 상태 기록 예시입니다.

## 현재 진행 단계 (Current Status)
- **현재 활성 단계**: `Slice 2 대기 (Slice 1 검증 완료)`
- **승인된 스펙 파일**: `.agents-cli-spec.md` (Gate 1 승인 완료)
- **배포 타깃**: 로컬 프로토타입 검증 중 (Slice 3 이후 Cloud Run 예정)

## 슬라이스 체크포인트
- [x] **Gate 1**: 1-Page 아키텍처 계약서(`.agents-cli-spec.md`) 확정 및 승인
- [x] **Slice 1**: 스캐폴딩 + Mock 도구 계약(`pytest` 6/6 통과) + 로컬 스모크(`agents-cli run`) 통과
- [ ] **Slice 2**: 실제 GCP Logging / Monitoring / Cloud Run Admin 읽기 클라이언트 연동 및 부분 실패(403/Timeout) 처리
- [ ] **Slice 3**: `agents-cli eval run` 핵심 시나리오 2건 통과 및 Cloud Run 배포 준비

## 확정된 핵심 아키텍처 결정 (ADR 요약)
1. **토폴로지**: `SequentialAgent(root_agent)` = `ParallelAgent(log, metric, revision 수집기)` → `Agent(triage_synthesizer)`
2. **App 이름 고정**: 평가 호환성을 위해 `app/agent.py` 내 `App(name="app", ...)` 유지
3. **가드레일 분리**: `app/callbacks.py`의 `enforce_sre_read_guardrails`에서 `lookback_minutes > 180` 및 특수문자 입력 시 도구 미실행 차단 확인 완료
4. **Mock 스위치**: 환경변수 `USE_MOCK_TOOLS=true`(기본값)일 때 결정론적 샘플 데이터 반환, `false`일 때 실제 GCP SDK 호출하도록 분기 구조 마련

## 직전 블랙박스 검증 리포트 (Slice 1 결과 요약)
| 검증 항목 | 실행 명령 | 결과 | 비고 |
| :--- | :--- | :--- | :--- |
| 스키마 & 가드레일 계약 | `uv run pytest tests/unit/` | **PASS (6/6)** | `lookback_minutes=240` 차단 및 정상 DTO 반환 확인 |
| 로컬 스모크 실행 | `agents-cli run "prod-proj의 checkout-api(asia-northeast3) 최근 30분 장애 분석해줘"` | **PASS** | 3개 Mock 도구 병렬 호출 후 `rev-0042` 배포 직후 커넥션 풀 고갈 원인 정확히 지목 |

## 다음 세션 첫 작업 (Next Action)
- **다음 작업**: **Slice 2** — `app/tools.py`의 `USE_MOCK_TOOLS=false` 분기에 실제 `google-cloud-logging`, `google-cloud-monitoring`, `google-cloud-run` 읽기 전용 SDK 호출 및 `403 PermissionDenied` 부분 실패 처리 구현
- **컨텍스트/모델 가이드**: 여기서 **`/compact`** 또는 **새 대화창** 전환 권장. Slice 2 구현은 스펙이 명확하므로 **Flash** 모델 사용 가능(GCP IAM 디버깅 발생 시에만 Pro 전환).
