# 💰 App Save Money

แอพจัดการรายรับรายจ่าย — อ่าน Slip อัตโนมัติ จัดหมวดหมู่ด้วย Keywords และ Tinder Swipe UI

## Features

- 📸 **Slip Import** — ดึง Slip จาก Gallery เลือกได้ว่าจะเริ่มจากเดือนไหน
- 🔍 **Auto OCR** — อ่านข้อมูลจาก Slip อัตโนมัติ (On-device)
- 🏷️ **Smart Categorize** — จัดหมวดหมู่อัตโนมัติด้วย Keywords ที่กำหนดเอง
- 💘 **Tinder Swipe** — ปัดซ้าย/ขวาเพื่อจัด Slip ที่ยังไม่มีหมวดหมู่
- 📊 **Dashboard** — สรุปรายจ่ายรายเดือนแยกตามหมวดหมู่

## Tech Stack

- **Mobile**: Flutter (iOS + Android)
- **Backend**: Supabase (Auth + PostgreSQL + Storage)

## Development

### Branches
- `main` — production ready เท่านั้น
- `develop` — integration branch
- `feature/*` — feature branches

### Workflow
ทุก feature ต้องเปิด PR เข้า `develop` ก่อนเสมอ ห้าม push ตรง `main`

## Project Structure

```
lib/
├── core/
│   ├── config/        # App config, Supabase keys
│   ├── router/        # App navigation
│   └── theme/         # Colors, typography
├── features/
│   ├── auth/          # Login / Register
│   ├── slip/          # Import + OCR
│   ├── categories/    # Category management
│   ├── swipe/         # Tinder swipe UI
│   └── dashboard/     # Summary charts
└── shared/
    ├── models/        # Data models
    ├── widgets/       # Shared widgets
    └── services/      # Supabase services
```
