# Catalog App

This is a Flutter application for the Catalog app, which integrates with back-end APIs for catalog and user management.

## Project Structure

- **lib/**: Contains the main application code.
  - **main.dart**: Entry point of the application.
  - **screens/**: Contains screen widgets.
    - **catalog_screen.dart**: Displays the catalog of items.
  - **widgets/**: Contains reusable widgets.
    - **catalog_widget.dart**: Displays details of a catalog item.
  - **services/**: Contains services for API interactions.
    - **catalog_service.dart**: Interacts with the catalog API.
    - **user_service.dart**: Manages user authentication and profile.
  - **models/**: Contains data models.
    - **catalog_model.dart**: Defines the structure of a catalog item.
    - **user_model.dart**: Defines the structure of a user.
  - **constants/**: Contains constant values.
    - **api_constants.dart**: API endpoint URLs.

- **test/**: Contains tests for the application.
  - **widget_test.dart**: Widget tests to ensure UI functionality.

- **pubspec.yaml**: Configuration file for the Flutter project.

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd fe
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the application:
   ```
   flutter run
   ```

## Usage Guidelines

- The application fetches catalog items from the catalog API and displays them in a user-friendly format.
- User authentication and profile management are handled through the user API.
- Ensure that the back-end APIs are running and accessible for the application to function correctly.