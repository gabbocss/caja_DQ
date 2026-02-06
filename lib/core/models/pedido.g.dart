// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pedido.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPedidoCollection on Isar {
  IsarCollection<Pedido> get pedidos => this.collection();
}

const PedidoSchema = CollectionSchema(
  name: r'Pedido',
  id: -6371224144056768827,
  properties: {
    r'esBuffet': PropertySchema(
      id: 0,
      name: r'esBuffet',
      type: IsarType.bool,
    ),
    r'estado': PropertySchema(
      id: 1,
      name: r'estado',
      type: IsarType.string,
      enumMap: _PedidoestadoEnumValueMap,
    ),
    r'fechaActualizacion': PropertySchema(
      id: 2,
      name: r'fechaActualizacion',
      type: IsarType.dateTime,
    ),
    r'fechaCompletado': PropertySchema(
      id: 3,
      name: r'fechaCompletado',
      type: IsarType.dateTime,
    ),
    r'fechaCreacion': PropertySchema(
      id: 4,
      name: r'fechaCreacion',
      type: IsarType.dateTime,
    ),
    r'items': PropertySchema(
      id: 5,
      name: r'items',
      type: IsarType.objectList,
      target: r'ItemPedido',
    ),
    r'mesaNumero': PropertySchema(
      id: 6,
      name: r'mesaNumero',
      type: IsarType.long,
    ),
    r'notas': PropertySchema(
      id: 7,
      name: r'notas',
      type: IsarType.string,
    ),
    r'numeroComensales': PropertySchema(
      id: 8,
      name: r'numeroComensales',
      type: IsarType.long,
    ),
    r'origen': PropertySchema(
      id: 9,
      name: r'origen',
      type: IsarType.string,
      enumMap: _PedidoorigenEnumValueMap,
    ),
    r'total': PropertySchema(
      id: 10,
      name: r'total',
      type: IsarType.double,
    ),
    r'usuarioCamarero': PropertySchema(
      id: 11,
      name: r'usuarioCamarero',
      type: IsarType.string,
    )
  },
  estimateSize: _pedidoEstimateSize,
  serialize: _pedidoSerialize,
  deserialize: _pedidoDeserialize,
  deserializeProp: _pedidoDeserializeProp,
  idName: r'id',
  indexes: {
    r'mesaNumero': IndexSchema(
      id: 3153117696506690401,
      name: r'mesaNumero',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mesaNumero',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'estado': IndexSchema(
      id: -4800696143246816208,
      name: r'estado',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'estado',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'usuarioCamarero': IndexSchema(
      id: 1161159933858556445,
      name: r'usuarioCamarero',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'usuarioCamarero',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'fechaCreacion': IndexSchema(
      id: 3471812336142411217,
      name: r'fechaCreacion',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fechaCreacion',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'ItemPedido': ItemPedidoSchema},
  getId: _pedidoGetId,
  getLinks: _pedidoGetLinks,
  attach: _pedidoAttach,
  version: '3.1.0+1',
);

int _pedidoEstimateSize(
  Pedido object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.estado.name.length * 3;
  bytesCount += 3 + object.items.length * 3;
  {
    final offsets = allOffsets[ItemPedido]!;
    for (var i = 0; i < object.items.length; i++) {
      final value = object.items[i];
      bytesCount += ItemPedidoSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.notas;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.origen.name.length * 3;
  bytesCount += 3 + object.usuarioCamarero.length * 3;
  return bytesCount;
}

void _pedidoSerialize(
  Pedido object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.esBuffet);
  writer.writeString(offsets[1], object.estado.name);
  writer.writeDateTime(offsets[2], object.fechaActualizacion);
  writer.writeDateTime(offsets[3], object.fechaCompletado);
  writer.writeDateTime(offsets[4], object.fechaCreacion);
  writer.writeObjectList<ItemPedido>(
    offsets[5],
    allOffsets,
    ItemPedidoSchema.serialize,
    object.items,
  );
  writer.writeLong(offsets[6], object.mesaNumero);
  writer.writeString(offsets[7], object.notas);
  writer.writeLong(offsets[8], object.numeroComensales);
  writer.writeString(offsets[9], object.origen.name);
  writer.writeDouble(offsets[10], object.total);
  writer.writeString(offsets[11], object.usuarioCamarero);
}

Pedido _pedidoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Pedido();
  object.esBuffet = reader.readBool(offsets[0]);
  object.estado =
      _PedidoestadoValueEnumMap[reader.readStringOrNull(offsets[1])] ??
          EstadoPedido.pendiente;
  object.fechaActualizacion = reader.readDateTime(offsets[2]);
  object.fechaCompletado = reader.readDateTimeOrNull(offsets[3]);
  object.fechaCreacion = reader.readDateTime(offsets[4]);
  object.id = id;
  object.items = reader.readObjectList<ItemPedido>(
        offsets[5],
        ItemPedidoSchema.deserialize,
        allOffsets,
        ItemPedido(),
      ) ??
      [];
  object.mesaNumero = reader.readLong(offsets[6]);
  object.notas = reader.readStringOrNull(offsets[7]);
  object.numeroComensales = reader.readLongOrNull(offsets[8]);
  object.origen =
      _PedidoorigenValueEnumMap[reader.readStringOrNull(offsets[9])] ??
          OrigenPedido.camarero;
  object.total = reader.readDouble(offsets[10]);
  object.usuarioCamarero = reader.readString(offsets[11]);
  return object;
}

P _pedidoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (_PedidoestadoValueEnumMap[reader.readStringOrNull(offset)] ??
          EstadoPedido.pendiente) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readObjectList<ItemPedido>(
            offset,
            ItemPedidoSchema.deserialize,
            allOffsets,
            ItemPedido(),
          ) ??
          []) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (_PedidoorigenValueEnumMap[reader.readStringOrNull(offset)] ??
          OrigenPedido.camarero) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PedidoestadoEnumValueMap = {
  r'pendiente': r'pendiente',
  r'preparando': r'preparando',
  r'listo': r'listo',
  r'servido': r'servido',
  r'cancelado': r'cancelado',
  r'pagado': r'pagado',
};
const _PedidoestadoValueEnumMap = {
  r'pendiente': EstadoPedido.pendiente,
  r'preparando': EstadoPedido.preparando,
  r'listo': EstadoPedido.listo,
  r'servido': EstadoPedido.servido,
  r'cancelado': EstadoPedido.cancelado,
  r'pagado': EstadoPedido.pagado,
};
const _PedidoorigenEnumValueMap = {
  r'camarero': r'camarero',
  r'qr': r'qr',
  r'web': r'web',
};
const _PedidoorigenValueEnumMap = {
  r'camarero': OrigenPedido.camarero,
  r'qr': OrigenPedido.qr,
  r'web': OrigenPedido.web,
};

Id _pedidoGetId(Pedido object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _pedidoGetLinks(Pedido object) {
  return [];
}

void _pedidoAttach(IsarCollection<dynamic> col, Id id, Pedido object) {
  object.id = id;
}

extension PedidoQueryWhereSort on QueryBuilder<Pedido, Pedido, QWhere> {
  QueryBuilder<Pedido, Pedido, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhere> anyMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'mesaNumero'),
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhere> anyFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'fechaCreacion'),
      );
    });
  }
}

extension PedidoQueryWhere on QueryBuilder<Pedido, Pedido, QWhereClause> {
  QueryBuilder<Pedido, Pedido, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> mesaNumeroEqualTo(
      int mesaNumero) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'mesaNumero',
        value: [mesaNumero],
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> mesaNumeroNotEqualTo(
      int mesaNumero) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mesaNumero',
              lower: [],
              upper: [mesaNumero],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mesaNumero',
              lower: [mesaNumero],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mesaNumero',
              lower: [mesaNumero],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'mesaNumero',
              lower: [],
              upper: [mesaNumero],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> mesaNumeroGreaterThan(
    int mesaNumero, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mesaNumero',
        lower: [mesaNumero],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> mesaNumeroLessThan(
    int mesaNumero, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mesaNumero',
        lower: [],
        upper: [mesaNumero],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> mesaNumeroBetween(
    int lowerMesaNumero,
    int upperMesaNumero, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'mesaNumero',
        lower: [lowerMesaNumero],
        includeLower: includeLower,
        upper: [upperMesaNumero],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> estadoEqualTo(
      EstadoPedido estado) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'estado',
        value: [estado],
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> estadoNotEqualTo(
      EstadoPedido estado) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'estado',
              lower: [],
              upper: [estado],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'estado',
              lower: [estado],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'estado',
              lower: [estado],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'estado',
              lower: [],
              upper: [estado],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> usuarioCamareroEqualTo(
      String usuarioCamarero) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'usuarioCamarero',
        value: [usuarioCamarero],
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> usuarioCamareroNotEqualTo(
      String usuarioCamarero) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'usuarioCamarero',
              lower: [],
              upper: [usuarioCamarero],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'usuarioCamarero',
              lower: [usuarioCamarero],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'usuarioCamarero',
              lower: [usuarioCamarero],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'usuarioCamarero',
              lower: [],
              upper: [usuarioCamarero],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> fechaCreacionEqualTo(
      DateTime fechaCreacion) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fechaCreacion',
        value: [fechaCreacion],
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> fechaCreacionNotEqualTo(
      DateTime fechaCreacion) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaCreacion',
              lower: [],
              upper: [fechaCreacion],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaCreacion',
              lower: [fechaCreacion],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaCreacion',
              lower: [fechaCreacion],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaCreacion',
              lower: [],
              upper: [fechaCreacion],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> fechaCreacionGreaterThan(
    DateTime fechaCreacion, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaCreacion',
        lower: [fechaCreacion],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> fechaCreacionLessThan(
    DateTime fechaCreacion, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaCreacion',
        lower: [],
        upper: [fechaCreacion],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterWhereClause> fechaCreacionBetween(
    DateTime lowerFechaCreacion,
    DateTime upperFechaCreacion, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaCreacion',
        lower: [lowerFechaCreacion],
        includeLower: includeLower,
        upper: [upperFechaCreacion],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PedidoQueryFilter on QueryBuilder<Pedido, Pedido, QFilterCondition> {
  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> esBuffetEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'esBuffet',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoEqualTo(
    EstadoPedido value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estado',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoGreaterThan(
    EstadoPedido value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estado',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoLessThan(
    EstadoPedido value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estado',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoBetween(
    EstadoPedido lower,
    EstadoPedido upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estado',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'estado',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'estado',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'estado',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'estado',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estado',
        value: '',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> estadoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'estado',
        value: '',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaActualizacionEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaActualizacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition>
      fechaActualizacionGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fechaActualizacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition>
      fechaActualizacionLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fechaActualizacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaActualizacionBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fechaActualizacion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaCompletadoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fechaCompletado',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition>
      fechaCompletadoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fechaCompletado',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaCompletadoEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaCompletado',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition>
      fechaCompletadoGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fechaCompletado',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaCompletadoLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fechaCompletado',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaCompletadoBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fechaCompletado',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaCreacionEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaCreacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaCreacionGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fechaCreacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaCreacionLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fechaCreacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> fechaCreacionBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fechaCreacion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> idGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> idLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> itemsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> itemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> itemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> itemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'items',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> mesaNumeroEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mesaNumero',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> mesaNumeroGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mesaNumero',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> mesaNumeroLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mesaNumero',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> mesaNumeroBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mesaNumero',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notas',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notas',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notas',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notas',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notas',
        value: '',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> notasIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notas',
        value: '',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> numeroComensalesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'numeroComensales',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition>
      numeroComensalesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'numeroComensales',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> numeroComensalesEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numeroComensales',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition>
      numeroComensalesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numeroComensales',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> numeroComensalesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numeroComensales',
        value: value,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> numeroComensalesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numeroComensales',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenEqualTo(
    OrigenPedido value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'origen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenGreaterThan(
    OrigenPedido value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'origen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenLessThan(
    OrigenPedido value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'origen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenBetween(
    OrigenPedido lower,
    OrigenPedido upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'origen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'origen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'origen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'origen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'origen',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'origen',
        value: '',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> origenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'origen',
        value: '',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> totalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> totalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> totalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'total',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> totalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'total',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> usuarioCamareroEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usuarioCamarero',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition>
      usuarioCamareroGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usuarioCamarero',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> usuarioCamareroLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usuarioCamarero',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> usuarioCamareroBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usuarioCamarero',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> usuarioCamareroStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'usuarioCamarero',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> usuarioCamareroEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'usuarioCamarero',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> usuarioCamareroContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'usuarioCamarero',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> usuarioCamareroMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'usuarioCamarero',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> usuarioCamareroIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usuarioCamarero',
        value: '',
      ));
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterFilterCondition>
      usuarioCamareroIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'usuarioCamarero',
        value: '',
      ));
    });
  }
}

extension PedidoQueryObject on QueryBuilder<Pedido, Pedido, QFilterCondition> {
  QueryBuilder<Pedido, Pedido, QAfterFilterCondition> itemsElement(
      FilterQuery<ItemPedido> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }
}

extension PedidoQueryLinks on QueryBuilder<Pedido, Pedido, QFilterCondition> {}

extension PedidoQuerySortBy on QueryBuilder<Pedido, Pedido, QSortBy> {
  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByEsBuffet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esBuffet', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByEsBuffetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esBuffet', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByEstado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByEstadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByFechaActualizacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByFechaCompletado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCompletado', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByFechaCompletadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCompletado', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByMesaNumeroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByNotas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notas', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByNotasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notas', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByNumeroComensales() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numeroComensales', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByNumeroComensalesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numeroComensales', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByOrigen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origen', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByOrigenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origen', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByUsuarioCamarero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usuarioCamarero', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> sortByUsuarioCamareroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usuarioCamarero', Sort.desc);
    });
  }
}

extension PedidoQuerySortThenBy on QueryBuilder<Pedido, Pedido, QSortThenBy> {
  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByEsBuffet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esBuffet', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByEsBuffetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esBuffet', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByEstado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByEstadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByFechaActualizacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByFechaCompletado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCompletado', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByFechaCompletadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCompletado', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByMesaNumeroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByNotas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notas', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByNotasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notas', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByNumeroComensales() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numeroComensales', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByNumeroComensalesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numeroComensales', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByOrigen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origen', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByOrigenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origen', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByUsuarioCamarero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usuarioCamarero', Sort.asc);
    });
  }

  QueryBuilder<Pedido, Pedido, QAfterSortBy> thenByUsuarioCamareroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usuarioCamarero', Sort.desc);
    });
  }
}

extension PedidoQueryWhereDistinct on QueryBuilder<Pedido, Pedido, QDistinct> {
  QueryBuilder<Pedido, Pedido, QDistinct> distinctByEsBuffet() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'esBuffet');
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByEstado(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estado', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaActualizacion');
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByFechaCompletado() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaCompletado');
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaCreacion');
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mesaNumero');
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByNotas(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notas', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByNumeroComensales() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numeroComensales');
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByOrigen(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'origen', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }

  QueryBuilder<Pedido, Pedido, QDistinct> distinctByUsuarioCamarero(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usuarioCamarero',
          caseSensitive: caseSensitive);
    });
  }
}

extension PedidoQueryProperty on QueryBuilder<Pedido, Pedido, QQueryProperty> {
  QueryBuilder<Pedido, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Pedido, bool, QQueryOperations> esBuffetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'esBuffet');
    });
  }

  QueryBuilder<Pedido, EstadoPedido, QQueryOperations> estadoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estado');
    });
  }

  QueryBuilder<Pedido, DateTime, QQueryOperations>
      fechaActualizacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaActualizacion');
    });
  }

  QueryBuilder<Pedido, DateTime?, QQueryOperations> fechaCompletadoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaCompletado');
    });
  }

  QueryBuilder<Pedido, DateTime, QQueryOperations> fechaCreacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaCreacion');
    });
  }

  QueryBuilder<Pedido, List<ItemPedido>, QQueryOperations> itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'items');
    });
  }

  QueryBuilder<Pedido, int, QQueryOperations> mesaNumeroProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mesaNumero');
    });
  }

  QueryBuilder<Pedido, String?, QQueryOperations> notasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notas');
    });
  }

  QueryBuilder<Pedido, int?, QQueryOperations> numeroComensalesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numeroComensales');
    });
  }

  QueryBuilder<Pedido, OrigenPedido, QQueryOperations> origenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'origen');
    });
  }

  QueryBuilder<Pedido, double, QQueryOperations> totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }

  QueryBuilder<Pedido, String, QQueryOperations> usuarioCamareroProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usuarioCamarero');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ItemPedidoSchema = Schema(
  name: r'ItemPedido',
  id: -2265097771531848832,
  properties: {
    r'cantidad': PropertySchema(
      id: 0,
      name: r'cantidad',
      type: IsarType.long,
    ),
    r'destinoId': PropertySchema(
      id: 1,
      name: r'destinoId',
      type: IsarType.long,
    ),
    r'estadoItem': PropertySchema(
      id: 2,
      name: r'estadoItem',
      type: IsarType.string,
      enumMap: _ItemPedidoestadoItemEnumValueMap,
    ),
    r'nombreDestino': PropertySchema(
      id: 3,
      name: r'nombreDestino',
      type: IsarType.string,
    ),
    r'nombreProducto': PropertySchema(
      id: 4,
      name: r'nombreProducto',
      type: IsarType.string,
    ),
    r'notas': PropertySchema(
      id: 5,
      name: r'notas',
      type: IsarType.string,
    ),
    r'precioUnitario': PropertySchema(
      id: 6,
      name: r'precioUnitario',
      type: IsarType.double,
    ),
    r'productoId': PropertySchema(
      id: 7,
      name: r'productoId',
      type: IsarType.long,
    ),
    r'subtotal': PropertySchema(
      id: 8,
      name: r'subtotal',
      type: IsarType.double,
    )
  },
  estimateSize: _itemPedidoEstimateSize,
  serialize: _itemPedidoSerialize,
  deserialize: _itemPedidoDeserialize,
  deserializeProp: _itemPedidoDeserializeProp,
);

int _itemPedidoEstimateSize(
  ItemPedido object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.estadoItem.name.length * 3;
  {
    final value = object.nombreDestino;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nombreProducto.length * 3;
  {
    final value = object.notas;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _itemPedidoSerialize(
  ItemPedido object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.cantidad);
  writer.writeLong(offsets[1], object.destinoId);
  writer.writeString(offsets[2], object.estadoItem.name);
  writer.writeString(offsets[3], object.nombreDestino);
  writer.writeString(offsets[4], object.nombreProducto);
  writer.writeString(offsets[5], object.notas);
  writer.writeDouble(offsets[6], object.precioUnitario);
  writer.writeLong(offsets[7], object.productoId);
  writer.writeDouble(offsets[8], object.subtotal);
}

ItemPedido _itemPedidoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ItemPedido();
  object.cantidad = reader.readLong(offsets[0]);
  object.destinoId = reader.readLongOrNull(offsets[1]);
  object.estadoItem =
      _ItemPedidoestadoItemValueEnumMap[reader.readStringOrNull(offsets[2])] ??
          EstadoPedido.pendiente;
  object.nombreDestino = reader.readStringOrNull(offsets[3]);
  object.nombreProducto = reader.readString(offsets[4]);
  object.notas = reader.readStringOrNull(offsets[5]);
  object.precioUnitario = reader.readDouble(offsets[6]);
  object.productoId = reader.readLong(offsets[7]);
  return object;
}

P _itemPedidoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (_ItemPedidoestadoItemValueEnumMap[
              reader.readStringOrNull(offset)] ??
          EstadoPedido.pendiente) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ItemPedidoestadoItemEnumValueMap = {
  r'pendiente': r'pendiente',
  r'preparando': r'preparando',
  r'listo': r'listo',
  r'servido': r'servido',
  r'cancelado': r'cancelado',
  r'pagado': r'pagado',
};
const _ItemPedidoestadoItemValueEnumMap = {
  r'pendiente': EstadoPedido.pendiente,
  r'preparando': EstadoPedido.preparando,
  r'listo': EstadoPedido.listo,
  r'servido': EstadoPedido.servido,
  r'cancelado': EstadoPedido.cancelado,
  r'pagado': EstadoPedido.pagado,
};

extension ItemPedidoQueryFilter
    on QueryBuilder<ItemPedido, ItemPedido, QFilterCondition> {
  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> cantidadEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cantidad',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      cantidadGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cantidad',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> cantidadLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cantidad',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> cantidadBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cantidad',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      destinoIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'destinoId',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      destinoIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'destinoId',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> destinoIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destinoId',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      destinoIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'destinoId',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> destinoIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'destinoId',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> destinoIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'destinoId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> estadoItemEqualTo(
    EstadoPedido value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estadoItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      estadoItemGreaterThan(
    EstadoPedido value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'estadoItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      estadoItemLessThan(
    EstadoPedido value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'estadoItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> estadoItemBetween(
    EstadoPedido lower,
    EstadoPedido upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'estadoItem',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      estadoItemStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'estadoItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      estadoItemEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'estadoItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      estadoItemContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'estadoItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> estadoItemMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'estadoItem',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      estadoItemIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estadoItem',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      estadoItemIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'estadoItem',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nombreDestino',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nombreDestino',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombreDestino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nombreDestino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nombreDestino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nombreDestino',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nombreDestino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nombreDestino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nombreDestino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nombreDestino',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombreDestino',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreDestinoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nombreDestino',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombreProducto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nombreProducto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nombreProducto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nombreProducto',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nombreProducto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nombreProducto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nombreProducto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nombreProducto',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombreProducto',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      nombreProductoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nombreProducto',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notas',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notas',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notas',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notas',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> notasIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notas',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      notasIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notas',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      precioUnitarioEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'precioUnitario',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      precioUnitarioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'precioUnitario',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      precioUnitarioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'precioUnitario',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      precioUnitarioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'precioUnitario',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> productoIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productoId',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      productoIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productoId',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      productoIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productoId',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> productoIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productoId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> subtotalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition>
      subtotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> subtotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ItemPedido, ItemPedido, QAfterFilterCondition> subtotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ItemPedidoQueryObject
    on QueryBuilder<ItemPedido, ItemPedido, QFilterCondition> {}
