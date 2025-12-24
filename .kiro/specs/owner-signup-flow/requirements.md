# Requirements Document

## Introduction

This feature adds a signup flow for new hotel owners on the ROOMS.io app.
Currently, the welcome screen only allows existing users to sign in. New hotel
owners need a way to create an account, provide their credentials, and set up
their first hotel. This feature will add a "Sign Up" button to the welcome
screen that initiates a streamlined owner registration and hotel creation flow.

Additionally, this feature will remove the old, unused `HotelSetupWizardPage`
which is overly complex and redundant.

## Glossary

- **Owner**: A user who owns and manages one or more hotels in the system.
  Owners have full administrative access to their hotels.
- **Welcome Screen**: The initial screen shown when the app opens
  (`WelcomeScreen`), containing the login form.
- **Signup Flow**: The multi-step process for new owners to create an account
  and their first hotel.
- **Hotel Setup**: The process of configuring a new hotel with basic
  information, floors, and rooms.

## Requirements

### Requirement 1

**User Story:** As a new hotel owner, I want to sign up for an account from the
welcome screen, so that I can start using ROOMS.io to manage my hotel.

#### Acceptance Criteria

1. WHEN the welcome screen loads THEN the system SHALL display a "Sign Up"
   button below the "Sign In" button
2. WHEN a user taps the "Sign Up" button THEN the system SHALL navigate to a
   signup page
3. WHEN on the signup page THEN the system SHALL display email and password
   input fields with confirmation
4. WHEN a user submits valid signup credentials THEN the system SHALL create a
   new user account with the "owner" role
5. IF a user submits an email that already exists THEN the system SHALL display
   an appropriate error message

### Requirement 2

**User Story:** As a new hotel owner completing signup, I want to create my
first hotel immediately after account creation, so that I can start managing my
property right away.

#### Acceptance Criteria

1. WHEN account creation succeeds THEN the system SHALL navigate to a hotel
   creation page
2. WHEN on the hotel creation page THEN the system SHALL display fields for
   hotel name and address (required) and optional fields for phone and email
3. WHEN on the hotel creation page THEN the system SHALL display floor
   configuration options with room ranges
4. WHEN a user submits valid hotel information THEN the system SHALL create the
   hotel and associate it with the owner
5. WHEN hotel creation succeeds THEN the system SHALL navigate to the owner
   dashboard

### Requirement 3

**User Story:** As a developer, I want the signup UI to match the existing app
theme, so that the user experience is consistent.

#### Acceptance Criteria

1. WHILE displaying the signup page THEN the system SHALL use the dark theme
   (black background) consistent with the welcome screen
2. WHILE displaying form inputs THEN the system SHALL use the same input styling
   as the welcome screen (grey900 fill, grey600 border, info color focus)
3. WHILE displaying buttons THEN the system SHALL use the same button styling as
   the welcome screen (info color primary, rounded corners)
4. WHEN displaying loading states THEN the system SHALL show a circular progress
   indicator matching the existing style

### Requirement 4

**User Story:** As a developer, I want to remove the old hotel setup wizard, so
that the codebase is cleaner and there's no confusion about which flow to use.

#### Acceptance Criteria

1. WHEN the cleanup is complete THEN the system SHALL have removed the
   `HotelSetupWizardPage` file
2. WHEN the cleanup is complete THEN the system SHALL have removed the `/setup`
   route from the router
3. WHEN the cleanup is complete THEN the system SHALL have removed any imports
   or references to the deleted wizard
4. WHEN the cleanup is complete THEN the system SHALL have removed the
   wizard-related widget files (`owner_auth_step.dart`,
   `wizard_step_pages.dart`)

### Requirement 5

**User Story:** As a user, I want proper form validation during signup, so that
I don't accidentally create an account with invalid data.

#### Acceptance Criteria

1. WHEN a user submits an empty email field THEN the system SHALL display
   "Please enter your email" error
2. WHEN a user submits an invalid email format THEN the system SHALL display
   "Please enter a valid email" error
3. WHEN a user submits a password shorter than 6 characters THEN the system
   SHALL display "Password must be at least 6 characters" error
4. WHEN a user submits mismatched passwords THEN the system SHALL display
   "Passwords do not match" error
5. WHEN a user submits an empty hotel name THEN the system SHALL display "Hotel
   name is required" error
6. WHEN a user submits an empty address THEN the system SHALL display "Address
   is required" error
