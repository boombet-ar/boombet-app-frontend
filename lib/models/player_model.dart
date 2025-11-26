class PlayerData {
  final String nombre;
  final String apellido;
  final String cuil;
  final String dni;
  final String sexo;
  final String estadoCivil;
  final String telefono;
  final String correoElectronico;
  final String direccionCompleta;
  final String calle;
  final String numCalle;
  final String localidad;
  final String provincia;
  final String fechaNacimiento;
  final int? cp;
  final int? edad;
  final String anioNacimiento;

  PlayerData({
    required this.nombre,
    required this.apellido,
    required this.cuil,
    required this.dni,
    required this.sexo,
    required this.estadoCivil,
    required this.telefono,
    required this.correoElectronico,
    required this.direccionCompleta,
    required this.calle,
    required this.numCalle,
    required this.localidad,
    required this.provincia,
    required this.fechaNacimiento,
    required this.anioNacimiento,
    this.cp,
    this.edad,
  });

  /// Factory para parsear desde el endpoint /auth/userData (datosJugador)
  factory PlayerData.fromJson(Map<String, dynamic> json) {
    return PlayerData(
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      cuil: json['cuil']?.toString() ?? '',
      dni: json['dni']?.toString() ?? '',
      sexo: json['sexo'] ?? '',
      estadoCivil: json['estado_civil'] ?? '',
      telefono: json['telefono'] ?? '',
      correoElectronico: json['correoElectronico'] ?? '',
      direccionCompleta: json['direccion'] ?? '',
      calle: json['calle'] ?? '',
      numCalle: json['numCalle']?.toString() ?? '',
      localidad: json['localidad'] ?? '',
      provincia: json['provincia'] ?? '',
      fechaNacimiento: json['fecha_nacimiento'] ?? '',
      anioNacimiento: json['añoNacimiento']?.toString() ?? '',
      cp: json['cp'] is int ? json['cp'] as int : int.tryParse('${json['cp']}'),
      edad: json['edad'] is int
          ? json['edad'] as int
          : int.tryParse('${json['edad']}'),
    );
  }

  /// Factory para parsear desde el endpoint /auth/register (listaExistenciaFisica)
  factory PlayerData.fromRegisterResponse(Map<String, dynamic> json) {
    print('DEBUG PARSER - JSON recibido: $json');

    // Extraer apenom y dividir en nombre y apellido
    final apenom = (json['apenom'] ?? '').toString().trim();
    print('DEBUG PARSER - apenom: "$apenom"');

    // Limpiar comas adicionales y espacios
    final aponemLimpio = apenom
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r',\s*$'), '')
        .trim();
    print('DEBUG PARSER - apenom limpio: "$aponemLimpio"');

    final partes = aponemLimpio.split(RegExp(r'\s+'));
    print('DEBUG PARSER - partes: $partes');

    String apellido = '';
    String nombre = '';

    if (partes.isNotEmpty) {
      // Primer elemento es el apellido (sin comas)
      apellido = partes[0].replaceAll(',', '').trim();
      // El resto es el nombre (sin comas)
      if (partes.length > 1) {
        nombre = partes.sublist(1).join(' ').replaceAll(',', '').trim();
      }
    }

    print('DEBUG PARSER - apellido: "$apellido", nombre: "$nombre"');

    // Extraer dirección completa y dividir en calle y número
    final direccionCompleta = (json['direc_calle'] ?? '').toString().trim();
    String calle = direccionCompleta;
    String numCalle = '';

    // Intentar separar el número de calle (último elemento numérico)
    final partesDireccion = direccionCompleta.split(' ');
    if (partesDireccion.isNotEmpty) {
      final ultimaParte = partesDireccion.last;
      if (int.tryParse(ultimaParte) != null) {
        numCalle = ultimaParte;
        calle = partesDireccion
            .sublist(0, partesDireccion.length - 1)
            .join(' ');
      }
    }

    // Extraer año de nacimiento desde fecha_nacimiento
    final fechaNacimiento = json['fecha_nacimiento']?.toString() ?? '';
    String anioNacimiento = '';
    if (fechaNacimiento.isNotEmpty) {
      final partesFecha = fechaNacimiento.split('-');
      if (partesFecha.length == 3) {
        anioNacimiento = partesFecha[2]; // dd-mm-yyyy
      }
    }

    // Calcular edad si no viene en el response
    int? edad;
    if (anioNacimiento.isNotEmpty) {
      final anio = int.tryParse(anioNacimiento);
      if (anio != null) {
        edad = DateTime.now().year - anio;
      }
    }

    print('DEBUG PARSER - Creando PlayerData...');
    print('DEBUG PARSER - dni: ${json['nume_docu']}');
    print('DEBUG PARSER - cuil: ${json['cdi_codigo_de_identificacion']}');
    print('DEBUG PARSER - fechaNacimiento: $fechaNacimiento');
    print('DEBUG PARSER - anioNacimiento: $anioNacimiento');

    final playerData = PlayerData(
      nombre: nombre,
      apellido: apellido,
      cuil: json['cdi_codigo_de_identificacion']?.toString() ?? '',
      dni: json['nume_docu']?.toString() ?? '',
      sexo: _normalizarSexo(json['sexo']?.toString() ?? ''),
      estadoCivil: json['estado_civil']?.toString() ?? '',
      telefono: '', // No viene en el response del register
      correoElectronico: '', // No viene en el response del register
      direccionCompleta: direccionCompleta,
      calle: calle,
      numCalle: numCalle,
      localidad: json['localidad']?.toString() ?? '',
      provincia: json['provincia']?.toString() ?? '',
      fechaNacimiento: fechaNacimiento,
      anioNacimiento: anioNacimiento,
      cp: json['codigo_postal'] is int
          ? json['codigo_postal'] as int
          : int.tryParse('${json['codigo_postal']}'),
      edad: edad,
    );

    print('DEBUG PARSER - PlayerData creado exitosamente');
    return playerData;
  }

  /// Helper para normalizar el sexo (M -> Masculino, F -> Femenino)
  static String _normalizarSexo(String sexo) {
    final sexoUpper = sexo.toUpperCase().trim();
    if (sexoUpper == 'M') return 'Masculino';
    if (sexoUpper == 'F') return 'Femenino';
    return sexo;
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'cuil': cuil,
      'dni': dni,
      'sexo': sexo,
      'estado_civil': estadoCivil,
      'telefono': telefono,
      'correoElectronico': correoElectronico,
      'direccion': direccionCompleta,
      'calle': calle,
      'numCalle': numCalle,
      'localidad': localidad,
      'provincia': provincia,
      'fecha_nacimiento': fechaNacimiento,
      'añoNacimiento': anioNacimiento,
      'cp': cp,
      'edad': edad,
    };
  }

  PlayerData copyWith({
    String? nombre,
    String? apellido,
    String? cuil,
    String? dni,
    String? sexo,
    String? estadoCivil,
    String? telefono,
    String? correoElectronico,
    String? direccionCompleta,
    String? calle,
    String? numCalle,
    String? localidad,
    String? provincia,
    String? fechaNacimiento,
    String? anioNacimiento,
    int? cp,
    int? edad,
  }) {
    return PlayerData(
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      cuil: cuil ?? this.cuil,
      dni: dni ?? this.dni,
      sexo: sexo ?? this.sexo,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      telefono: telefono ?? this.telefono,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      direccionCompleta: direccionCompleta ?? this.direccionCompleta,
      calle: calle ?? this.calle,
      numCalle: numCalle ?? this.numCalle,
      localidad: localidad ?? this.localidad,
      provincia: provincia ?? this.provincia,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      anioNacimiento: anioNacimiento ?? this.anioNacimiento,
      cp: cp ?? this.cp,
      edad: edad ?? this.edad,
    );
  }
}
