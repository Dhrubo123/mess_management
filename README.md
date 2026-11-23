# MessMate BD — Bachelor Mess Management & To-Let Finder

Monorepo for a Bangladesh-focused Bachelor Mess Management & Vacant Seat / To-Let Finder platform.

## Project Structure

- `backend/` — Laravel 13 REST API + Sanctum token authentication + SQLite/MySQL database
- `mobile/` — Flutter Android/iOS mobile app (Bangla + English ready)

## Core Features (Phase 1 + Phase 2)

### Phase 1: Mess Management
- Phone/email registration & login (Sanctum API tokens)
- Create a mess & join via 6-character invite code
- Daily meal tracking (Breakfast, Lunch, Dinner, Guest meals) with cutoff-time enforcement
- Bazar (grocery) expense logging & member deposit tracking (Cash, bKash, Nagad, Bank)
- Fixed bills splitting (Rent, Wi-Fi, Bua, Gas, Electricity, Water)
- Live monthly calculation: Total Meals, Meal Rate, Per-Member Meal Cost, Fixed Bill Share, Total Payable/Refundable
- 1-Tap Manager Handover (transfer monthly manager role without losing history)
- Formatted WhatsApp/Messenger monthly summary generator (Bangla & English)

### Phase 2: Bachelor Seat / To-Let Finder
- Browse & filter vacant bachelor seats by city, area, budget, seat type, and gender
- Verified badge for listings posted by active messes on the platform
- Post, update, and mark seats as filled directly from the app
- Featured listing support for monetization (bKash/Nagad boost ready)

## Running Locally

### Backend (Laravel)
```powershell
cd F:\laragon\www\mess_management\backend
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

### Mobile (Flutter)
```powershell
cd F:\laragon\www\mess_management\mobile
flutter run
```
> Note: On Android Emulator, the API base URL defaults to `http://10.0.2.2:8000/api`. For a physical phone on the same Wi-Fi, update `ApiConfig.baseUrl` in `mobile/lib/config/api_config.dart` to your PC's LAN IP.
