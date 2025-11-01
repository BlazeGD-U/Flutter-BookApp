# MyBooks - Flutter Book Management App

Una aplicación Flutter para gestión y recomendación de libros con Firebase.

## Características

-  Gestión completa de libros (agregar, editar, eliminar)
-  Autenticación de usuarios (registro, login, logout)
-  Perfil de usuario editable
-  Sistema de notificaciones inteligentes
-  Búsqueda y filtros por categoría y estado
-  Diseño moderno y responsivo
-  Sincronización en tiempo real con Firebase


La aplicación usa Firebase Realtime Database 

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

