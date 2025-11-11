# 🔥 Guía de Configuración de Firebase para BookApp

## ✅ Estado actual del proyecto

Tu aplicación BookApp ya tiene toda la lógica implementada correctamente:

- ✅ Firebase Core inicializado
- ✅ Firebase Storage Service completo
- ✅ Image Picker integrado en las pantallas
- ✅ Providers configurados
- ✅ Permisos de Android e iOS agregados
- ✅ Reglas de Database configuradas

## 📝 Pasos para completar la configuración

### 1. Desplegar las reglas de Firebase Storage

Ejecuta este comando en la terminal desde la carpeta `flutter_bookapp`:

```bash
firebase deploy --only storage
```

Esto desplegará las reglas de `storage.rules` que permiten:
- Usuarios autenticados pueden subir imágenes de perfil (máx 5MB)
- Usuarios autenticados pueden subir imágenes de libros (máx 5MB)
- Solo imágenes JPG, PNG, GIF permitidas

### 2. Verificar las reglas de Realtime Database

Ejecuta este comando para desplegar las reglas de la base de datos:

```bash
firebase deploy --only database
```

### 3. Agregar libros recomendados a Firebase

Tienes dos opciones para agregar los libros recomendados:

#### Opción A: Desde la consola de Firebase (Recomendado)

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto `bookapp-3b63f`
3. Ve a **Realtime Database**
4. Haz clic en los 3 puntos ⋮ y selecciona **"Import JSON"**
5. Selecciona el archivo `recommendations_data.json` que está en la carpeta del proyecto
6. Confirma la importación

#### Opción B: Copiar y pegar manualmente

1. Ve a Firebase Console → Realtime Database
2. Haz clic en el ícono `+` junto a la raíz de tu base de datos
3. Crea un nodo llamado `recommendations`
4. Para cada libro recomendado, crea un hijo con los datos del archivo `recommendations_data.json`

### 4. Instalar dependencias

Si aún no lo has hecho, ejecuta:

```bash
flutter pub get
```

### 5. Configurar Firebase CLI (si no lo tienes)

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Iniciar sesión
firebase login

# Inicializar en el proyecto (si es necesario)
cd flutter_bookapp
firebase init
```

Selecciona:
- Realtime Database
- Storage

## 🧪 Cómo probar que todo funciona

### 1. Probar subida de imagen de perfil

1. Ejecuta la app: `flutter run`
2. Crea una cuenta o inicia sesión
3. Ve a la pantalla de perfil
4. Toca el círculo de la foto de perfil
5. Selecciona "Galería" o "Cámara"
6. Elige/toma una foto
7. Guarda los cambios

**Verificación:**
- Ve a Firebase Console → Storage
- Deberías ver la carpeta `profile_images/` con tu imagen subida
- La imagen debería mostrarse en tu perfil

### 2. Probar subida de imagen de libro

1. En la pantalla principal, toca el botón "+" para agregar un libro
2. Toca el área de imagen del libro
3. Selecciona "Galería" o "Cámara"
4. Elige/toma una foto de la portada
5. Completa los datos: título, autor, categoría, estado, descripción
6. Guarda el libro

**Verificación:**
- Ve a Firebase Console → Storage
- Deberías ver la carpeta `book_images/` con la imagen subida
- El libro debería aparecer en tu lista con su imagen

### 3. Probar libros recomendados

1. Ve a la pestaña "Inicio" (Home)
2. Deberías ver la sección "Libros recomendados"
3. Los 6 libros pre-configurados deberían mostrarse con sus portadas

**Si no aparecen:**
- Verifica que importaste el archivo `recommendations_data.json` en Firebase
- Verifica que el nodo se llame exactamente `recommendations`
- Revisa la consola de Flutter por errores

## 🐛 Solución de problemas comunes

### Las imágenes no se suben

1. **Verifica permisos:** Asegúrate de que la app tenga permisos de cámara y galería
   - En Android: Ve a Configuración → Apps → BookApp → Permisos
   - En iOS: Ve a Ajustes → BookApp → Permisos

2. **Verifica reglas de Storage:**
   ```bash
   firebase deploy --only storage
   ```

3. **Verifica que el usuario esté autenticado:**
   - Las reglas requieren `request.auth != null`

### Los libros recomendados no aparecen

1. **Verifica la estructura en Firebase:**
   ```
   (raíz)
     ├── books/
     ├── users/
     ├── notifications/
     └── recommendations/  ← Debe existir aquí
         ├── rec_001/
         ├── rec_002/
         └── ...
   ```

2. **Verifica las reglas de lectura:**
   - Las recomendaciones tienen `.read: true` en `database.rules.json`

3. **Revisa los logs:**
   ```bash
   flutter run -v
   ```

### Error de tamaño de imagen

Si aparece el mensaje "La imagen es muy grande. Máximo 5MB":
- La imagen seleccionada excede los 5MB
- Intenta con una imagen más pequeña
- El widget ya comprime automáticamente a 85% de calidad

## 📱 Comandos útiles

```bash
# Ver logs en tiempo real
flutter run -v

# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run

# Verificar configuración de Firebase
firebase projects:list
firebase use bookapp-3b63f

# Ver reglas actuales
firebase database:get / --pretty
```

## 🎨 Estructura de las imágenes en Storage

```
storage/
├── profile_images/
│   ├── profile_<userId1>.jpg
│   ├── profile_<userId2>.jpg
│   └── ...
└── book_images/
    ├── <uuid1>.jpg
    ├── <uuid2>.jpg
    └── ...
```

## 📞 Soporte adicional

Si tienes problemas:
1. Verifica que Firebase esté correctamente inicializado en `main.dart`
2. Verifica que `google-services.json` (Android) esté en la carpeta correcta
3. Revisa los logs de Flutter y Firebase Console
4. Asegúrate de que tu proyecto de Firebase tenga Storage y Realtime Database habilitados

---

¡Listo! Tu app BookApp está completamente configurada para trabajar con Firebase Storage 🎉
