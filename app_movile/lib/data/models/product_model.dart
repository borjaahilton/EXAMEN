class ProductModel {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final bool disponible;
  final String imagenUrl;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.disponible,
    required this.imagenUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double parsedPrecio = 0.0;
    if (json['precio'] != null) {
      if (json['precio'] is num) {
        parsedPrecio = (json['precio'] as num).toDouble();
      } else {
        parsedPrecio = double.tryParse(json['precio'].toString()) ?? 0.0;
      }
    }

    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: json['nombre'] as String? ?? 'Plato Tradicional',
      descripcion: json['descripcion'] as String? ?? '',
      precio: parsedPrecio,
      disponible: json['disponible'] as bool? ?? true,
      imagenUrl: json['imagen_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'disponible': disponible,
    'imagen_url': imagenUrl,
  };
}
