# SkillResy Flutter Project Guidelines

## Architecture & Best Practices

### State Management
- **Use Riverpod** for all state management
- Prefer `ConsumerWidget` and `ConsumerStatefulWidget` over regular widgets
- Use proper provider types:
  - `Provider` for simple values
  - `StateProvider` for simple state
  - `StateNotifierProvider` for complex state
  - `FutureProvider` for async operations
  - `StreamProvider` for streams

### Project Structure (Simplified)
```
lib/
├── config/
│   ├── app_theme.dart
│   └── app_router.dart
├── constants/
│   ├── app_colors.dart
│   ├── app_strings.dart
│   └── app_sizes.dart
├── models/
│   └── user_model.dart
├── providers/
│   ├── auth_provider.dart
│   └── app_state_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   └── home/
│       └── home_screen.dart
├── services/
│   ├── api_service.dart
│   └── storage_service.dart
├── utils/
│   ├── validators.dart
│   └── helpers.dart
├── widgets/
│   ├── common/
│   │   ├── custom_button.dart
│   │   └── custom_text_field.dart
│   └── auth/
│       └── auth_form.dart
└── main.dart
```

### Coding Standards

1. **DRY Principle (Don't Repeat Yourself)**
   - Create reusable widgets for repeated UI patterns
   - Extract common functionality into shared utilities
   - Use composition over duplication

2. **Separation of Concerns**
   - Business logic in providers/controllers
   - UI logic in widgets
   - Data operations in repositories
   - API calls in datasources

3. **Widget Best Practices**
   - Create reusable widget components
   - Keep widgets small and focused
   - Use `const` constructors where possible
   - Extract repeated UI patterns into custom widgets

4. **State Management Rules**
   - Never use setState() - use Riverpod providers instead
   - Keep providers in separate files
   - Use proper provider naming: `featureNameProvider`
   - Dispose providers properly

5. **Error Handling**
   - Use Result/Either pattern for error handling
   - Handle all possible error states in UI
   - Show user-friendly error messages

6. **Navigation**
   - Use go_router for navigation
   - Define routes in centralized location
   - Use type-safe route parameters

7. **Responsive Design**
   - Support both mobile and tablet layouts
   - Use `LayoutBuilder` for responsive designs
   - Define breakpoints in constants

8. **Testing**
   - Write unit tests for business logic
   - Write widget tests for UI components
   - Maintain at least 80% code coverage

### Code Style
- Maximum line length: 80 characters
- Use trailing commas for better formatting
- Follow official Dart style guide
- Use meaningful variable and function names
- Add comments for complex logic

### Dependencies to Use
- State Management: `flutter_riverpod`
- Navigation: `go_router`
- HTTP Client: `dio`
- Local Storage: `shared_preferences` or `hive`
- Form Validation: `reactive_forms`
- Dependency Injection: Built into Riverpod

### File Naming Conventions
- Use snake_case for file names
- Suffix screens with `_screen.dart`
- Suffix widgets with `_widget.dart`
- Suffix providers with `_provider.dart`
- Suffix models with `_model.dart`

### Git Commit Messages
- Use conventional commits format
- Examples:
  - `feat: add login screen`
  - `fix: resolve navigation issue`
  - `refactor: improve auth provider structure`
  - `docs: update README`

## Implementation Checklist for New Features
1. Create feature folder structure
2. Define data models
3. Create repository interfaces
4. Implement repositories
5. Create providers
6. Build UI screens
7. Add navigation routes
8. Write tests
9. Update documentation

## Notes for AI Assistant
When creating new screens or features:
1. Always follow the folder structure above
2. Use Riverpod for state management
3. Create separate providers file
4. Implement proper error handling
5. Make UI responsive for mobile and tablet
6. Use constants for repeated values
7. Extract reusable widgets
8. Follow separation of concerns principle