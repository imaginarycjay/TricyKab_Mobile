# Backend API mapping (TricyKab driver flow)

This document links the Flutter [`DriverFlowRepository`](../lib/features/driver_flow/data/driver_flow_repository.dart) to the Laravel JSON API under `/api/v1`. The **HTTP implementation** is [`HttpDriverFlowRepository`](../lib/features/driver_flow/data/http_driver_flow_repository.dart), selected when the app is built with a non-empty base URL:

```bash
flutter run --dart-define=TRICYKAB_API_BASE=http://10.0.2.2:8000/api/v1
```

(Use your host IP or `localhost` for iOS/desktop; Android emulator uses `10.0.2.2` to reach the host machine.)

All successful responses use the shared [`ApiResponse`](../../../TricyKab/app/Http/Responses/ApiResponse.php) envelope: `{ "success": true, "data": { ... } }`. Errors: `{ "success": false, "error": { "code", "message", "details?" } }`.

## Auth (OTP)

| Repository method | HTTP | Notes |
|-------------------|------|--------|
| `requestOtp(phone)` | `POST /api/v1/auth/otp/request` | `phone_number`, `role_hint: "DRIVER"` |
| `verifyOtp(phone, code)` | `POST /api/v1/auth/otp/verify` | Returns Sanctum `access_token`; use `Authorization: Bearer` on subsequent calls. Driver scopes include `availability:update:self`, `booking:read:self`, `booking:offer:read:self`, `booking:accept:self`, `booking:decline:self`, `trip:start:self`, `trip:end:self`, `trip:update:self`, `passenger:add:self`, `payment:record:self`. |

## Online / offline toggle

| Repository method | HTTP | Notes |
|-------------------|------|--------|
| `updateAvailability(bool online)` | `POST /api/v1/drivers/me/availability` | Body: `driver_status`: `"ONLINE"` \| `"OFFLINE"`, optional `latitude`, `longitude`, `accuracy_meters`. Only **ONLINE** drivers receive new dispatch candidates. |

## Incoming offers (carousel)

| Repository method | HTTP | Notes |
|-------------------|------|--------|
| `fetchIncomingOffers(midAssignment:)` | `GET /api/v1/drivers/me/dispatch-offers` | Returns `data.offers[]`. Each offer includes `candidate_id`, `dispatch_attempt_id`, `expires_at`, **`countdown_seconds`**, **`distance_meters`**, `rank_order`, **`booking`** (passenger display + pickup/destination + fare estimates), and **`display`** (`pickup_distance`, `estimated_distance`, `estimated_duration`). |

**Accept / decline** (also used by Blade driver webapp when a token is present):

- `POST /api/v1/drivers/bookings/{booking}/accept` — JSON body: `dispatch_attempt_id`, `candidate_id`. Success includes **`trip_id`** (PRE_START trip row).
- `POST /api/v1/drivers/bookings/{booking}/decline` — JSON body: `dispatch_attempt_id`, `candidate_id`, **`reason_code`** (e.g. `TOO_FAR`).

Multi-offer UX in Flutter may queue several accepts client-side; each accept assigns **one** booking on the server.

## Pickup stacks (`buildPickupFromAccepted`)

| Repository method | HTTP | Notes |
|-------------------|------|--------|
| `buildPickupFromAccepted(accepted)` | *(client-side layout)* | HTTP repo builds a local `PickupLayout` from accepted `DriverOffer` rows. |
| Refresh assignments | `GET /api/v1/drivers/me/bookings` | `data.bookings[]` — driver API shape. Optional `?active=1`. |
| Detail | `GET /api/v1/drivers/me/bookings/{booking}` | 403 if not assigned to this driver. |

## Trip lifecycle (PRD §9.5) — `HttpDriverFlowRepository`

| Step | HTTP |
|------|------|
| Arrive at pickup | `POST /api/v1/drivers/trips/{trip}/arrive` — `latitude`, `longitude`, optional `accuracy_meters` |
| Start trip | `POST /api/v1/drivers/trips/{trip}/start` — same geo fields, optional `started_at_client` |
| Add walk-ins | `POST /api/v1/drivers/trips/{trip}/add-passengers` — `quantity`, optional `notes` |
| Location ping | `POST /api/v1/drivers/trips/{trip}/location` — periodic GPS |
| End trip | `POST /api/v1/drivers/trips/{trip}/end` — `latitude`, `longitude` at drop-off, optional `ended_at_client`, `manual_reason` |

`completeTrip` in the HTTP repository runs **arrive → start → end** with coordinates from the accepted offer, then:

| Step | HTTP |
|------|------|
| Record cash + receipt | `POST /api/v1/payments/{booking}/record` — `amount`, `method` (e.g. `CASH`), `recorded_by_role`, optional `notes` |

Response includes `data.receipt.receipt_number` and immutable `payload` snapshot.

## Passenger-side (reference for a future passenger repository)

- `GET /api/v1/bookings/{booking}/trip-tracking` — live booking, driver summary, trip, last `trip_location_logs` point.
- `GET /api/v1/bookings/{booking}/receipt` — requires `receipt:read:self`.
- `POST /api/v1/passenger/sos` — `booking_id` optional, `latitude`, `longitude`, optional `notes`.

## Realtime (optional)

- Trip mutations queue [`FirebaseMirrorJob`](../../../TricyKab/app/Jobs/FirebaseMirrorJob.php) when `FIREBASE_PROJECTION_ENABLED=true` (see `TricyKab/config/services.php`).

---

**Summary:** Use `HttpDriverFlowRepository` with `TRICYKAB_API_BASE` for end-to-end driver flow; keep `MockDriverFlowRepository` for UI work without a backend. The Blade **driver** webapp (`TricyKab/resources/views/webapp/driver.blade.php`) can use the same endpoints with a pasted Sanctum token (dev/demo path).
