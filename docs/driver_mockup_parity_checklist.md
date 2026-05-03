# Driver Mockup Parity Checklist

Mapping reference from `TricyKab/mockups/driver` to `Applications/driver_app/lib`.

## Screen Mapping

- `01-otp-login.html` → `features/auth/screens/otp_login_screen.dart`
  - Step 1 matches mockup (logo, Driver Portal, registered number card, TODA President footer).
  - Step 2 retains OTP send/verify for PRD-aligned auth (`Verify & Sign In`).
- `02-home.html` → `features/home/screens/home_screen.dart`
  - Profile, stats grid, weekly bars, quick links, bottom nav.
- `03-incoming-offer.html` → `features/offer/screens/incoming_offer_screen.dart`
  - Three-offer mock batch, offer badge with icon, per-card countdown (safe/warning/danger), trip distance + pickup rows, Accepted/Remaining summary, deferred navigation, special/shared validation dialogs, `arguments: true` return-to-pickup batch.
- `04-assigned-pickup.html` → `features/pickup/screens/assigned_pickup_screen.dart`
  - Dynamic Next Task / primary CTA cycle, waiting + onboard stacks, expandable booking rows (including ride type from queue), incoming-offer strip + Handle Now, map markers + route hint, pickup notes banner.
- `05-trip-in-progress.html` → `features/trip/screens/trip_in_progress_screen.dart`
  - Live elapsed timer, map markers + route segments, trip stats, per-passenger Complete, primary leg completion / End All, trip earnings strip (no SOS FAB for mockup parity).
- `06-add-passenger.html` → `features/trip/screens/add_passenger_screen.dart`
  - Green header, info banner, capacity + listed onboard sample, destination + notes, stepper 1–3, after-boarding preview, Cancel.
- `07-end-trip.html` → `features/complete/screens/end_trip_screen.dart`
  - Paid hero, collect subtitle, route + receipt summary, digital receipt strip, Done — Back to Home.

## State & Data

- Models: `features/driver_flow/domain/driver_flow_models.dart` (`DriverOffer` passenger + distance fields, `PickupLayout`, extended `DriverTripSummary`).
- Mock constants: `data/mock_data.dart` (`MockIncomingOffers`, `MockAssignedPickup`, `MockTripInProgress`, `MockEndTrip`, …).
- Controller: multi-accept queue, `returnToAssignedPickupAfterBatch`, pickup primary steps, `startTripPhaseFromPickup()`, trip leg completion.
- Repository: `fetchIncomingOffers(midAssignment:)`, `buildPickupFromAccepted`.

## Reusable Widgets

- `core/widgets/countdown_timer.dart` — ring colors aligned with mockup timers.
- Shared: `app_header`, `status_badge`, `map_placeholder`, `info_row`, `bottom_nav`.
