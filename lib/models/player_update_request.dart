class PlayerUpdateRequest {
  String nombre;
  String apellido;
  String email;
  String telefono;
  String genero;
  String fechaNacimiento;
  String dni;
  String cuit;
  String estadoCivil;
  String calle;
  String numCalle;
  String provincia;
  String ciudad;
  String cp;

  PlayerUpdateRequest({
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.genero,
    required this.fechaNacimiento,
    required this.dni,
    required this.cuit,
    required this.estadoCivil,
    required this.calle,
    required this.numCalle,
    required this.provincia,
    required this.ciudad,
    required this.cp,
  });

  Map<String, dynamic> toJson() {
    return {
      "nombre": nombre,
      "apellido": apellido,
      "email": email,
      "telefono": telefono,
      "genero": genero,
      "fecha_nacimiento": fechaNacimiento,
      "dni": dni,
      "cuit": cuit,
      "est_civil": estadoCivil,
      "calle": calle,
      "numcalle": numCalle,
      "provincia": provincia,
      "ciudad": ciudad,
      "cp": cp,
    };
  }
}
