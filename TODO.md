# Master Remediation TODO List

## 1. Security & Environment (High Priority)
- [x] Provide instructions to remove .env and serviceAccountKey.json from Git history
- [x] Create .env.example template for backend
- [ ] Update Flutter api_constants.dart with environment-based configuration

## 2. Backend Infrastructure & Routing
- [ ] Add npm scripts (start, dev) to package.json
- [ ] Consolidate registration logic - remove duplicate registerClient from clientController
- [ ] Implement robust logout with token invalidation in authController
- [ ] Implement RBAC: restrict POST /services to admin/repairman roles

## 3. Flutter Architecture Refactoring
- [ ] Refactor signup_user.dart to use ApiService instead of direct http calls
- [ ] Update api_service.dart to use api_constants.dart for baseUrl
- [ ] Ensure consistent base URL across the app

## 4. Feature Implementation (Code Scaffolding)
- [ ] Create Rating/Review system (backend schema and controller)
- [ ] Create real-time booking status (WebSocket/Firebase)
- [ ] Outline Search/Filter UI logic
- [ ] Outline Profile management screen
- [ ] Outline Booking status listener

---

## Implementation Status:
- [ ] NOT STARTED
