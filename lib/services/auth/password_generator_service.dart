class PasswordGeneratorService {
  /// Genera un usuario basado en nombre, apellido y DNI
  static String generateUser(String nombre, String apellido, String dni) {
    if (nombre.isEmpty || apellido.isEmpty || dni.isEmpty) {
      return '';
    }

    final nombreTrimmed = nombre.trim();
    final apellidoTrimmed = apellido.trim();
    final dniTrimmed = dni.trim();

    return (nombreTrimmed[0].toUpperCase() +
        nombreTrimmed
            .substring(1, nombreTrimmed.length >= 3 ? 3 : nombreTrimmed.length)
            .toLowerCase() +
        apellidoTrimmed[0].toUpperCase() +
        (apellidoTrimmed.length >= 2 ? apellidoTrimmed[1].toLowerCase() : '') +
        dniTrimmed.substring(
          0,
          dniTrimmed.length >= 3 ? 3 : dniTrimmed.length,
        ));
  }

  /// Genera una contraseña basada en nombre, apellido y DNI
  static String generatePassword(String nombre, String apellido, String dni) {
    if (nombre.isEmpty || apellido.isEmpty || dni.isEmpty) {
      return '';
    }

    final nombreTrimmed = nombre.trim();
    final apellidoTrimmed = apellido.trim();
    final dniTrimmed = dni.trim();

    final ultimosCuatro = dniTrimmed.length >= 4
        ? dniTrimmed.substring(dniTrimmed.length - 4)
        : dniTrimmed;

    return ('${nombreTrimmed[0].toUpperCase()}${apellidoTrimmed[0].toUpperCase()}${apellidoTrimmed.length >= 2 ? apellidoTrimmed[1].toLowerCase() : ''}.${_fixSequences(ultimosCuatro)}!'); // Agregamos ! al final para cumplir con el requisito de símbolo
  }

  /// Arregla secuencias consecutivas o repetitivas en un string numérico
  static String _fixSequences(String numString) {
    if (numString.isEmpty) return '';

    List<String> newNumArray = [numString[0]];

    for (int i = 1; i < numString.length; i++) {
      int actual = int.parse(numString[i]);
      int anterior = int.parse(newNumArray[newNumArray.length - 1]);

      bool isRepetitive = actual == anterior;
      bool isConsecutiveUp = actual == anterior + 1;
      bool isConsecutiveDown = actual == anterior - 1;

      if (isRepetitive || isConsecutiveUp || isConsecutiveDown) {
        int newDigit = (actual + 3) % 10;

        while (newDigit == anterior ||
            newDigit == anterior + 1 ||
            newDigit == anterior - 1) {
          newDigit = (newDigit + 1) % 10;
        }

        newNumArray.add(newDigit.toString());
      } else {
        newNumArray.add(actual.toString());
      }
    }

    return newNumArray.join('');
  }
}
