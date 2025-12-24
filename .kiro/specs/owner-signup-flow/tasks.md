# Implementation Plan

-
  1. [x] Create SignupPage with form validation
  - [x] 1.1 Create `signup_page.dart` with email, password, and confirm password
        fields
    - Use dark theme styling consistent with WelcomeScreen (black background,
      grey900 inputs)
    - Include form validation for all fields
    - Add password visibility toggles
    - Add loading state handling
    - _Requirements: 1.3, 3.1, 3.2, 3.3, 3.4_
  - [x] 1.2 Write property test for email validation
    - **Property 2: Invalid email format rejected**
    - **Validates: Requirements 5.2**
  - [x] 1.3 Write property test for password length validation
    - **Property 3: Short password rejected**
    - **Validates: Requirements 5.3**
  - [x] 1.4 Write property test for password match validation
    - **Property 4: Mismatched passwords rejected**
    - **Validates: Requirements 5.4**

-
  2. [x] Implement signup functionality
  - [x] 2.1 Add signup handler that calls `authRepository.signUp()`
    - Handle success by navigating to CreateHotelPage
    - Handle errors with appropriate snackbar messages
    - _Requirements: 1.4, 1.5_
  - [x] 2.2 Write property test for signup account creation
    - **Property 1: Valid signup creates account**
    - **Validates: Requirements 1.4**

-
  3. [x] Create CreateHotelPage for initial hotel setup
  - [x] 3.1 Create `create_hotel_page.dart` with hotel name, address, and floor
        configuration
    - Use dark theme styling consistent with signup flow
    - Include required field validation for name and address
    - Add floor/room configuration with sensible defaults
    - _Requirements: 2.2, 2.3, 5.5, 5.6_
  - [x] 3.2 Implement hotel creation handler
    - Call `SupabaseHotelSetupRepository.createHotel()` with owner ID
    - Create default rooms based on floor configuration
    - Navigate to owner dashboard on success
    - _Requirements: 2.4, 2.5_
  - [x] 3.3 Write property test for hotel creation
    - **Property 5: Valid hotel data creates hotel**
    - **Validates: Requirements 2.4**

-
  4. [x] Update WelcomeScreen and routing
  - [x] 4.1 Add "Sign Up" button to WelcomeScreen below the Sign In button
    - Use consistent styling with existing buttons
    - Navigate to `/signup` route on tap
    - _Requirements: 1.1, 1.2_
  - [x] 4.2 Add `/signup` and `/create-hotel` routes to app_router.dart
    - Add route constants
    - Add route definitions with appropriate transitions
    - _Requirements: 1.2, 2.1_

-
  5. [x] Checkpoint - Ensure signup flow works end-to-end
  - Ensure all tests pass, ask the user if questions arise.

-
  6. [x] Remove old hotel setup wizard
  - [x] 6.1 Delete `hotel_setup_wizard_page.dart`
    - _Requirements: 4.1_
  - [x] 6.2 Delete `owner_auth_step.dart` and `wizard_step_pages.dart`
    - _Requirements: 4.4_
  - [x] 6.3 Remove `/setup` route from app_router.dart
    - Remove route constant
    - Remove route definition
    - Remove import statement
    - _Requirements: 4.2, 4.3_
  - [x] 6.4 Verify no remaining references to deleted files
    - Search codebase for any imports or usages
    - Fix any broken references
    - _Requirements: 4.3_

-
  7. [x] Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
