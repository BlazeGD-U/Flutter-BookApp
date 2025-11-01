# MyBooks - Flutter Book Management App

Una aplicación Flutter para gestión y recomendación de libros con Firebase.

## Características

- 📚 Gestión completa de libros (agregar, editar, eliminar)
- 🔐 Autenticación de usuarios (registro, login, logout)
- 👤 Perfil de usuario editable
- 🔔 Sistema de notificaciones inteligentes
- 🔍 Búsqueda y filtros por categoría y estado
- 📱 Diseño moderno y responsivo
- ☁️ Sincronización en tiempo real con Firebase

## Configuración de Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Habilita Authentication (Email/Password)
3. Crea una Realtime Database
4. Habilita Firebase Storage
5. Descarga los archivos de configuración:
   - Android: `google-services.json` en `android/app/`
   - iOS: `GoogleService-Info.plist` en `ios/Runner/`

## Base de Datos

La aplicación usa Firebase Realtime Database con la siguiente estructura:

```
/users/{userId}
  - name
  - email
  - photoUrl
  - createdAt

/books/{bookId}
  - userId
  - title
  - author
  - category
  - status
  - description
  - imageUrl
  - createdAt
  - updatedAt

/recommendations/{bookId}
  - title
  - author
  - category
  - description
  - imageUrl

/notifications/{notificationId}
  - userId
  - bookId
  - message
  - createdAt
  - read
```

## Instalación

```bash
# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run
```

## Estructura del Proyecto

```
lib/
├── main.dart
├── models/          # Modelos de datos
├── providers/       # Gestión de estado con Provider
├── services/        # Servicios de Firebase
├── screens/         # Pantallas de la aplicación
├── widgets/         # Widgets reutilizables
└── utils/           # Utilidades y constantes
```

## Tecnologías

- Flutter 3.0+
- Firebase (Auth, Realtime Database, Storage)
- Provider (State Management)
- Google Fonts
- Image Picker

