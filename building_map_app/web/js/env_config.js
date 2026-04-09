// 환경별 설정 파일
// - 로컬 개발: 이 파일이 기본값으로 사용됨 (git 추적)
// - 테스트/운영 배포: CI/CD가 이 파일을 환경별 값으로 덮어씀
window.__ENV__ = {
  // 환경 식별
  ENVIRONMENT: 'local',

  // Kakao
  KAKAO_JS_KEY: '5e2b60c33562fb4806fde94853956642',
  KAKAO_REST_API_KEY: 'e68e331e3c2fd104aa8d7194f7c3a066',

  // Firebase
  FIREBASE_API_KEY: 'AIzaSyBDwxJU7ivdjfdMOJeA7N_buRjdJLfdKUs',
  FIREBASE_AUTH_DOMAIN: 'ezstay-864bc.firebaseapp.com',
  FIREBASE_PROJECT_ID: 'ezstay-864bc',
  FIREBASE_STORAGE_BUCKET: 'ezstay-864bc.firebasestorage.app',
  FIREBASE_MESSAGING_SENDER_ID: '922042336723',
  FIREBASE_APP_ID: '1:922042336723:web:054fdbcc6b9b219aed1b26',
  FIREBASE_MEASUREMENT_ID: 'G-1QZK8YMFEV',

  // PayTag
  PAYTAG_SHOPCODE: '1901110002',
  PAYTAG_SDK_URL: 'https://apit.paytag.kr/std_pay/paytag_std.js?version=20251104',
};
