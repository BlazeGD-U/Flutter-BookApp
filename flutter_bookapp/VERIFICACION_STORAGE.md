# 🔥 Verificación de Reglas de Firebase Storage

## ⚠️ IMPORTANTE: Permisos de Eliminación

Para que las imágenes se eliminen correctamente de Firebase Storage, debes verificar que las reglas permitan la operación de **delete**.

---

## 📋 Verificar Reglas Actuales

### 1. Acceder a Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **bookapp-3b63f**
3. En el menú izquierdo, ve a **Storage** → **Rules**

### 2. Revisar las Reglas Actuales

Tu archivo `storage.rules` actual debería verse así:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Función auxiliar para verificar autenticación
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Función para verificar que el archivo sea una imagen
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    // Función para verificar el tamaño del archivo (máximo 5MB)
    function isValidSize() {
      return request.resource.size < 5 * 1024 * 1024;
    }
    
    // Reglas para imágenes de perfil
    match /profile_images/{userId} {
      // Permitir lectura a todos los usuarios autenticados
      allow read: if isAuthenticated();
      
      // Permitir escritura solo al propietario
      allow write: if isAuthenticated() 
                   && request.auth.uid == userId
                   && isImage()
                   && isValidSize();
    }
    
    // Reglas para imágenes de libros
    match /book_images/{imageId} {
      // Permitir lectura a todos los usuarios autenticados
      allow read: if isAuthenticated();
      
      // Permitir escritura a cualquier usuario autenticado
      allow write: if isAuthenticated()
                   && isImage()
                   && isValidSize();
    }
    
    // Denegar acceso a todo lo demás
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## ⚠️ PROBLEMA COMÚN: Reglas restrictivas para `delete`

### ❌ Problema:

La regla actual usa `allow write` que incluye tanto `create`, `update` como **`delete`**.

Sin embargo, las condiciones `isImage()` y `isValidSize()` **solo se aplican a archivos que se están subiendo**, no a archivos que se están eliminando.

Esto causa que las eliminaciones fallen porque `request.resource` es `null` durante una operación `delete`.

### ✅ Solución:

Separa las reglas para permitir `delete` sin validaciones de contenido:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // Función auxiliar para verificar autenticación
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Función para verificar que el archivo sea una imagen (solo en creación/actualización)
    function isImage() {
      return request.resource != null && request.resource.contentType.matches('image/.*');
    }
    
    // Función para verificar el tamaño del archivo (solo en creación/actualización)
    function isValidSize() {
      return request.resource != null && request.resource.size < 5 * 1024 * 1024;
    }
    
    // Reglas para imágenes de perfil
    match /profile_images/{userId}/{fileName} {
      // Permitir lectura a todos los usuarios autenticados
      allow read: if isAuthenticated();
      
      // Permitir subir solo al propietario, con validaciones
      allow create, update: if isAuthenticated() 
                            && request.auth.uid == userId
                            && isImage()
                            && isValidSize();
      
      // Permitir eliminar solo al propietario, sin validaciones de contenido
      allow delete: if isAuthenticated() && request.auth.uid == userId;
    }
    
    // Reglas para imágenes de libros
    match /book_images/{imageId} {
      // Permitir lectura a todos los usuarios autenticados
      allow read: if isAuthenticated();
      
      // Permitir subir a cualquier usuario autenticado, con validaciones
      allow create, update: if isAuthenticated()
                            && isImage()
                            && isValidSize();
      
      // Permitir eliminar a cualquier usuario autenticado
      allow delete: if isAuthenticated();
    }
    
    // Denegar acceso a todo lo demás
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 🚀 Aplicar las Nuevas Reglas

### Opción A: Desde Firebase Console

1. Ve a **Storage** → **Rules**
2. Reemplaza el contenido con las reglas corregidas de arriba
3. Haz clic en **"Publish"**
4. Espera 1-2 minutos para que se propaguen

### Opción B: Desde la Terminal

1. Abre la terminal en la carpeta del proyecto
2. Ejecuta:
   ```bash
   cd flutter_bookapp
   firebase deploy --only storage
   ```

---

## 🧪 Probar la Eliminación

### Verificar en los Logs

Después de aplicar las reglas, elimina un libro y revisa los logs de Flutter:

```bash
flutter run -v
```

**Deberías ver:**
```
Eliminando imagen del libro: https://firebasestorage...
Imagen eliminada exitosamente: https://firebasestorage...
Eliminando libro de la base de datos: abc123
Libro eliminado exitosamente: Nombre del Libro
```

**Si hay problemas:**
```
Error de Firebase al eliminar imagen: unauthorized - ...
```
↑ Esto indica que las reglas no permiten la eliminación

### Verificar en Firebase Console

1. Ve a **Storage** → **Files**
2. Navega a `book_images/`
3. Elimina un libro desde la app
4. Actualiza la vista de Storage
5. ✅ La imagen debería haber desaparecido

---

## 📊 Casos de Uso Cubiertos

### ✅ Eliminar libro con imagen

```
1. Usuario elimina libro
2. App intenta eliminar imagen de Storage
3. Storage verifica: ¿Usuario autenticado? ✓
4. Storage verifica: ¿Regla permite delete? ✓
5. Imagen se elimina exitosamente
6. App elimina libro de Database
7. ✓ Libro y su imagen eliminados
```

### ✅ Eliminar libro con imagen ya eliminada

```
1. Usuario elimina libro
2. App intenta eliminar imagen de Storage
3. Storage responde: "object-not-found"
4. App maneja el error silenciosamente (ya no existe)
5. App elimina libro de Database
6. ✓ Libro eliminado, no hay imagen huérfana
```

### ✅ Actualizar imagen de libro

```
1. Usuario sube nueva imagen
2. App sube nueva imagen a Storage ✓
3. App elimina imagen anterior de Storage ✓
4. App actualiza URL en Database
5. ✓ Solo la nueva imagen queda en Storage
```

### ✅ Eliminar libro sin imagen

```
1. Usuario elimina libro
2. App detecta: imageUrl es null o vacío
3. App omite eliminación de Storage
4. App elimina libro de Database
5. ✓ Libro eliminado correctamente
```

---

## 🔍 Diagnóstico de Problemas

### Si las imágenes no se eliminan:

1. **Verificar reglas de Storage** (Opción más común)
   - ¿Permiten `delete` para usuarios autenticados?
   - ¿Las condiciones de `isImage()` están bloqueando el `delete`?

2. **Verificar autenticación**
   - ¿El usuario está autenticado al eliminar?
   - Revisa los logs: `request.auth != null`

3. **Verificar URLs**
   - ¿La URL de la imagen es válida?
   - ¿Comienza con `https://firebasestorage.googleapis.com/...`?

4. **Verificar logs de Flutter**
   - Ejecuta `flutter run -v` para ver mensajes detallados
   - Busca mensajes que empiecen con "Eliminando imagen..."

---

## ✅ Checklist Final

```
☐ Las reglas de Storage permiten delete para usuarios autenticados
☐ Las reglas separan create/update de delete
☐ Las validaciones de isImage() y isValidSize() solo se aplican a create/update
☐ Las reglas han sido desplegadas (firebase deploy --only storage)
☐ He esperado 1-2 minutos para que se propaguen los cambios
☐ Los logs de Flutter muestran "Imagen eliminada exitosamente"
☐ Al verificar en Firebase Console, las imágenes desaparecen
☐ No hay imágenes huérfanas en Storage después de eliminar libros
```

---

## 📞 Solución Rápida

Si sigues teniendo problemas, reemplaza **TEMPORALMENTE** las reglas con estas (solo para pruebas):

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**⚠️ ADVERTENCIA:** Estas reglas son muy permisivas. Solo úsalas para probar que la eliminación funciona. Luego vuelve a las reglas seguras de arriba.

---

¡Listo! Ahora tu app eliminará correctamente las imágenes de Storage cuando elimines libros. 🎉

