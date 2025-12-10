# Check-in Feature

## Overview
Handles the guest check-in flow including customer information capture, payment processing, and booking confirmation.

## Structure
```
checkin/
├── data/
│   └── repositories/
│       └── checkin_repository.dart  # Check-in data operations
├── domain/
│   ├── entities/
│   │   └── checkin_data.dart        # Check-in form data entity
│   └── repositories/
│       └── checkin_repository.dart  # Repository interface
└── presentation/
    ├── pages/
    │   └── checkin_flow_page.dart   # Multi-step check-in wizard
    ├── providers/
    │   └── checkin_providers.dart   # Flow state management
    └── widgets/
        ├── step_confirmation.dart   # Final confirmation step
        ├── step_customer_info.dart  # Guest details capture
        └── step_payment.dart        # Payment collection
```

## Check-in Flow Steps
1. **Guest Information** - Capture customer details, ID scan (Aadhaar OCR)
2. **Payment** - Collect advance payment and payment mode
3. **Confirmation** - Review and confirm booking details

## Key Providers
- `checkinStateProvider` - StateNotifier for check-in flow state
- `currentCheckinDataProvider` - Provider for form data

## Usage
```dart
// Navigate to check-in with room
context.push(AppRoutes.checkin, extra: room);

// Complete check-in updates room status to 'occupied'
```

## UX Considerations
- Large touch targets (48x48 dp minimum)
- Clear step indicators with icons
- Inline error display near input fields
- Progress indicators during async operations
