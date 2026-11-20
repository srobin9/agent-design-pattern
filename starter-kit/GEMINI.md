# Project Anti-Slop & SRE Gate Rules

이 프로젝트는 **계약 우선(Contract-First) · 얇은 슬라이스(Thin Slice) · 블랙박스 검증** 원칙을 따릅니다. 작업 시작 시 반드시 `lean-agent-architect` 스킬을 활성화하세요.

## 1. 작업 전 필수 확인 (Zero-Guessing)
- 코딩이나 스캐폴딩 전 반드시 `.agents-cli-spec.md`(1-Page 계약서)와 `STATE.md`(현재 슬라이스 상태)를 먼저 읽으세요.
- `.agents-cli-spec.md`가 승인되기 전에는 절대 `agents-cli scaffold`를 실행하거나 구현 코드(`.py`)를 작성하지 마세요.

## 2. 컨텍스트 격리 (토큰 폭발 차단)
- 외부 문서나 ADK 샘플 레포지토리(`adk-samples`)를 메인 대화창에서 직접 클론하거나 다량으로 읽지 마세요.
- 레퍼런스 조사나 긴 로그 분석이 필요하면 반드시 `research` 서브에이전트에 위임하여 **25줄 이내의 핵심 요약**만 메인 창으로 가져오세요.

## 3. 수직 슬라이스 & Stub-First 구현
- 한 번의 승인 사이클에서는 `STATE.md`에 지정된 **단 하나의 슬라이스만** 구현하세요.
- **Slice 1**은 항상 외부 GCP/API 인증 없이 로컬에서 즉시 검증 가능한 **Mock/Stub 도구 + 입출력 계약**으로 먼저 완성합니다.

## 4. 블랙박스 검증 & 2-Strike 서킷 브레이커
- `uv run pytest`는 결정론적 계약(도구 입출력 DTO, 가드레일 콜백) 검증에만 사용하고, 에이전트 응답 확인은 `agents-cli run` 및 `agents-cli eval`을 사용하세요.
- **2-Strike 서킷 브레이커**: 동일한 에러가 **2회 연속** 반복되면 즉시 코드 수정을 멈추고, 5줄 요약(`증상 / 원인 가설 / 시도 내역 / 대안 A·B`)을 보고한 뒤 사용자 결정을 기다리세요.
- 슬라이스 완료 시 `STATE.md`를 갱신하고, 코드 나열 대신 **블랙박스 검증 요약표 + `/compact` 및 다음 단계 추천 모델(Flash/Pro)**을 안내하세요.
