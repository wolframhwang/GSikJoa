# G식좋아 — Build Notes

## Project layout
- `Project.swift` + `Tuist.swift` at repo root → run `tuist generate` here
- Workspace: `GsikJoa.xcworkspace`
- Modules: 4 Core (Domain · Data · DesignSystem · Utils) + 7 Features + App + 2 Test targets

## Content
`Modules/Core/Data/Resources/card_packs.json` — 21 packs / 105 cards. Validated by content sub-agent + `python3 -c "import json; json.load(...)"` smoke check.

## Implemented — ship-blocker pass

| Item | Status | Notes |
|---|---|---|
| App icon | ✅ | Icon A (G젤리/coral) for Light/Dark/Tinted. 1024×1024 PNG → Xcode auto-resizes. |
| Launch screen | ✅ | `UILaunchScreen` plist entry → `LaunchBackground` colorset (#E5F1F4 Ocean page). No white flash. |
| ko-only lock | ✅ | `defaultKnownRegions: ["ko"]` + `CFBundleAllowMixedLocalizations: false` + en.lproj 제거 |
| 변형 복습 | ✅ | `recommendedPacks` adds +30 score for packs containing user's weak concept tags. Surfaced via "약점 복습" badge on PackCardRow. |
| 이어풀기 | ✅ | `ActiveQuizSession` model + `UserDefaultsActiveSessionStore`. Quiz exit ✕ saves snapshot; Home shows "이어서 풀기" card if fresh (<24h). Resume seeds QuizViewModel at saved index. |
| Result 카피 거짓말 | ✅ | "다음 세션에서 변형 문제로 다시 만나요" → "이 개념이 들어간 카드팩을 다음에 위로 추천해요" (코드와 일치) |
| 개인정보처리방침 | ✅ | `PRIVACY.md` 한국어 초안. 호스팅 후 App Store Connect에 URL 입력 필요. |

## 외부에서 처리 필요한 것

### 실기기 테스트
시뮬레이터 빌드는 통과했지만 **실기기 검증이 안 끝났음**. App Store 제출 전 본인 iPhone에서 다음 항목 확인:

- [ ] 노치/Dynamic Island 안전영역 (Onboarding/Home/Quiz 상단 잘림 없음)
- [ ] 홈 인디케이터 영역 (Bottom tab bar가 가리지 않는지)
- [ ] Dynamic Type — 설정 > 디스플레이 > 텍스트 크기 최대로 했을 때 레이아웃 깨지는 곳 (특히 PackCardRow)
- [ ] 다크 모드 (Project.swift는 Light로 강제하므로 잠금 확인)
- [ ] 회전 (UIRequiresFullScreen 미설정 → iPad/회전 시 동작)
- [ ] 한글 폰트 폴백 — 실기기에서 SF Pro Rounded가 한글 글리프를 어떻게 그리는지 (시뮬레이터와 다를 수 있음)
- [ ] Quiz 중간 ✕ 종료 → Home에 "이어서 풀기" 카드 뜨는지
- [ ] 24시간 후 "이어서 풀기" 카드 사라지는지 (시뮬레이터 시간 조작으로도 가능)
- [ ] 오답 → Result → Home → 추천 카드팩 위에 "약점 복습" 배지 뜨는지

빌드 + 배포:
```bash
cd /Users/volganovski/Desktop/gsik/GSikJoa
tuist generate
# Xcode에서 본인 Apple ID 팀 선택 → 실기기 연결 → ▶ Run
```

### 개인정보처리방침 호스팅
`PRIVACY.md` 작성 완료. 호스팅 옵션:
- GitHub Pages: repo 내 `/docs` 폴더에 마크다운 → `https://wolframhwang.github.io/GSikJoa/`
- Notion 페이지 publish → 짧은 URL
- 본인 도메인이 있으면 거기 업로드

App Store Connect → App Information → Privacy Policy URL에 입력.

### App Store Connect 메타데이터
- App 이름: G식좋아
- Subtitle (30자): "한 입에 씹어먹는 경제·물리·통계"
- Description: BUILD_NOTES와 PRIVACY 참고해서 작성
- 키워드: 퀴즈, 경제, 물리, 통계, 학습, 지식, 베이즈, 금리, 채권
- 카테고리: Education
- 심사 등급: 4+ (모든 연령)
- Privacy nutrition labels: "Data Not Collected" 단일 항목으로 체크

### 스크린샷
이미 `~/Desktop/gsikjoa_screenshot_01..06.png`에 저장됨 (1290×2796, App Store 6.7" 규격). 6.5"용은 자동으로 같은 이미지 재사용 가능 또는 별도 생성.

## Known follow-ups (post-launch)

- 커스텀 한글 폰트(Jua, Pretendard) `.otf` 번들링 — `AppFont.swift`는 이미 폴백 로직 가짐
- 같은 `topicId`의 L1·L2·L3 변형 카드 추가 (현재 0/21 토픽이 다중 난이도) — 변형 복습 효과를 더 강화
- 콘텐츠 200문제까지 양산 (PDF §16 4주차 목표)
- Settings에 진행 데이터 초기화 버튼 (개인정보처리방침 명시 위해)
