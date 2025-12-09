# BEST_PRACTICES.md — Flutter frontend & screens (project-wide)

> A concise, strict set of best-practice rules for the Hotel App frontend (Flutter). Focus: code structure, screens, UI, state, performance, testing and security for biometric workflows.

---

## 1. Purpose
Provide a single source of truth for frontend engineering decisions so the team ships maintainable, secure, and high-performance Flutter screens that match the SRS goals (real-time, biometric gating, low-literacy UX).

## 2. High-level principles
- **Readable & consistent**: follow Effective Dart style and `dart format` everywhere.
- **Feature-first, layered responsibilities**: group code by feature, but keep a clear separation between presentation, domain (business logic), and data layers.
- **Immutable state & typed models**: prefer immutable data classes and generated serialization.
- **Small widgets**: prefer many small, testable widgets over one giant widget tree.
- **Security-first for biometrics**: biometric templates live encrypted; biometric matching always on-device.
- **Backend-agnostic**: All backend interactions abstracted behind repository interfaces for easy switching between Supabase/AWS.

---

## 3. IMPLEMENTED Project structure (feature-first, scalable)
```
lib/
├─ src/
│  ├─ core/                # app-wide utilities, theme, constants, exceptions
│  │  ├─ config/           # Environment configuration
│  │  ├─ routing/          # GoRouter configuration and route guards
│  │  ├─ theme/            # AppTheme and design tokens
│  │  ├─ constants/        # AppConstants, AppColors, etc.
│  │  ├─ error/            # Error handling and failures
│  │  └─ network/          # HTTP client abstractions
│  ├─ shared/              # reusable widgets, form inputs, icons, design tokens
│  │  └─ widgets/          # Shared UI components
│  ├─ features/
│  │   ├─ auth/
│  │   │   ├─ data/        # DummyAuthRepository, future: SupabaseAuthRepository
│  │   │   │   └─ repositories/
│  │   │   ├─ domain/      # User entity, UserRole enum, AuthRepository interface
│  │   │   │   ├─ entities/
│  │   │   │   └─ repositories/
│  │   │   └─ presentation/# LoginPage, HomePage, AuthProviders (Riverpod)
│  │   │       ├─ pages/
│  │   │       └─ providers/
│  │   ├─ hotel_setup/     # Hotel setup wizard flow
│  │   │   ├─ data/
│  │   │   ├─ domain/      # Hotel, RoomType entities
│  │   │   │   └─ entities/
│  │   │   └─ presentation/
│  │   ├─ rooms/           # Room grid, status management
│  │   │   ├─ data/
│  │   │   ├─ domain/      # Room entity, RoomStatus enum
│  │   │   │   └─ entities/
│  │   │   └─ presentation/
│  │   └─ bookings/        # Customer onboarding, booking management
│  │       ├─ data/
│  │       ├─ domain/
│  │       └─ presentation/
│  ├─ app.dart             # RoomsApp widget with MaterialApp.router
│  └─ main.dart            # App entry with ProviderScope
├─ assets/
│  ├─ images/
│  └─ icons/
```

### Current Implementation Status:
✅ Core structure created
✅ Theme system with AppColors (room status colors)
✅ GoRouter with auth redirect logic
✅ Riverpod state management setup
✅ Dummy authentication with hardcoded users
✅ Login page with demo credentials
✅ Home page with role-based quick actions
✅ Feature-first architecture with data/domain/presentation layers

---

## 4. Packages & dependency rules - IMPLEMENTED
**Chosen packages for MVP:**
- ✅ **State Management**: `flutter_riverpod` ^2.6.1 with `riverpod_annotation` for code generation
- ✅ **Routing**: `go_router` ^14.6.2 with auth-based redirects
- ✅ **Storage**: `shared_preferences` ^2.3.4, `flutter_secure_storage` ^9.2.2 (tokens, flags)
- ✅ **Network**: `dio` ^5.7.0 (ready for backend integration)
- ✅ **Forms**: `flutter_form_builder` ^10.2.0, `form_builder_validators` ^11.0.0
- ✅ **Biometrics**: `local_auth` ^2.3.0 (prepared, not yet implemented)
- ✅ **Images**: `image_picker` ^1.1.2, `cached_network_image` ^3.4.1 (for ID photos)
- ✅ **Code Gen**: `freezed`, `json_serializable`, `build_runner` (ready for use)

**Dependency Lock Policy:**
- Lock major packages in `pubspec.yaml` and run `dart pub upgrade --major-versions` only on planned updates.
- Prefer well-maintained, null-safe packages.
- **Backend agnostic**: No direct Supabase/AWS SDK imports in domain/presentation layers - only in data layer repositories.

---

## 5. State management (strict rules) - IMPLEMENTED
- ✅ Using **Riverpod** for DI-friendly state management
- ✅ Provider/testability without `BuildContext`
- ✅ Clear separation: UI -> ViewModel/Notifier -> Repository -> DataSource
- State types:
  - `StreamProvider` for auth state and real-time data
  - `FutureProvider` for async operations
  - `StateNotifier` / `Notifier` for complex flows (to be added as needed)
  - `AsyncValue<T>` wrappers for loading/error/data states
- Keep ephemeral UI state (form fields, local controllers) inside the widget or a `StateProvider` only if necessary.

**Example Implementation:**
```dart
// Provider for repository (swappable)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return DummyAuthRepository(); // Switch to SupabaseAuthRepository later
});

// Stream provider for current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.watchAuthState();
});
```

---

## 6. UI & Screen rules (low-literacy UX focus)
- Use a grid-first approach for the Room Grid screen; it must load < 1s on stable network.
- Use large, consistent icons + one-line labels; color is primary indicator but always include an icon and short text.
- Accessibility:
  - Minimum touch target: 48x48 dp.
  - High contrast icons/text; support system font scaling.
- Navigation:
  - Use declarative, named routes (e.g. `GoRouter` or `AutoRoute`).
  - Keep deep linkable screens and pass only serializable arguments.
- Screen composition:
  - Compose screens from `Header`, `Body`, `Fab/PrimaryAction`, and `BottomBar` small widgets.
  - Every screen file should be < 400 lines; extract subparts to `widgets/` if larger.

---

## 7. Widgets & rendering
- Favor `const` constructors wherever possible.
- Use `RepaintBoundary` around heavy visual subtrees (room grid, charts).
- Avoid large `setState` scope — prefer `StateNotifier`/`Provider` updates or smaller `StatefulWidget`s.
- Use `ListView.builder` / `GridView.builder` for large lists; provide stable keys where items can reorder.
- Use `CachedNetworkImage` (or similar) for id photos and room photos; enforce size limits and placeholders.

---

## 8. Data models & serialization
- Use `freezed` + `json_serializable` for all DTOs and domain models (immutable, copyWith, equalities).
- Keep mapping logic in the `data` layer. Convert DTOs to domain models before use in `domain` and `presentation` layers.
- Avoid `dynamic`/`Map` in the widget layer—use typed models.

---

## 9. Networking & realtime
- Abstract the backend behind a `Repository` interface. Example: `EmployeeRepository`, `BookingRepository`.
- Realtime: keep an adapter that exposes streams to business logic; UI subscribes to riverpod providers.
- If using Supabase SDK later, wrap it in a `SupabaseDatasource` implementing the `RemoteDataSource` interface.
- Retry/backoff: centralize network retry and error mapping in the data layer.

---

## 10. Biometric workflows & security (critical)
- **On-device biometric matching only**; never transmit raw templates. Store only encrypted templates if persistent storage is needed.
- Define a `BiometricService` interface:
  - `Future<bool> verify(template, sample)` — implemented by native plugin and used only in `domain` layer.
- All sensitive actions must pass through a `BiometricAuthorizer` use-case which: checks match, writes `biometric_audit_log`, and returns an authorization token for the action.
- Audit log: store `biometric_user_id`, `session_user_id`, action, timestamp in a single transaction with the change.

---

## 11. Error handling & user feedback
- Centralize error types and map exceptions to user-friendly messages in the presentation layer.
- Use toasts/snackbars sparingly; prefer inline error UI near the action for low-literacy users.
- Show progress states (indeterminate) for fingerprint scanning and network calls.

---

## 12. Testing policy
- Unit tests for domain logic and repositories (mock data sources).
- Widget tests for each screen's main flows (check-in, checkout, cleaning flow).
- Integration (end-to-end) tests for crucial end-to-end flows (onboard ≤20 seconds, biometric gating).
- CI: run `dart analyze`, `flutter test` and `flutter format --set-exit-if-changed` on every PR.

---

## 13. Linting & code style
- Use `analysis_options.yaml` with `package:pedantic`/`package:lint` or `dart_code_metrics` rules favored by the team.
- Enforce `dart format` and `flutter_lints` in CI.

---

## 14. CI / Release
- CI steps: analyze, test, build (apk/aab), code-sign (secure secrets), static asset validation.
- Use semantic version tags and CHANGELOG.md. Keep releases small and focused for MVP.

---

## 15. Performance checklist
- Use `const`, small widgets, avoid rebuilds.
- Profile with Flutter DevTools before optimization.
- Lazy-load images & data, paginate lists.
- Keep room grid initial payload small: only fields visible on the grid.

---

## 16. Logging & observability
- Centralized logger that can be toggled per environment.
- Capture structured events for: check-in/out, payments, biometric verification success/failure.
- Ensure logs never contain raw biometric data or PII; mask sensitive fields.

---

## 17. Documentation
- Every feature must include a short README.md under `lib/src/features/<feature>/README.md` describing contracts and public providers.
- Maintain an architecture decision record (ADR) for major choices (state mgmt, routing, backend choice).

---

## 18. Migration & backend-agnostic rules
- All backend calls must go through repository interfaces; provide a `MockRepository` used by dev/test and `SupabaseRepository` or `AwsRepository` for production.
- Keep backend-specific models inside `data/` folder; expose domain models to the rest of the app.

---

## 19. Onboarding & UX performance target
- Keep onboarding flow (scan ID → fingerprint → confirm → payment) under 20s. Measure this in e2e tests and instrument metrics in production builds.

---

## 20. Quick checklist for PR review
- Is code readable, formatted, lint-clean?
- Are new screens < 400 lines and composed of smaller widgets?
- Is business logic inside `domain`/`data`, not inside widgets?
- Are models immutable and typed?
- Are sensitive actions gated by `BiometricAuthorizer` and logged?

---

End of BEST_PRACTICES.md

