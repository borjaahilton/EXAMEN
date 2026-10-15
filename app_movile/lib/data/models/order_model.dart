class OrderItemModel {
  final int? id;
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String imagenUrl;

  OrderItemModel({
    this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.imagenUrl = '',
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final pId = json['producto'] ?? json['producto_id'] ?? 0;
    final pName = json['producto_nombre'] ?? json['nombre_producto'] ?? 'Plato';

    return OrderItemModel(
      id: (json['id'] as num?)?.toInt(),
      productoId: (pId as num).toInt(),
      nombreProducto: pName.toString(),
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      precioUnitario: parseDouble(json['precio_unitario']),
      subtotal: parseDouble(json['subtotal']),
      imagenUrl: json['imagen_url'] as String? ?? '',
    );
  }

  // Django espera el campo "producto": <id> y "cantidad": <int>
  Map<String, dynamic> toJson() => {
    'producto': productoId,
    'cantidad': cantidad,
  };
}

class OrderModel {
  final int id;
  final int clienteId;
  final String fecha;
  final String estado; // 'pendiente', 'en preparacion', 'listo', 'entregado'
  final String tipoEntrega; // 'recojo', 'consumo_local'
  final double total;
  final String notas;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.clienteId,
    required this.fecha,
    required this.estado,
    required this.tipoEntrega,
    required this.total,
    required this.notas,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final cId = json['cliente'] ?? json['cliente_id'] ?? 0;

    return OrderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      clienteId: (cId as num).toInt(),
      fecha: json['fecha'] as String? ?? '',
      estado: json['estado'] as String? ?? 'pendiente',
      tipoEntrega: json['tipo_entrega'] as String? ?? 'recojo',
      total: parseDouble(json['total']),
      notas: json['notas'] as String? ?? '',
      items: rawItems
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
