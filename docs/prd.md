좋습니다. 말씀하신 내용을 반영하여, 기존 PRD를 최신 사양에 맞게 수정한 **MVP 버전 PRD**를 아래에 정리하였습니다.
이 문서는 Flutter + FastAPI + Spring Boot + AWS 아키텍처를 기반으로 한 **실제 개발 지침 수준의 PRD**입니다.

---

### **[PRD] 수집가의 기록 앱 ‘카탈로깅 (Collectors' Companion App)’**

---

## **1. 개요**

* **프로젝트명:** 카탈로깅 (Collectors' Companion App)

* **핵심 목표:**
  수집가가 자신의 소장품을 **카탈로그 단위로 체계적으로 기록·관리**하고,
  오프라인에서도 CRUD가 가능한 모바일 앱을 제공함.
  SNS 로그인 기반 계정 관리, 클라우드 동기화, 수집률 시각화를 통해
  완성의 성취감과 기록의 즐거움을 제공함.

* **MVP 개발 범위:**

  * **회원 CRUD (Spring Boot + RDS)** — SNS 로그인(Google, Apple, Naver)
  * **카탈로그 및 아이템 CRUD (FastAPI + DynamoDB)**
  * **Flutter 클라이언트 (iOS / Android)**
  * **S3 이미지 업로드, CloudFront 정적 배포, ALB(API Gateway 역할)**
  * **SQLite 로컬 캐시 기반 오프라인 퍼스트 동작 (서버 우선 병합 정책)**

---

## **2. 타겟 사용자**

* 넘버링 시리즈, 피규어, 스니커즈, 음반 등 수집품을 체계적으로 관리하고 싶은 **수집가**
* 완전 수집률을 확인하고 싶은 **전종러(완전 수집 지향 사용자)**
* 인터넷 연결이 불안정한 환경에서도 기록을 유지하고 싶은 **모바일 중심 사용자**

---

## **3. 기능 명세**

---

### **Part 1. 회원 기능 (Spring Boot / RDS)**

#### **F-01: SNS 로그인 (Google / Apple / Naver)**

* **설명:** 사용자는 Google, Apple, Naver 계정을 통해 회원가입 및 로그인을 수행함.
* **요구사항:**

  * OAuth 2.0 기반 SNS 인증 후, 백엔드(Spring Boot)에서 JWT 토큰 발급.
  * SNS Provider별 식별자(`provider`, `provider_id`)로 회원 중복 방지.
  * 최초 로그인 시 사용자 프로필 자동 생성.
  * 클라이언트 측에서는 JWT 토큰 저장 및 자동 갱신 관리.
  * Apple은 iOS 전용, Naver는 국내 사용자를 위한 선택 옵션.

#### **F-02: 프로필 관리**

* **설명:** 로그인한 사용자는 프로필 정보를 관리할 수 있음.
* **요구사항:**

  * 필드: `닉네임`, `소개`, `프로필 이미지(S3 URL)`.
  * 공개/비공개 범위 설정 가능.
  * 회원 탈퇴 시 연관 카탈로그/아이템 soft-delete 처리.

---

### **Part 2. 카탈로그 기능 (FastAPI / DynamoDB)**

#### **F-03: 카탈로그 생성 및 관리**

* **설명:** 사용자는 자신만의 카탈로그를 생성하고 관리할 수 있음.
* **요구사항:**

  * 필수 필드:

    * `title` (카탈로그 제목, **필수**)
    * `description` (카탈로그 설명, **필수**)
  * 선택 필드 (기본값 존재):

    * `category` (기본값: "미분류")
    * `tags` (문자열 배열)
    * `visibility` (공개 여부, 기본값: `public`)
    * `thumbnail_url` (S3 업로드 이미지 URL)
  * 기능:

    * 카탈로그 목록 보기, 생성, 수정, 삭제 CRUD 지원.
    * 카탈로그별 아이템 리스트 및 수집률 계산.
    * 태그·카테고리 기반 필터링(고도화 단계에서 확장).

---

### **Part 3. 아이템 기능 (FastAPI / DynamoDB)**

#### **F-04: 아이템 추가 및 상세 입력**

* **설명:** 사용자는 카탈로그 내에 수집품을 개별 등록하고 관리함.
* **요구사항:**

  * 필수 필드:

    * `name` (아이템명, **필수**)
    * `description` (아이템 설명, **필수**)
  * 선택 필드:

    * `image_url` (S3 업로드)
    * `owned` (보유 여부, boolean)
    * `user_fields` (사용자 정의 필드 — key:value 쌍, 예: `{ "시리즈": "Gen1", "희귀도": "SSR" }`)
  * 기능:

    * 아이템 생성, 수정, 삭제, 보유 여부 토글.
    * 사용자 정의 필드를 JSON 형태로 DynamoDB에 저장.
    * 수집률 = (보유 아이템 수 / 전체 아이템 수) × 100

#### **F-05: 이미지 업로드 (S3 Signed URL)**

* **설명:** 사용자는 사진을 선택하면 앱이 백엔드(FastAPI)를 통해 S3 서명 URL을 발급받아 직접 업로드함.
* **요구사항:**

  * FastAPI에서 presigned URL 생성 후 반환.
  * Flutter에서 multipart 업로드 → URL 저장.
  * 업로드 실패 시 재시도 큐에 임시 저장.

---

### **Part 4. 오프라인 퍼스트 및 동기화 (Flutter / SQLite)**

#### **F-06: 로컬 저장 및 서버 동기화**

* **설명:** 네트워크 불안정 시 로컬 SQLite를 사용하여 CRUD 작업을 임시 저장.
* **요구사항:**

  * 오프라인 CRUD는 SQLite에 캐시.
  * 온라인 복구 시 FastAPI와 비교 후 **서버 우선 정책**으로 병합.
  * 충돌 발생 시 서버 버전 우선 반영, 클라이언트는 덮어쓰기 처리.
  * 업로드 실패 항목은 재시도 큐로 관리.

#### **F-07: UI 및 사용자 흐름**

* **설명:** Flutter 앱에서 직관적인 UX로 컬렉션을 관리할 수 있음.
* **요구사항:**

  * 홈 화면: 내 카탈로그 리스트 및 수집률 요약.
  * 카탈로그 상세: 아이템 리스트 및 필터(보유/미보유).
  * 아이템 상세: 이미지, 설명, 사용자 정의 필드 표시.
  * 오프라인 시 읽기 전용 모드 안내 및 동기화 상태 표시.

---

## **4. 데이터 구조**

### **RDS (회원 / Spring Boot)**

| 필드명           | 타입       | 설명                              |
| ------------- | -------- | ------------------------------- |
| id            | bigint   | PK                              |
| provider      | varchar  | SNS 제공자명 (google, apple, naver) |
| provider_id   | varchar  | SNS 고유 식별자                      |
| email         | varchar  | 사용자 이메일                         |
| nickname      | varchar  | 닉네임                             |
| profile_image | varchar  | 프로필 이미지 URL                     |
| created_at    | datetime | 가입일                             |
| updated_at    | datetime | 수정일                             |

---

### **DynamoDB (카탈로그 및 아이템 / FastAPI)**

**Catalog Table**

| 필드명           | 타입           | 설명                           |
| ------------- | ------------ | ---------------------------- |
| catalog_id    | string (PK)  | 카탈로그 고유 ID                   |
| user_id       | string       | 소유자 ID                       |
| title         | string       | 카탈로그 제목 (필수)                 |
| description   | string       | 카탈로그 설명 (필수)                 |
| category      | string       | 카테고리 (기본값: "미분류")            |
| tags          | list[string] | 태그 리스트                       |
| visibility    | string       | 공개 여부 (`public` / `private`) |
| thumbnail_url | string       | 썸네일 이미지 URL (S3)             |
| created_at    | string       | 생성일                          |
| updated_at    | string       | 수정일                          |

**Item Table**

| 필드명         | 타입                 | 설명           |
| ----------- | ------------------ | ------------ |
| item_id     | string (PK)        | 아이템 고유 ID    |
| catalog_id  | string             | 카탈로그 ID (FK) |
| name        | string             | 아이템명 (필수)    |
| description | string             | 아이템 설명 (필수)  |
| image_url   | string             | S3 이미지 URL   |
| owned       | boolean            | 보유 여부        |
| user_fields | map<string,string> | 사용자 정의 필드    |
| created_at  | string             | 생성일          |
| updated_at  | string             | 수정일          |

---

## **5. 시스템 아키텍처**

```
[Flutter App]
   ↓
[ALB (AWS Application Load Balancer)]
   ├─ /api/users → Spring Boot (EC2 / RDS)
   └─ /api/catalogs → FastAPI (EC2 / DynamoDB)
        ↓
      S3 (이미지 저장)
        ↓
      CloudFront (정적 리소스 배포)
   ↕
[SQLite Local DB] ←→ [서버 동기화 (Server Priority)]
```

---

## **6. MVP 범위 요약**

| 기능                             | 기술 스택                   | 포함 여부 |
| ------------------------------ | ----------------------- | ----- |
| SNS 로그인 (Google, Apple, Naver) | Spring Boot + OAuth 2.0 | ✅     |
| 프로필 관리                         | Spring Boot + RDS       | ✅     |
| 카탈로그 CRUD                      | FastAPI + DynamoDB      | ✅     |
| 아이템 CRUD                       | FastAPI + DynamoDB      | ✅     |
| 사용자 정의 필드                      | FastAPI (JSON Map 저장)   | ✅     |
| 이미지 업로드                        | S3 Signed URL           | ✅     |
| 오프라인 동기화                       | Flutter + SQLite        | ✅     |
| 검색/필터                          | (고도화 단계)                | 🚫    |
| 커뮤니티/공유                        | (차기 단계)                 | 🚫    |
| 자동 인식(OCR)                     | (차기 단계)                 | 🚫    |

---

## **7. 향후 확장 계획**

* OCR/이미지 인식 기반 자동 등록
* 사용자 간 컬렉션 공유 및 트레이드
* 고도화된 검색/필터(태그·메타데이터 기반)
* 통계 대시보드(카테고리별 수집률, 월별 수집 현황)
* Web/PWA 버전 확장

---

이 문서는 **‘카탈로깅(Collecting Companion App)’의 MVP 개발을 위한 최종 요구사항 정의서(PRD)**입니다.
본 버전은 오프라인 환경에서도 데이터 일관성을 유지하며,
AWS 클라우드 아키텍처를 기반으로 확장 가능한 구조를 목표로 합니다.