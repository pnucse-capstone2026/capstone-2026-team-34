<div align="center">

<img src="assets/brand/tripick-app-icon.svg" width="88" height="88" alt="TriPick" />

# TriPick (트리픽)

**Trip + Pick — 취향으로 골라주는 AI 여행 플래너 에이전트**

부산대학교 정보컴퓨터공학부 2026년도 졸업과제 · TEAM-34

[![CI](https://github.com/pnucse-capstone2026/capstone-2026-team-34/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/pnucse-capstone2026/capstone-2026-team-34/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-2E6BE6.svg)](LICENSE)
[![tripick.place](https://img.shields.io/badge/LIVE-tripick.place-2E6BE6?logo=googlechrome&logoColor=white&labelColor=1B4BB8)](https://tripick.place)

</div>

---

## 1. 프로젝트 배경

### 1.1. 국내외 시장 현황 및 문제점

국내 여행 시장은 패키지에서 개별 자유여행(FIT)으로 옮겨 갔지만, 계획을 세우는 도구는 그 변화를 따라가지 못했다.

- **장소 검색과 일정 작성이 분리돼 있다.** 지도·블로그·리뷰 앱을 오가며 후보를 모으고, 그 결과를 다시 메모장이나 스프레드시트에 시간 순으로 옮겨 적는다. 여행자가 실제로 쓰는 시간의 대부분은 "어디를 갈지"가 아니라 **고른 곳을 이동 가능한 시간표로 엮는 일**에 들어간다.
- **추천이 개인 취향이 아니라 대중 순위를 따른다.** 기존 서비스의 추천은 조회수·방문자 수 같은 일반 통계에 기반해, 누가 검색해도 비슷한 유명 관광지 목록이 나온다. "조용한 바닷가 카페"를 좋아하는 사람과 "야시장과 시장 골목"을 좋아하는 사람에게 같은 결과가 돌아간다.
- **여행이 시작되면 계획은 방치된다.** 비가 오거나, 이동이 지연돼 다음 장소 시간을 놓치거나, 관광지가 붐벼도 계획은 그대로 남는다. 계획을 고치려면 다시 처음부터 검색해야 한다.
- **LLM 기반 여행 추천의 한계.** 범용 LLM 에 일정을 물으면 그럴듯한 문장은 나오지만 **영업시간·실제 이동시간·좌표가 검증되지 않는다.** 존재하지 않는 장소나 폐업한 가게가 섞이고, 하루에 물리적으로 불가능한 동선이 나온다.

### 1.2. 필요성과 기대효과

이 문제들은 각각 다른 성격의 해법을 요구한다.

| 문제                        | TriPick 의 접근                                                         | 기대효과                                         |
| --------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------ |
| 취향을 말로 설명하기 어렵다 | 갤러리 사진을 vision 모델로 분석해 취향 태그·임베딩으로 변환            | 설문 없이 개인화된 후보 풀 확보                  |
| 추천이 대중 순위로 수렴한다 | pgvector 취향 유사도 검색 + 대중 인지도는 **소프트 재랭킹**으로만 반영  | 유명하지 않아도 취향에 맞는 장소가 상위로 올라옴 |
| LLM 결과를 신뢰할 수 없다   | 후보를 **실제 장소 카탈로그에서만** 뽑고, LLM 초안을 제약 엔진으로 검증 | 좌표·영업시간·이동시간이 검증된 일정만 저장      |
| 여행 중 상황 변화           | 미도착·날씨·혼잡을 서버가 감지해 알림, 재계획은 사용자 확인 후          | 예측 불가능한 자동 변경 없이 대응 가능           |

또한 LLM 추론을 외부 상용 API 가 아니라 **자체 GPU 파드에서 서빙**(Gemma 4 + llama.cpp, OpenAI 호환 인터페이스)하여, 사용자 사진·위치 같은 민감 데이터가 외부 사업자에게 나가지 않고 호출량에 따른 비용 종속도 없앴다.

---

## 2. 개발 목표

### 2.1. 목표 및 세부 내용

**사진으로 취향을 읽어 국내 여행 일정을 자동 생성하고, 여행 중 맥락 변화를 감지해 일정 조정을 추천하는 AI 에이전트 서비스.**

| 기능                     | 설명                                                                                             |
| ------------------------ | ------------------------------------------------------------------------------------------------ |
| **취향 사진 분석**       | 갤러리 사진 → vision 모델 → 음식·무드·자연/도시 태그 → pgvector 임베딩                           |
| **AI 일정 생성**         | 목적지·기간·이동 수단·취침/기상 시간을 받아 일차별 타임라인 생성                                 |
| **RAG / CRAG 후보 검색** | 전국 7만여 행 장소 카탈로그에서 취향 유사도로 후보를 뽑고, confidence 가 낮으면 외부 API 로 보정 |
| **제약 검증 루프**       | 영업시간·구간 ETA·활동 가능 시간 검증, 위반 시 근접 후보로 결정적 재생성 (최대 3회)              |
| **부분 재계획**          | 일차 단위로 다시 짜고 나머지 일차는 보존. 오늘 일차는 "지금 이후"만 다시 짬                      |
| **미도착 알림**          | 항목 시작 시각 + 15분에 현재 위치가 반경 500m 밖이면 inbox + 푸시                                |
| **날씨 · 혼잡 알림**     | 기상청 단·중기예보, 한국관광공사 관광지 집중률 기반 일정 조정 추천                               |
| **실시간 반영**          | Socket.IO 로 재계획 결과 push, FCM / APNs 로 푸시 알림                                           |
| **친구 · 동행**          | 친구 초대, 동행 취향 조율, 참여자 일정 변경에 대한 owner 승인                                    |

설계에서 고정한 세 가지 원칙:

1. **취향을 말이 아니라 사진으로 받는다** — 갤러리 사진을 분석해 음식·무드·자연/도시 태그를 뽑고 임베딩으로 저장해, 검색 자체를 개인화한다.
2. **일정을 규칙이 아니라 제약으로 만든다** — 영업시간·이동시간·취침/기상 시간을 통과할 때까지 결정적으로 재정렬한다. LLM 초안이 제약을 어기면 LLM 을 다시 부르지 않고 근접 후보로 재배치한다.
3. **여행 중에는 자동으로 바꾸지 않고 알려준다** — 미도착·날씨·혼잡은 전부 "추천 알림"까지만 간다. 실제 재계획은 사용자가 확인하고 요청할 때만 실행된다.

### 2.2. 기존 서비스 대비 차별성

| 항목             | 기존 여행 플래너 · 범용 LLM   | TriPick                                                            |
| ---------------- | ----------------------------- | ------------------------------------------------------------------ |
| 취향 입력        | 텍스트 설문 / 카테고리 선택   | **사진 기반** vision 분석 + 임베딩                                 |
| 후보 선정        | 조회수·평점 등 대중 통계 순위 | **pgvector 취향 유사도** 기반, 인지도는 0.12 가중의 보조 신호      |
| 장소 신뢰성      | LLM 생성 텍스트 (환각 가능)   | 실제 카탈로그(한국관광공사·카카오 로컬) **후보 ID 검증**           |
| 일정 실행 가능성 | 검증 없음                     | **Constraint Engine** — 영업시간·구간 ETA·활동 시간 검증 루프      |
| 여행 중 대응     | 없음 / 수동 재작성            | 미도착·날씨·혼잡 **서버 감지 → 알림 → 사용자 확인 후 부분 재계획** |
| 재계획 범위      | 전체 재작성                   | **일차 단위 부분 재계획**, 오늘 일차는 "지금 이후"만               |
| LLM 인프라       | 외부 상용 API                 | **자체 GPU 파드 서빙** (Gemma 4 + llama.cpp)                       |

핵심 차별점은 **LLM 을 툴 라우터가 아니라 초안 생성기로만 쓴다**는 설계다. 후보 검색·경로·날씨 조회는 코드가 정한 결정적 순서로 먼저 끝내고, LLM 은 검증된 후보와 제약이 모두 갖춰진 상태에서 일정 초안 하나만 만든다. 그 초안도 제약 엔진을 통과해야 저장된다.

### 2.3. 사회적 가치 도입 계획

- **국내 여행 · 지역 관광 활성화** — 후보 풀을 한국관광공사 국문 관광정보와 카카오 로컬로 구성하고, 대중 인지도는 후보를 제거하지 않고 순위만 조정하는 소프트 재랭킹으로 다뤘다. 그 결과 유명 관광지에 가려진 **지역 소규모 장소가 취향이 맞는 사용자에게 노출**된다.
- **개인정보 보호** — 취향 사진·위치 같은 민감 데이터를 외부 LLM 사업자에게 보내지 않고 자체 추론 인프라에서 처리한다. 사진은 취향 태그·임베딩 추출 후 원본을 서비스 목적 외로 사용하지 않는다.
- **접근성과 저비용 운영** — 웹(Next.js)과 앱(React Native WebView)이 같은 화면을 공유해 앱 설치 없이 브라우저만으로 전체 기능을 쓸 수 있다. 자체 서빙으로 토큰 단가에 비례하는 운영비를 없애 무료 공개 서비스로 유지 가능하다.
- **오픈소스 공개** — 전체 코드를 MIT 라이선스로 공개한다.

---

## 3. 시스템 설계

### 3.1. 시스템 구성도

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/diagrams/architecture-dark.png" />
  <img src="assets/diagrams/architecture.png" alt="TriPick 시스템 아키텍처" />
</picture>

| 레이어          | 구성                                                                             |
| --------------- | -------------------------------------------------------------------------------- |
| **Client**      | React Native 앱 (WebView 컨테이너 · 위치 추적 · FCM) + Next.js 웹앱              |
| **API**         | NestJS — REST + Socket.IO Gateway, JWT / Passport, BullMQ Worker 동일 프로세스   |
| **AI Agent**    | Planner Orchestrator (툴 조율 · 프롬프트 구성 · JSON 검증) + Constraint Engine   |
| **LLM Serving** | 자체 GPU 파드 — llama.cpp 2개 (chat + vision / 임베딩), OpenAI 호환 API          |
| **Data**        | PostgreSQL 16 + pgvector, Redis (캐시 · 세션 · 잡 큐), S3 호환 오브젝트 스토리지 |
| **External**    | 카카오 (로컬 · 모빌리티 · 맵 · OAuth), ODsay, 기상청, 한국관광공사, 네이버 검색  |

> 툴 오케스트레이션은 LLM 이 툴을 고르는 agentic 라우팅이 아니라 **코드가 정한 결정적 순서**다.
> LLM 은 후보와 제약이 다 갖춰진 상태에서 일정 초안 하나만 만든다.

### 3.2. 사용 기술

| 영역               | 사용 기술                                                                                             |
| ------------------ | ----------------------------------------------------------------------------------------------------- |
| **Frontend (Web)** | Next.js 16 (App Router) · React 19 · TypeScript 6 · Tailwind CSS 4 · TanStack Query · 카카오맵 JS SDK |
| **Frontend (App)** | React Native 0.85 · react-native-webview · Firebase Messaging · notifee · Geolocation                 |
| **Backend**        | NestJS 11 · TypeORM · Passport / JWT · Socket.IO · BullMQ · Swagger                                   |
| **AI / ML**        | Gemma 4 (llama.cpp, chat + vision) · BGE-m3-ko 임베딩 (1024d) · RAG / CRAG                            |
| **Data**           | PostgreSQL 16 + pgvector (HNSW) · Redis 7 · S3 호환 스토리지 (MinIO / R2)                             |
| **Infra**          | Turborepo + pnpm workspace · Docker Compose · GitHub Actions · Vercel · Railway · RunPod              |
| **모니터링**       | Sentry · Vercel Analytics                                                                             |

**외부 API**

| 분류        | API                                        | 용도                                         |
| ----------- | ------------------------------------------ | -------------------------------------------- |
| 지도 · 장소 | 카카오맵 JS SDK, 카카오 로컬               | 지도 렌더링, 키워드 장소 검색, 좌표          |
| 경로 · ETA  | 카카오 모빌리티, ODsay                     | 자동차 경로, 대중교통 경로                   |
| 관광정보    | 한국관광공사 국문 관광정보 · 관광지 집중률 | 장소 카탈로그 적재, 영업시간 보강, 혼잡 예측 |
| 인기도      | 네이버 블로그 · 카페 검색 (NCP API Hub)    | 대중 인지도 재랭킹 신호                      |
| 날씨        | 기상청 단기 · 중기예보                     | 날씨 · 강수 기반 일정 조정 추천              |
| 인증 · 푸시 | 카카오 OAuth 2.0, Firebase FCM + APNs      | 로그인, 푸시 알림                            |

---

## 4. 개발 결과

### 4.1. 전체 시스템 흐름도

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/diagrams/flow-dark.png" />
  <img src="assets/diagrams/flow.png" alt="일정 생성 · 재계획 흐름" />
</picture>

- **FLOW A (일정 생성)** — 취향 / 조건 → CRAG 후보 검색 → 맥락 주입 → LLM 초안 → 제약 검증 → 저장
- **FLOW B (재계획)** — 서버가 상황을 감지해 알림 → 사용자가 확인 · 요청 → BullMQ 잡 → FLOW A 재사용 → WebSocket + 인박스 통지

경로 이탈 · 날씨 · 혼잡 어느 것도 **자동 재계획을 트리거하지 않는다.** 알림까지만 가고, 재계획은 사용자의 선택이다.

**취향 기반 후보 검색 (RAG / CRAG)**

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/diagrams/rag-crag-dark.png" />
  <img src="assets/diagrams/rag-crag.png" alt="RAG / CRAG 검색 파이프라인" />
</picture>

pgvector 유사도만으로는 마이너 장소가 상위를 채운다. 그래서 confidence 를 6개 항의 가중합으로 계산하고(취향 · 지역 근접 · 맥락 · 대중 인지도 · 영업 가능 · 벡터 유사도), 기준에 못 미치면 카카오 로컬로 후보를 덧대 다시 평가한다. 인지도 감점은 후보를 **제거하지 않고 순위만 낮춘다** — 개인화를 죽이지 않기 위한 소프트 재랭킹이다. 각 노브의 값과 근거는 [docs/preference](docs/preference) 아래 문서에 스윕 결과와 함께 고정돼 있다.

### 4.2. 기능 설명 및 주요 기능 명세서

|                                    ① 취향 사진 → 태그 추출                                    |                                    ② 생성된 일정 · 동선                                    |                                  ③ 동행 취향 조율                                   |
| :-------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------: |
| <img src="assets/screenshots/01-preference-tags.png" width="240" alt="취향 사진 분석 결과" /> | <img src="assets/screenshots/02-itinerary-map.png" width="240" alt="생성된 일정과 지도" /> | <img src="assets/screenshots/03-taste-sync.png" width="240" alt="동행 취향 조율" /> |

|                            ④ 미도착 · 날씨 · 혼잡 알림                             |                                      ⑤ 재계획 요청                                      |                                ⑥ 여행 진행 · 다음 장소 ETA                                |
| :--------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------: | :---------------------------------------------------------------------------------------: |
| <img src="assets/screenshots/04-inbox-alerts.png" width="240" alt="알림 인박스" /> | <img src="assets/screenshots/05-replan-request.png" width="240" alt="AI 재계획 요청" /> | <img src="assets/screenshots/06-trip-live.png" width="240" alt="여행 진행 실시간 화면" /> |

**주요 기능 명세**

| 기능             | 입력                                              | 처리                                                           | 출력                                     |
| ---------------- | ------------------------------------------------- | -------------------------------------------------------------- | ---------------------------------------- |
| 취향 사진 분석   | 갤러리 사진 (다중 업로드)                         | vision 모델 태그 추출 → 임베딩 (1024d) 저장                    | 음식 · 무드 · 자연/도시 취향 태그        |
| 일정 생성        | 목적지, 기간, 이동 수단, 취침 · 기상 시간, 강도   | CRAG 후보 검색 → LLM 초안 → 제약 검증 (최대 3회 재생성)        | 일차별 타임라인 (장소 · 시각 · 구간 ETA) |
| 부분 재계획      | trigger (deviation / weather / manual), 대상 일차 | BullMQ 잡 → 대상 일차만 재생성, 유지 일차 장소는 후보에서 제외 | 갱신된 일차 + WebSocket push             |
| 미도착 알림      | 항목 시작 시각 + 15분, 사용자 최신 위치           | 반경 500m 밖 판정 (위치 10분 이상 오래되면 스킵)               | `arrival_alert` 인박스 + FCM 푸시        |
| 날씨 알림        | 여행 일정 좌표 → nx · ny 격자                     | 기상청 단 · 중기예보 조회, 강수 · 악천후 판정                  | `weather_alert` 인박스 + 푸시            |
| 혼잡 알림        | 일정 내 관광지 (하루 1회 스캔)                    | 관광공사 집중률 예측값 vs 해당 장소 평균 비교                  | `crowd_alert` 인박스 + 푸시              |
| 실시간 위치 보고 | 앱 foreground service / 웹 geolocation            | `POST /live/location` → Redis 캐시                             | 미도착 판정 · 재계획 위치 앵커           |
| 친구 · 동행      | 친구 초대, 동행 참여                              | 동행 취향 임베딩 병합, 일정 변경 owner 승인                    | 공유 여행 일정                           |

### 4.3. 디렉토리 구조

```
capstone-2026-team-34/
├── apps/
│   ├── api/          # NestJS — auth · trips · itinerary · planner · replanning · alerts
│   ├── web/          # Next.js 웹앱 (FSD: app / views / widgets / features / entities / shared)
│   └── mobile/       # React Native WebView 셸 (위치 · 푸시 · 딥링크)
├── packages/
│   ├── types/        # FE·BE 공유 DTO·타입
│   └── utils/        # 기상청 격자 변환 등 공통 유틸
├── infra/
│   ├── postgres/     # init.sql (pgvector 확장 · 벡터 컬럼)
│   └── runpod/       # GPU 추론 파드 Dockerfile · 기동 스크립트
├── docs/
│   ├── 01.보고서/    # 착수 · 중간 · 최종 보고서
│   ├── 02.포스터/
│   ├── 03.발표자료/
│   └── (그 외)       # 기능별 결정 · 근거 · 검증 기술 문서 — docs/README.md 인덱스
├── assets/           # 브랜드 · 다이어그램 · 스크린샷
├── scripts/
├── CLAUDE.md         # 프로젝트 전반 컨텍스트 (아키텍처 · 제약 · 결정 사항)
├── docker-compose.yml
└── install_and_build.sh
```

`apps/api` 의 핵심 도메인은 `planner` 모듈이다.

```
apps/api/src/planner/
├── planner.service.ts           # LLM 오케스트레이션, 일정 생성 · 수정
├── helpers/
│   ├── weather.helper.ts        # 기상청 API, 격자 변환, 동선 조정
│   ├── route.helper.ts          # 카카오 · ODsay 길찾기, ETA 계산
│   ├── preference.helper.ts     # pgvector 취향 임베딩 RAG 조회
│   └── schedule.constraint.ts   # 취침 · 기상 시간 제약
└── constraint/
    └── constraint.engine.ts     # 영업시간 · 이동시간 · 경로 검증 루프
```

### 4.4. 산업체 멘토링 의견 및 반영 사항

| 항목              | 멘토 의견                                                                                                                                                                              | 반영 사항                                                                                                                                                                                                                                                                                   |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 과제목표          | 취향 벡터 개인화 + 실시간 상황 대응이라는 목표와 Constraint Engine 재검증 구조가 명확. 다만 "같은 목적지에서 취향을 바꿨을 때 추천이 실제로 얼마나 달라지는지" 를 정량적으로 보여줄 것 | counterfactual 개인화 평가 하니스 추가(`pnpm eval:personalization`) — 무개인화 대비 순위 변화, 취향 벡터의 태그 대비 추가 이득, 타인 프로필 교체 시 점수 하락, 그룹 병합 시 공정성 4개 축을 분리 측정 (`docs/preference/personalization-counterfactual-eval-v1.md`)                         |
| 설계 사양 및 내용 | 다계층 구조와 cache·seed·deterministic fallback 설계는 운영을 염두에 둔 것으로 적절. 남은 기간은 대표 흐름의 반복 검증에 집중하고, pgvector 검색시간·재임베딩 처리시간을 측정해 둘 것  | 일정 생성을 BullMQ 비동기 잡으로 전환해 단계별 진행률을 실측 기반으로 보고 (`docs/performance/async-trip-generation-v1.md`). 검색 품질·지연은 골든셋 평가 하니스(`pnpm eval:retrieval`, 노브 스윕)로 반복 측정                                                                              |
| 성능평가          | AI 일정 품질을 단일 점수가 아니라 취향 반영도·영업시간/이동시간 위반·재계획 성공률·평균 응답시간·외부 API 실패 시 fallback 성공 여부로 나눠 측정할 것                                  | 지표를 항목별로 분리 — 취향 반영도는 개인화 counterfactual 평가, 제약 위반은 Constraint Engine 검증 루프 테스트, fallback 은 LLM·길찾기·인지도 API 부재 시 각각 규칙 기반 플래닝·직선거리 추정·중립값으로 대체되는 경로를 테스트로 고정. CI 에서 verify / e2e / migrations 3개 잡 상시 실행 |
| 자문 결론         | 취향 개인화·실시간 대응·실행 가능성 검증을 함께 구현한 점이 강점. 최종 시연에서는 서로 다른 취향과 돌발 상황에서 일정이 실제로 어떻게 달라지는지를 보여줄 것                           | 시연 시나리오를 취향 대비(동일 목적지·상이한 취향 프로필)와 상황 대응(미도착·날씨·혼잡 알림 → 사용자 확인 → 부분 재계획) 두 축으로 구성                                                                                                                                                     |

---

## 5. 설치 및 실행 방법

### 5.1. 설치절차 및 실행 방법

**요구 사항**

- Node.js 20 (`.nvmrc`)
- pnpm 9 (`corepack enable`)
- Docker (PostgreSQL · Redis · MinIO · Mailpit)

**설치 · 실행**

```bash
git clone https://github.com/pnucse-capstone2026/capstone-2026-team-34.git
cd capstone-2026-team-34

./install_and_build.sh      # corepack 활성화 + 의존성 설치 + .env 준비 + 빌드

pnpm start                  # 인프라 기동 + web · API 동시 실행 (http://localhost:3000)
```

`pnpm start` 는 `pnpm db:up` (Docker 인프라) 후 `turbo run dev` 로 web · API 를 함께 띄운다. 인프라만 따로 올리려면 `pnpm db:up`, 내리려면 `pnpm db:down`. 개발 모드에서는 TypeORM `synchronize` 로 스키마가 자동 반영돼 별도 마이그레이션 실행이 필요 없다.

**포트**

| 서비스        | 주소                                                |
| ------------- | --------------------------------------------------- |
| Web (Next.js) | http://localhost:3000                               |
| API (NestJS)  | http://localhost:4000/api/v1 (Swagger: `/api/docs`) |
| PostgreSQL    | localhost:5432 (`tripick` / `tripick`)              |
| Redis         | localhost:6379                                      |
| MinIO         | http://localhost:9000 (콘솔 :9001)                  |
| Mailpit       | http://localhost:8025                               |

**외부 API 키**

키 없이도 앱은 뜬다 — 해당 기능만 폴백으로 동작한다. 전체 기능을 보려면 `apps/api/.env` 에 채운다.

| 키                                           | 용도                           | 없을 때                      |
| -------------------------------------------- | ------------------------------ | ---------------------------- |
| `KAKAO_REST_API_KEY` · `KAKAO_LOCAL_API_KEY` | 장소 검색, 자동차 경로, OAuth  | 시드 후보 · 직선거리 추정    |
| `NEXT_PUBLIC_KAKAO_MAP_KEY`                  | 웹 지도 렌더링                 | 지도 미표시                  |
| `ODSAY_API_KEY` · `ODSAY_SERVICE_URL`        | 대중교통 경로                  | 직선거리 추정 폴백           |
| `KMA_API_KEY`                                | 기상청 단기예보                | 날씨 카드 · 알림 비활성      |
| `KTO_API_KEY`                                | 관광공사 관광정보 적재, 집중률 | 카탈로그 적재 불가           |
| `NAVER_SEARCH_CLIENT_ID` · `_SECRET`         | 대중 인지도 재랭킹             | 인지도 항 중립값 (랭킹 불변) |
| `FIREBASE_*`                                 | FCM 푸시                       | 인박스만 동작                |

**로컬 LLM**

일정 생성 · 취향 사진 분석 · 임베딩은 OpenAI 호환 엔드포인트를 호출한다. 기본값은 로컬 llama.cpp 다.

```bash
# chat + vision (mmproj 포함)
llama-server -m gemma-4-26b-q4.gguf --mmproj mmproj.gguf --port 8080

# 임베딩 (BGE-m3-ko, 1024차원 — pgvector 컬럼과 일치해야 함)
llama-server -m bge-m3-ko.gguf --embedding --port 8081
```

서버가 없으면 `LLM_PLANNER_ENABLED=false` 로 두면 된다. 규칙 기반 폴백 플래닝으로 일정이 생성된다.

**주요 스크립트**

| 명령                                        | 설명                                                     |
| ------------------------------------------- | -------------------------------------------------------- |
| `pnpm start`                                | 인프라 기동 + web · API dev 실행                         |
| `pnpm dev`                                  | web · API dev 실행 (인프라 제외)                         |
| `pnpm dev:android` / `dev:ios`              | React Native 앱 실행                                     |
| `pnpm build` / `lint` / `test`              | Turborepo 전체 태스크                                    |
| `pnpm --filter @tripick/api ingest:places`  | 장소 카탈로그 적재 (KTO · 카카오 · 네이버)               |
| `pnpm --filter @tripick/api eval:retrieval` | 골든셋 검색 품질 평가 (`--sweep=KEY=v1,v2` 로 노브 스윕) |
| `pnpm --filter @tripick/api migration:run`  | 마이그레이션 적용 (배포 환경용)                          |

**테스트**

```bash
pnpm test                                   # 전체 유닛
pnpm --filter @tripick/api test:e2e         # e2e (DB 필요)
pnpm --filter @tripick/api test:integration # 로컬 LLM 필요
```

PR 마다 GitHub Actions 에서 **verify**(빌드 · 타입체크 · 린트 · 유닛), **e2e**(HTTP 계약 · 인가 경계), **migrations**(up → 재실행 no-op → revert → up) 세 잡이 돈다.

### 5.2. 오류 발생 시 해결 방법

| 증상                               | 원인                                    | 해결                                                                                                                                           |
| ---------------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `relation "vector" does not exist` | 일반 `postgres:16` 이미지 사용          | `pgvector/pgvector:pg16` 이미지만 사용. `docker compose down -v` 후 재기동                                                                     |
| MinIO 버킷 없음 에러               | 초기화 잡 미실행                        | `docker compose up minio-init` 한 번 실행                                                                                                      |
| 이동시간이 비현실적으로 나옴       | 길찾기 API 실패 → 직선거리 폴백         | 카카오 · ODsay 키 확인. ODsay 는 `ODSAY_SERVICE_URL` 이 발급 시 등록한 도메인과 정확히 일치해야 함 (불일치 시 HTTP 200 + `[ApiKeyAuthFailed]`) |
| 일정 생성이 폴백으로만 동작        | LLM 서버 미기동                         | `llama-server` 기동 확인, 또는 `LLM_PLANNER_ENABLED=false` 로 명시                                                                             |
| 임베딩 차원 불일치 에러            | 임베딩 모델과 pgvector 컬럼 차원 불일치 | BGE-m3-ko (1024d) 사용 확인                                                                                                                    |
| 카카오 로그인이 콜백에서 실패      | `state` 쿠키 오리진 불일치              | 로그인 시작 URL 을 서버가 내려주는 절대 `startUrl` 로 사용 (`/auth/kakao/status`)                                                              |
| 프로덕션 부팅 거부                 | `JWT_SECRET` 미설정 또는 예시값 그대로  | `JWT_SECRET` · `JWT_REFRESH_SECRET` 을 실제 값으로 설정                                                                                        |
| 웹에서 위치가 안 잡힘              | geolocation 은 HTTPS 전용               | `localhost` 또는 HTTPS 환경에서 실행                                                                                                           |

---

## 6. 소개 자료 및 시연 영상

### 6.1. 프로젝트 소개 자료

- 최종 발표자료: [docs/03.발표자료](docs/03.발표자료)
- 포스터: [docs/02.포스터](docs/02.포스터)
- 보고서 (착수 · 중간 · 최종): [docs/01.보고서](docs/01.보고서)

### 6.2. 시연 영상

[![TriPick 시연 영상](http://img.youtube.com/vi/BM2o1f-YCEA/0.jpg)](https://youtu.be/BM2o1f-YCEA?si=1RMnuZwmueZ2cLTg)

라이브 서비스는 [tripick.place](https://tripick.place) 에서 바로 사용할 수 있다 (WebView 앱과 동일 화면).

---

## 7. 팀 구성

### 7.1. 팀원별 소개 및 역할 분담

| 팀원   | 이메일             | 주 담당                                     | 주요 산출물                                                                                                                                                                                                     |
| ------ | ------------------ | ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 고태영 | koty08@pusan.ac.kr | AI 파이프라인, 서버 도메인, 데이터 · 인프라 | Planner 오케스트레이션과 제약 엔진, pgvector 적재 · CRAG 검색과 평가 하니스, 인증 하드닝, 알림 3종(미도착 · 날씨 · 혼잡) 스케줄러, BullMQ · WebSocket, RunPod 추론 서빙, Railway / Vercel / R2 배포와 운영 문서 |
| 박준이 | zun_e@pusan.ac.kr  | 웹 프론트엔드와 디자인 시스템, 협업 도메인  | 랜딩 · 로그인 · 여행 생성 · 플래너 화면 UI, 공용 UI 컴포넌트와 비주얼 리디자인, 취향 입력 · 취향 조율 화면, 친구 · 여행 멤버 · 초대 기능, 모바일 앱 아이콘과 스토어 리소스                                      |

### 7.2. 팀원 별 참여 후기

- **고태영** : LLM 을 쓰는 서비스를 만들면서 가장 많이 배운 건 "LLM 에 얼마나 맡기지 않을 것인가" 였다. 처음에는 툴 선택까지 모델에 맡기려 했지만, 존재하지 않는 장소와 실행 불가능한 동선이 계속 나왔다. 결국 후보 검색 · 경로 · 날씨는 코드가 정한 순서로 먼저 끝내고 LLM 은 초안 하나만 만들게, 그 초안도 제약 엔진을 통과해야 저장되게 구조를 바꿨다. 검색 품질도 감으로 노브를 만지는 대신 골든셋 평가 하니스를 만들어 스윕 결과로 값을 고정했는데, 측정 없이 고친 건 대부분 착각이었다는 걸 확인하는 과정이었다.

- **박준이** : 화면을 만드는 일이 컴포넌트를 배치하는 일이 아니라는 걸 알게 됐다. 취향 입력이나 동행 조율처럼 사용자가 무엇을 골라야 하는지 스스로도 모르는 화면에서는, 기능이 다 동작해도 흐름이 어색하면 쓰이지 않았다. 공용 UI 컴포넌트를 먼저 정리하고 비주얼을 다시 잡은 뒤에야 화면마다 제각각이던 간격과 위계가 맞았다. 서버와의 경계도 `packages/types` 로 DTO 를 공유하면서 계약을 먼저 맞추는 편이 결국 빨랐다.

## 8. 참고 문헌 및 출처

**논문 · 방법론**

- Lewis et al., _Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks_, NeurIPS 2020
- Yan et al., _Corrective Retrieval Augmented Generation (CRAG)_, 2024
- Malkov & Yashunin, _Efficient and Robust Approximate Nearest Neighbor Search Using HNSW Graphs_, IEEE TPAMI 2020
- Es et al., _RAGAS: Automated Evaluation of Retrieval Augmented Generation_, 2023

**모델 · 라이브러리**

- [Gemma](https://ai.google.dev/gemma) — Google DeepMind
- [llama.cpp](https://github.com/ggml-org/llama.cpp) — ggml-org
- [BGE-m3](https://github.com/FlagOpen/FlagEmbedding) — BAAI
- [pgvector](https://github.com/pgvector/pgvector)
- [NestJS](https://nestjs.com) · [Next.js](https://nextjs.org) · [React Native](https://reactnative.dev) · [BullMQ](https://docs.bullmq.io)

**공공 · 상용 API**

- [한국관광공사 국문 관광정보 · 관광지 집중률 (공공데이터포털)](https://www.data.go.kr)
- [기상청 단기예보 · 중기예보 (공공데이터포털)](https://www.data.go.kr)
- [카카오 개발자 — 로컬 · 모빌리티 · 맵 · OAuth](https://developers.kakao.com)
- [ODsay 대중교통 API](https://lab.odsay.com)
- [네이버 검색 API (NCP API Hub)](https://api.ncloud-docs.com)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)

**프로젝트 내부 문서**

- [docs/README.md](docs/README.md) — 기능별 결정 · 근거 · 검증 문서 인덱스
- [CLAUDE.md](CLAUDE.md) — 아키텍처 · 제약 · 설계 결정 전반
- [docs/overview/repository-readme.md](docs/overview/repository-readme.md) — 개발용 리포지토리 README

---

## 라이선스

[MIT](LICENSE) © TEAM-34
