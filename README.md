# MirrorCam

macOS 메뉴바에 상주하는 경량 웹캠 미러 앱. 글로벌 단축키 한 번으로 플로팅 PIP 미러를 띄우고 닫을 수 있다.

## Download

**[MirrorCam v1.0.0](https://github.com/sijinyu/MirrorCam/releases/tag/v1.0.0)** — DMG 다운로드 (1.9MB, macOS 13+)

> unsigned 앱이므로 처음 실행 시 우클릭 → 열기 한 번 필요

## Features

- 원형 / 둥근 사각형 미러 윈도우 (항상 최상위)
- 볼록 / 오목 미러 효과
- 흑백 / 세피아 컬러 필터
- 스크린샷 (PNG) + 영상 녹화 (MP4)
- 셀프 타이머 (3초 / 5초 / 10초)
- 드래그 이동, 스크롤 리사이즈 (100~600px)
- 밝기 / 줌 조절
- 프리즈 모드
- Launch at Login (SMAppService)
- 메뉴바 전용 (Dock 아이콘 없음)

## Shortcuts

| Key | Action |
|-----|--------|
| ⌥⌘G | 미러 토글 |
| ⌥⌘S | 스크린샷 |
| ⌥⌘R | 녹화 시작/중지 |
| ⌥⌘F | 프리즈/해제 |
| 스크롤 | 미러 리사이즈 |

## Install

1. [Releases](https://github.com/sijinyu/MirrorCam/releases/tag/v1.0.0)에서 `MirrorCam.dmg` 다운로드
2. DMG 열기 → `MirrorCam.app`을 Applications 폴더로 드래그
3. 처음 실행 시: 우클릭 → 열기 (한 번만 필요)
4. 메뉴바에 카메라 아이콘 확인 → ⌥⌘G로 미러 토글

## Build from Source

```bash
# Requirements: macOS 13+, Swift 5.9+
git clone https://github.com/sijinyu/MirrorCam.git
cd MirrorCam

swift build && .build/debug/MirrorCamApp     # 디버그 실행
swift test                                    # 테스트 (40개)
scripts/build-app.sh                          # .app 번들 + DMG 생성
```

## System Requirements

- macOS 13.0 (Ventura) 이상
- 카메라 접근 권한

## Architecture

Swift Package (swift-tools-version 5.9) — AppKit + AVFoundation + CoreImage + Combine

| Module | Role |
|--------|------|
| CameraManager | AVCaptureSession 라이프사이클, DI via protocols |
| ImageProcessor | Stateless CIImage 파이프라인 (flip, brightness, zoom, effects) |
| SettingsStore | UserDefaults 기반 설정 저장 |
| MirrorWindow | Floating NSPanel + fade 애니메이션 |
| MirrorContentView | Shape clipping, drag, scroll resize |
| MenuBarController | NSStatusItem + NSMenu + SMAppService |
| ScreenRecorder | Screenshot (PNG) + Video (MP4) + UNUserNotificationCenter |
| HotkeyManager | 글로벌 단축키 (NSEvent) |
| CountdownTimer | 셀프 타이머 |

## Privacy

- 카메라는 미러 윈도우가 보일 때만 활성화
- 데이터는 기기 밖으로 나가지 않음
- 분석/추적 없음

## License

Copyright 2026. All rights reserved.

---

<details>
<summary>Original PRD (개발 초기 기획)</summary>

## Problem Statement

macOS 사용자가 화상 회의, 프레젠테이션, 또는 외출 전에 빠르게 자신의 모습을 확인하고 싶을 때, 기존 방법(Photo Booth 실행, FaceTime 열기 등)은 전체 앱을 열어야 하고 화면을 많이 차지한다. 단축키 한 번으로 작은 거울 창을 띄우고 바로 닫을 수 있는 경량 도구가 필요하다.

## User Stories

1. ⌥⌘G로 즉시 얼굴 확인
2. 모든 창 위에 플로팅
3. 원형/사각형 선택
4. 드래그로 위치 이동
5. 100~600px 리사이즈
6. 좌우 반전 (기본 ON)
7. 반전 토글
8. 밝기 조절
9. 줌 인/아웃
10. 설정 자동 저장
11. 로그인 시 자동 실행
12. 메뉴바 드롭다운 설정
13. 카메라 권한 요청
14. 단축키 커스터마이즈
15. 최소 CPU/배터리 사용
16. 숨기면 카메라 중지
17. 부드러운 show/hide 애니메이션

</details>
