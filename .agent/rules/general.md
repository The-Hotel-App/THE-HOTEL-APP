---
trigger: always_on
---

# Custom Development Rules

## Reference Documents
- Always refer to DOCS/srs.md for requirements and specifications
- Always ensure best practices being adhered by referring DOCS/best_practices.md

## File Creation Restrictions
- Never create any summary documents or .ps1 or bash executable scripts UNLESS EXPLICITLY MENTIONED

## Supabase
- ALWAYS refer supabase-info.md
- ALWAYS update supabase-info.md wherever applicable

## Pushing to Main
For in app updates:
  - Change version and build number in pubspec.yaml (eg: 1.1.5+5 -> 1.1.6+6)
  - This will trigger GitHub actions(https://github.com/The-Hotel-App/THE-HOTEL-APP/actions)to complete (green tick mark)
  - Finally remind the user to change version number in app_version table in supabase to the latest version after the github actions job has run successfully.