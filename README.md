## 도로명 주소 -> 위도/경도 받아오기(Nominatim API 활용)
<img width="404" alt="image" src="https://github.com/user-attachments/assets/ebfb6eca-ffeb-4532-b51a-447923ec6925" />

#### Opportunity의 도로명 주소 필드가 입력/수정될때마다 Nominatim API 호출을 통해서 위도/경도 값을 받아서 위치(geolocation field)값을 수정합니다.
성공 여부에 따라서 지오코딩 상태 필드 업데이트(성공/대기중/실패)

### 1. 사용한 커스텀 필드
<img width="504" alt="image" src="https://github.com/user-attachments/assets/a3545717-b1b9-40c4-9d4e-5ca87e23503d" />

### 2. Remote Site 세팅
<img width="438" alt="image" src="https://github.com/user-attachments/assets/354f5b53-2d57-4036-95a4-da5bbf5744bf" />

1) Setup -> (Quick Find) Remote Site Setting -> new
2) 설정
- Remote Site URL: https://nominatim.openstreetmap.org
- Active 체크


