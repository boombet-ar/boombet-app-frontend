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
