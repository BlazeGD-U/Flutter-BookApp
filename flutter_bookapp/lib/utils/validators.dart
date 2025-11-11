class Validators {
  
  static String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Por favor, ingresa tu nombre';
  }

  
  final nameRegex = RegExp(r'^[A-Za-záéíóúÁÉÍÓÚñÑ\s]+$', unicode: true);

  if (!nameRegex.hasMatch(value.trim())) {
    return 'El nombre solo puede contener letras y espacios';
  }

  if (value.trim().length < 2) {
    return 'El nombre debe tener al menos 2 letras';
  }

  return null;
}


  
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu correo electrónico';
    }

    // Verificar si tiene espacios
    if (value.contains(' ')) {
      return 'El correo no puede tener espacios. Por favor, revisa tu correo';
    }

    // Verificar si tiene @
    if (!value.contains('@')) {
      return 'Por favor, revisa tu correo: parece que falta el @';
    }

    // Verificar si tiene dominio
    final parts = value.split('@');
    if (parts.length != 2 || parts[1].isEmpty) {
      return 'Por favor, revisa tu correo: falta el dominio después del @';
    }

    // Verificar si tiene punto en el dominio
    if (!parts[1].contains('.')) {
      return 'Por favor, revisa tu correo: falta el dominio completo (ejemplo: gmail.com)';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Por favor, revisa tu correo: el formato no es válido';
    }

    return null;
  }

 
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, crea una contraseña';
    }

    // Debe contener al menos una letra y un número, mínimo 6 caracteres
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$');

    if (!passwordRegex.hasMatch(value)) {
      return 'La contraseña debe tener letras, números y al menos 6 caracteres';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  static String? validateBookTitle(String? value) {
    return validateRequired(value, 'El título del libro');
  }

  static String? validateAuthor(String? value) {
    return validateRequired(value, 'El autor');
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'La descripción es requerida';
    }

    if (value.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }

    return null;
  }
}
