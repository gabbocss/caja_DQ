// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producto.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProductoCollection on Isar {
  IsarCollection<Producto> get productos => this.collection();
}

const ProductoSchema = CollectionSchema(
  name: r'Producto',
  id: -5697193943419826423,
  properties: {
    r'activo': PropertySchema(
      id: 0,
      name: r'activo',
      type: IsarType.bool,
    ),
    r'categoria': PropertySchema(
      id: 1,
      name: r'categoria',
      type: IsarType.string,
    ),
    r'descripcion': PropertySchema(
      id: 2,
      name: r'descripcion',
      type: IsarType.string,
    ),
    r'destino': PropertySchema(
      id: 3,
      name: r'destino',
      type: IsarType.string,
      enumMap: _ProductodestinoEnumValueMap,
    ),
    r'destinoId': PropertySchema(
      id: 4,
      name: r'destinoId',
      type: IsarType.long,
    ),
    r'esBuffet': PropertySchema(
      id: 5,
      name: r'esBuffet',
      type: IsarType.bool,
    ),
    r'fechaCreacion': PropertySchema(
      id: 6,
      name: r'fechaCreacion',
      type: IsarType.dateTime,
    ),
    r'fechaModificacion': PropertySchema(
      id: 7,
      name: r'fechaModificacion',
      type: IsarType.dateTime,
    ),
    r'imagen': PropertySchema(
      id: 8,
      name: r'imagen',
      type: IsarType.string,
    ),
    r'isAvailable': PropertySchema(
      id: 9,
      name: r'isAvailable',
      type: IsarType.bool,
    ),
    r'nombre': PropertySchema(
      id: 10,
      name: r'nombre',
      type: IsarType.string,
    ),
    r'precio': PropertySchema(
      id: 11,
      name: r'precio',
      type: IsarType.double,
    ),
    r'stock': PropertySchema(
      id: 12,
      name: r'stock',
      type: IsarType.long,
    ),
    r'stockDisponible': PropertySchema(
      id: 13,
      name: r'stockDisponible',
      type: IsarType.long,
    ),
    r'usarInventario': PropertySchema(
      id: 14,
      name: r'usarInventario',
      type: IsarType.bool,
    )
  },
  estimateSize: _productoEstimateSize,
  serialize: _productoSerialize,
  deserialize: _productoDeserialize,
  deserializeProp: _productoDeserializeProp,
  idName: r'id',
  indexes: {
    r'nombre': IndexSchema(
      id: -8239814765453414572,
      name: r'nombre',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nombre',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'esBuffet': IndexSchema(
      id: 1612509451709277347,
      name: r'esBuffet',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'esBuffet',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'categoria': IndexSchema(
      id: -697249392299839610,
      name: r'categoria',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'categoria',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'destinoId': IndexSchema(
      id: 868936371468648160,
      name: r'destinoId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'destinoId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'destino': IndexSchema(
      id: 1040399099711712212,
      name: r'destino',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'destino',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'isAvailable': IndexSchema(
      id: -3723543345987067287,
      name: r'isAvailable',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isAvailable',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _productoGetId,
  getLinks: _productoGetLinks,
  attach: _productoAttach,
  version: '3.1.0+1',
);

int _productoEstimateSize(
  Producto object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.categoria;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.descripcion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.destino.name.length * 3;
  {
    final value = object.imagen;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nombre.length * 3;
  return bytesCount;
}

void _productoSerialize(
  Producto object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.activo);
  writer.writeString(offsets[1], object.categoria);
  writer.writeString(offsets[2], object.descripcion);
  writer.writeString(offsets[3], object.destino.name);
  writer.writeLong(offsets[4], object.destinoId);
  writer.writeBool(offsets[5], object.esBuffet);
  writer.writeDateTime(offsets[6], object.fechaCreacion);
  writer.writeDateTime(offsets[7], object.fechaModificacion);
  writer.writeString(offsets[8], object.imagen);
  writer.writeBool(offsets[9], object.isAvailable);
  writer.writeString(offsets[10], object.nombre);
  writer.writeDouble(offsets[11], object.precio);
  writer.writeLong(offsets[12], object.stock);
  writer.writeLong(offsets[13], object.stockDisponible);
  writer.writeBool(offsets[14], object.usarInventario);
}

Producto _productoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Producto();
  object.activo = reader.readBool(offsets[0]);
  object.categoria = reader.readStringOrNull(offsets[1]);
  object.descripcion = reader.readStringOrNull(offsets[2]);
  object.destino =
      _ProductodestinoValueEnumMap[reader.readStringOrNull(offsets[3])] ??
          DestinoProducto.cocina;
  object.destinoId = reader.readLongOrNull(offsets[4]);
  object.esBuffet = reader.readBool(offsets[5]);
  object.fechaCreacion = reader.readDateTime(offsets[6]);
  object.fechaModificacion = reader.readDateTimeOrNull(offsets[7]);
  object.id = id;
  object.imagen = reader.readStringOrNull(offsets[8]);
  object.isAvailable = reader.readBool(offsets[9]);
  object.nombre = reader.readString(offsets[10]);
  object.precio = reader.readDouble(offsets[11]);
  object.stock = reader.readLongOrNull(offsets[12]);
  object.stockDisponible = reader.readLong(offsets[13]);
  object.usarInventario = reader.readBool(offsets[14]);
  return object;
}

P _productoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (_ProductodestinoValueEnumMap[reader.readStringOrNull(offset)] ??
          DestinoProducto.cocina) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ProductodestinoEnumValueMap = {
  r'cocina': r'cocina',
  r'barra': r'barra',
};
const _ProductodestinoValueEnumMap = {
  r'cocina': DestinoProducto.cocina,
  r'barra': DestinoProducto.barra,
};

Id _productoGetId(Producto object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _productoGetLinks(Producto object) {
  return [];
}

void _productoAttach(IsarCollection<dynamic> col, Id id, Producto object) {
  object.id = id;
}

extension ProductoQueryWhereSort on QueryBuilder<Producto, Producto, QWhere> {
  QueryBuilder<Producto, Producto, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhere> anyEsBuffet() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'esBuffet'),
      );
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhere> anyDestinoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'destinoId'),
      );
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhere> anyIsAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isAvailable'),
      );
    });
  }
}

extension ProductoQueryWhere on QueryBuilder<Producto, Producto, QWhereClause> {
  QueryBuilder<Producto, Producto, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Producto, Producto, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> idBetween(
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

  QueryBuilder<Producto, Producto, QAfterWhereClause> nombreEqualTo(
      String nombre) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nombre',
        value: [nombre],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> nombreNotEqualTo(
      String nombre) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nombre',
              lower: [],
              upper: [nombre],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nombre',
              lower: [nombre],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nombre',
              lower: [nombre],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nombre',
              lower: [],
              upper: [nombre],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> esBuffetEqualTo(
      bool esBuffet) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'esBuffet',
        value: [esBuffet],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> esBuffetNotEqualTo(
      bool esBuffet) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'esBuffet',
              lower: [],
              upper: [esBuffet],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'esBuffet',
              lower: [esBuffet],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'esBuffet',
              lower: [esBuffet],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'esBuffet',
              lower: [],
              upper: [esBuffet],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> categoriaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'categoria',
        value: [null],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> categoriaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'categoria',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> categoriaEqualTo(
      String? categoria) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'categoria',
        value: [categoria],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> categoriaNotEqualTo(
      String? categoria) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoria',
              lower: [],
              upper: [categoria],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoria',
              lower: [categoria],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoria',
              lower: [categoria],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'categoria',
              lower: [],
              upper: [categoria],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'destinoId',
        value: [null],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'destinoId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoIdEqualTo(
      int? destinoId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'destinoId',
        value: [destinoId],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoIdNotEqualTo(
      int? destinoId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'destinoId',
              lower: [],
              upper: [destinoId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'destinoId',
              lower: [destinoId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'destinoId',
              lower: [destinoId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'destinoId',
              lower: [],
              upper: [destinoId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoIdGreaterThan(
    int? destinoId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'destinoId',
        lower: [destinoId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoIdLessThan(
    int? destinoId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'destinoId',
        lower: [],
        upper: [destinoId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoIdBetween(
    int? lowerDestinoId,
    int? upperDestinoId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'destinoId',
        lower: [lowerDestinoId],
        includeLower: includeLower,
        upper: [upperDestinoId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoEqualTo(
      DestinoProducto destino) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'destino',
        value: [destino],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> destinoNotEqualTo(
      DestinoProducto destino) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'destino',
              lower: [],
              upper: [destino],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'destino',
              lower: [destino],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'destino',
              lower: [destino],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'destino',
              lower: [],
              upper: [destino],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> isAvailableEqualTo(
      bool isAvailable) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isAvailable',
        value: [isAvailable],
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterWhereClause> isAvailableNotEqualTo(
      bool isAvailable) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isAvailable',
              lower: [],
              upper: [isAvailable],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isAvailable',
              lower: [isAvailable],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isAvailable',
              lower: [isAvailable],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isAvailable',
              lower: [],
              upper: [isAvailable],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ProductoQueryFilter
    on QueryBuilder<Producto, Producto, QFilterCondition> {
  QueryBuilder<Producto, Producto, QAfterFilterCondition> activoEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activo',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'categoria',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'categoria',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'categoria',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'categoria',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'categoria',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> categoriaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'categoria',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      categoriaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'categoria',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'descripcion',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      descripcionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'descripcion',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      descripcionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'descripcion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'descripcion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> descripcionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descripcion',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      descripcionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'descripcion',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoEqualTo(
    DestinoProducto value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoGreaterThan(
    DestinoProducto value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoLessThan(
    DestinoProducto value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoBetween(
    DestinoProducto lower,
    DestinoProducto upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'destino',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'destino',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destino',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'destino',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'destinoId',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'destinoId',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destinoId',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoIdGreaterThan(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoIdLessThan(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition> destinoIdBetween(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition> esBuffetEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'esBuffet',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> fechaCreacionEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaCreacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      fechaCreacionGreaterThan(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition> fechaCreacionLessThan(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition> fechaCreacionBetween(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      fechaModificacionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fechaModificacion',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      fechaModificacionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fechaModificacion',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      fechaModificacionEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaModificacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      fechaModificacionGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fechaModificacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      fechaModificacionLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fechaModificacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      fechaModificacionBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fechaModificacion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagen',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagen',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagen',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagen',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagen',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> imagenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagen',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> isAvailableEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAvailable',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nombre',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nombre',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombre',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> nombreIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nombre',
        value: '',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> precioEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'precio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> precioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'precio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> precioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'precio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> precioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'precio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> stockIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stock',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> stockIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stock',
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> stockEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stock',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> stockGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stock',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> stockLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stock',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> stockBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stock',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      stockDisponibleEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stockDisponible',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      stockDisponibleGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stockDisponible',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      stockDisponibleLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stockDisponible',
        value: value,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition>
      stockDisponibleBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stockDisponible',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Producto, Producto, QAfterFilterCondition> usarInventarioEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usarInventario',
        value: value,
      ));
    });
  }
}

extension ProductoQueryObject
    on QueryBuilder<Producto, Producto, QFilterCondition> {}

extension ProductoQueryLinks
    on QueryBuilder<Producto, Producto, QFilterCondition> {}

extension ProductoQuerySortBy on QueryBuilder<Producto, Producto, QSortBy> {
  QueryBuilder<Producto, Producto, QAfterSortBy> sortByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByActivoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByCategoria() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoria', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByCategoriaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoria', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByDescripcion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByDescripcionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByDestino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByDestinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByDestinoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoId', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByDestinoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoId', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByEsBuffet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esBuffet', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByEsBuffetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esBuffet', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByFechaModificacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaModificacion', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByFechaModificacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaModificacion', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByImagen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagen', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByImagenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagen', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByIsAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAvailable', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByIsAvailableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAvailable', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByNombre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByNombreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByPrecio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precio', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByPrecioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precio', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stock', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByStockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stock', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByStockDisponible() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDisponible', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByStockDisponibleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDisponible', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByUsarInventario() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usarInventario', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> sortByUsarInventarioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usarInventario', Sort.desc);
    });
  }
}

extension ProductoQuerySortThenBy
    on QueryBuilder<Producto, Producto, QSortThenBy> {
  QueryBuilder<Producto, Producto, QAfterSortBy> thenByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByActivoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByCategoria() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoria', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByCategoriaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categoria', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByDescripcion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByDescripcionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByDestino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByDestinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByDestinoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoId', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByDestinoIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinoId', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByEsBuffet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esBuffet', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByEsBuffetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'esBuffet', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByFechaModificacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaModificacion', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByFechaModificacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaModificacion', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByImagen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagen', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByImagenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagen', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByIsAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAvailable', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByIsAvailableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAvailable', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByNombre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByNombreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByPrecio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precio', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByPrecioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precio', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stock', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByStockDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stock', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByStockDisponible() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDisponible', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByStockDisponibleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stockDisponible', Sort.desc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByUsarInventario() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usarInventario', Sort.asc);
    });
  }

  QueryBuilder<Producto, Producto, QAfterSortBy> thenByUsarInventarioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usarInventario', Sort.desc);
    });
  }
}

extension ProductoQueryWhereDistinct
    on QueryBuilder<Producto, Producto, QDistinct> {
  QueryBuilder<Producto, Producto, QDistinct> distinctByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activo');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByCategoria(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categoria', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByDescripcion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'descripcion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByDestino(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'destino', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByDestinoId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'destinoId');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByEsBuffet() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'esBuffet');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaCreacion');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByFechaModificacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaModificacion');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByImagen(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagen', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByIsAvailable() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAvailable');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByNombre(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nombre', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByPrecio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'precio');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByStock() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stock');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByStockDisponible() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stockDisponible');
    });
  }

  QueryBuilder<Producto, Producto, QDistinct> distinctByUsarInventario() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usarInventario');
    });
  }
}

extension ProductoQueryProperty
    on QueryBuilder<Producto, Producto, QQueryProperty> {
  QueryBuilder<Producto, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Producto, bool, QQueryOperations> activoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activo');
    });
  }

  QueryBuilder<Producto, String?, QQueryOperations> categoriaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categoria');
    });
  }

  QueryBuilder<Producto, String?, QQueryOperations> descripcionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'descripcion');
    });
  }

  QueryBuilder<Producto, DestinoProducto, QQueryOperations> destinoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'destino');
    });
  }

  QueryBuilder<Producto, int?, QQueryOperations> destinoIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'destinoId');
    });
  }

  QueryBuilder<Producto, bool, QQueryOperations> esBuffetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'esBuffet');
    });
  }

  QueryBuilder<Producto, DateTime, QQueryOperations> fechaCreacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaCreacion');
    });
  }

  QueryBuilder<Producto, DateTime?, QQueryOperations>
      fechaModificacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaModificacion');
    });
  }

  QueryBuilder<Producto, String?, QQueryOperations> imagenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagen');
    });
  }

  QueryBuilder<Producto, bool, QQueryOperations> isAvailableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAvailable');
    });
  }

  QueryBuilder<Producto, String, QQueryOperations> nombreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nombre');
    });
  }

  QueryBuilder<Producto, double, QQueryOperations> precioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'precio');
    });
  }

  QueryBuilder<Producto, int?, QQueryOperations> stockProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stock');
    });
  }

  QueryBuilder<Producto, int, QQueryOperations> stockDisponibleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stockDisponible');
    });
  }

  QueryBuilder<Producto, bool, QQueryOperations> usarInventarioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usarInventario');
    });
  }
}
