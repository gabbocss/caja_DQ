// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destino_impresion.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDestinoImpresionCollection on Isar {
  IsarCollection<DestinoImpresion> get destinoImpresions => this.collection();
}

const DestinoImpresionSchema = CollectionSchema(
  name: r'DestinoImpresion',
  id: -4502643503832516541,
  properties: {
    r'activo': PropertySchema(id: 0, name: r'activo', type: IsarType.bool),
    r'color': PropertySchema(id: 1, name: r'color', type: IsarType.string),
    r'descripcion': PropertySchema(
      id: 2,
      name: r'descripcion',
      type: IsarType.string,
    ),
    r'direccionImpresora': PropertySchema(
      id: 3,
      name: r'direccionImpresora',
      type: IsarType.string,
    ),
    r'fechaCreacion': PropertySchema(
      id: 4,
      name: r'fechaCreacion',
      type: IsarType.dateTime,
    ),
    r'icono': PropertySchema(id: 5, name: r'icono', type: IsarType.string),
    r'nombre': PropertySchema(id: 6, name: r'nombre', type: IsarType.string),
    r'nombreImpresora': PropertySchema(
      id: 7,
      name: r'nombreImpresora',
      type: IsarType.string,
    ),
    r'orden': PropertySchema(id: 8, name: r'orden', type: IsarType.long),
    r'puertoImpresora': PropertySchema(
      id: 9,
      name: r'puertoImpresora',
      type: IsarType.long,
    ),
    r'tipo': PropertySchema(
      id: 10,
      name: r'tipo',
      type: IsarType.string,
      enumMap: _DestinoImpresiontipoEnumValueMap,
    ),
  },

  estimateSize: _destinoImpresionEstimateSize,
  serialize: _destinoImpresionSerialize,
  deserialize: _destinoImpresionDeserialize,
  deserializeProp: _destinoImpresionDeserializeProp,
  idName: r'id',
  indexes: {
    r'nombre': IndexSchema(
      id: -8239814765453414572,
      name: r'nombre',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nombre',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _destinoImpresionGetId,
  getLinks: _destinoImpresionGetLinks,
  attach: _destinoImpresionAttach,
  version: '3.3.2',
);

int _destinoImpresionEstimateSize(
  DestinoImpresion object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.color.length * 3;
  {
    final value = object.descripcion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.direccionImpresora;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.icono.length * 3;
  bytesCount += 3 + object.nombre.length * 3;
  {
    final value = object.nombreImpresora;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tipo.name.length * 3;
  return bytesCount;
}

void _destinoImpresionSerialize(
  DestinoImpresion object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.activo);
  writer.writeString(offsets[1], object.color);
  writer.writeString(offsets[2], object.descripcion);
  writer.writeString(offsets[3], object.direccionImpresora);
  writer.writeDateTime(offsets[4], object.fechaCreacion);
  writer.writeString(offsets[5], object.icono);
  writer.writeString(offsets[6], object.nombre);
  writer.writeString(offsets[7], object.nombreImpresora);
  writer.writeLong(offsets[8], object.orden);
  writer.writeLong(offsets[9], object.puertoImpresora);
  writer.writeString(offsets[10], object.tipo.name);
}

DestinoImpresion _destinoImpresionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DestinoImpresion();
  object.activo = reader.readBool(offsets[0]);
  object.color = reader.readString(offsets[1]);
  object.descripcion = reader.readStringOrNull(offsets[2]);
  object.direccionImpresora = reader.readStringOrNull(offsets[3]);
  object.fechaCreacion = reader.readDateTime(offsets[4]);
  object.icono = reader.readString(offsets[5]);
  object.id = id;
  object.nombre = reader.readString(offsets[6]);
  object.nombreImpresora = reader.readStringOrNull(offsets[7]);
  object.orden = reader.readLong(offsets[8]);
  object.puertoImpresora = reader.readLongOrNull(offsets[9]);
  object.tipo =
      _DestinoImpresiontipoValueEnumMap[reader.readStringOrNull(offsets[10])] ??
      TipoDestino.pantalla;
  return object;
}

P _destinoImpresionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (_DestinoImpresiontipoValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              TipoDestino.pantalla)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DestinoImpresiontipoEnumValueMap = {
  r'pantalla': r'pantalla',
  r'impresora': r'impresora',
  r'ambos': r'ambos',
};
const _DestinoImpresiontipoValueEnumMap = {
  r'pantalla': TipoDestino.pantalla,
  r'impresora': TipoDestino.impresora,
  r'ambos': TipoDestino.ambos,
};

Id _destinoImpresionGetId(DestinoImpresion object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _destinoImpresionGetLinks(DestinoImpresion object) {
  return [];
}

void _destinoImpresionAttach(
  IsarCollection<dynamic> col,
  Id id,
  DestinoImpresion object,
) {
  object.id = id;
}

extension DestinoImpresionByIndex on IsarCollection<DestinoImpresion> {
  Future<DestinoImpresion?> getByNombre(String nombre) {
    return getByIndex(r'nombre', [nombre]);
  }

  DestinoImpresion? getByNombreSync(String nombre) {
    return getByIndexSync(r'nombre', [nombre]);
  }

  Future<bool> deleteByNombre(String nombre) {
    return deleteByIndex(r'nombre', [nombre]);
  }

  bool deleteByNombreSync(String nombre) {
    return deleteByIndexSync(r'nombre', [nombre]);
  }

  Future<List<DestinoImpresion?>> getAllByNombre(List<String> nombreValues) {
    final values = nombreValues.map((e) => [e]).toList();
    return getAllByIndex(r'nombre', values);
  }

  List<DestinoImpresion?> getAllByNombreSync(List<String> nombreValues) {
    final values = nombreValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'nombre', values);
  }

  Future<int> deleteAllByNombre(List<String> nombreValues) {
    final values = nombreValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'nombre', values);
  }

  int deleteAllByNombreSync(List<String> nombreValues) {
    final values = nombreValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'nombre', values);
  }

  Future<Id> putByNombre(DestinoImpresion object) {
    return putByIndex(r'nombre', object);
  }

  Id putByNombreSync(DestinoImpresion object, {bool saveLinks = true}) {
    return putByIndexSync(r'nombre', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNombre(List<DestinoImpresion> objects) {
    return putAllByIndex(r'nombre', objects);
  }

  List<Id> putAllByNombreSync(
    List<DestinoImpresion> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'nombre', objects, saveLinks: saveLinks);
  }
}

extension DestinoImpresionQueryWhereSort
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QWhere> {
  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DestinoImpresionQueryWhere
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QWhereClause> {
  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterWhereClause>
  nombreEqualTo(String nombre) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'nombre', value: [nombre]),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterWhereClause>
  nombreNotEqualTo(String nombre) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nombre',
                lower: [],
                upper: [nombre],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nombre',
                lower: [nombre],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nombre',
                lower: [nombre],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'nombre',
                lower: [],
                upper: [nombre],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension DestinoImpresionQueryFilter
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QFilterCondition> {
  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  activoEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'activo', value: value),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'color',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'color',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'color',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'color',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'color',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'color',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'color',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'color',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'color', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  colorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'color', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'descripcion'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'descripcion'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'descripcion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'descripcion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'descripcion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'descripcion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'descripcion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'descripcion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'descripcion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'descripcion',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'descripcion', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  descripcionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'descripcion', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'direccionImpresora'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'direccionImpresora'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'direccionImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'direccionImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'direccionImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'direccionImpresora',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'direccionImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'direccionImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'direccionImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'direccionImpresora',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'direccionImpresora', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  direccionImpresoraIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'direccionImpresora', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  fechaCreacionEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fechaCreacion', value: value),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  fechaCreacionGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fechaCreacion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  fechaCreacionLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fechaCreacion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  fechaCreacionBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fechaCreacion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'icono',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'icono',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'icono',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'icono',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'icono',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'icono',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'icono',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'icono',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'icono', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  iconoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'icono', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  idGreaterThan(Id? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  idLessThan(Id? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nombre',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nombre',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nombre',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nombre',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nombre',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nombre',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nombre',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nombre',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nombre', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nombre', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'nombreImpresora'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'nombreImpresora'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nombreImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nombreImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nombreImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nombreImpresora',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nombreImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nombreImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nombreImpresora',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nombreImpresora',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nombreImpresora', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  nombreImpresoraIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nombreImpresora', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  ordenEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'orden', value: value),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  ordenGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'orden',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  ordenLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'orden',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  ordenBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'orden',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  puertoImpresoraIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'puertoImpresora'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  puertoImpresoraIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'puertoImpresora'),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  puertoImpresoraEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'puertoImpresora', value: value),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  puertoImpresoraGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'puertoImpresora',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  puertoImpresoraLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'puertoImpresora',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  puertoImpresoraBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'puertoImpresora',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoEqualTo(TipoDestino value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoGreaterThan(
    TipoDestino value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoLessThan(
    TipoDestino value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoBetween(
    TipoDestino lower,
    TipoDestino upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tipo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tipo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tipo', value: ''),
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterFilterCondition>
  tipoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tipo', value: ''),
      );
    });
  }
}

extension DestinoImpresionQueryObject
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QFilterCondition> {}

extension DestinoImpresionQueryLinks
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QFilterCondition> {}

extension DestinoImpresionQuerySortBy
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QSortBy> {
  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByActivoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> sortByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByDescripcion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByDescripcionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByDireccionImpresora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direccionImpresora', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByDireccionImpresoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direccionImpresora', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> sortByIcono() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icono', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByIconoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icono', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByNombre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByNombreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByNombreImpresora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombreImpresora', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByNombreImpresoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombreImpresora', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> sortByOrden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orden', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByOrdenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orden', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByPuertoImpresora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'puertoImpresora', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByPuertoImpresoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'puertoImpresora', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> sortByTipo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  sortByTipoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.desc);
    });
  }
}

extension DestinoImpresionQuerySortThenBy
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QSortThenBy> {
  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByActivoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> thenByColor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByColorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'color', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByDescripcion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByDescripcionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByDireccionImpresora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direccionImpresora', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByDireccionImpresoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direccionImpresora', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> thenByIcono() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icono', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByIconoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'icono', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByNombre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByNombreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByNombreImpresora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombreImpresora', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByNombreImpresoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombreImpresora', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> thenByOrden() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orden', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByOrdenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orden', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByPuertoImpresora() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'puertoImpresora', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByPuertoImpresoraDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'puertoImpresora', Sort.desc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy> thenByTipo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.asc);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QAfterSortBy>
  thenByTipoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.desc);
    });
  }
}

extension DestinoImpresionQueryWhereDistinct
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct> {
  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct>
  distinctByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activo');
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct> distinctByColor({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'color', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct>
  distinctByDescripcion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'descripcion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct>
  distinctByDireccionImpresora({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'direccionImpresora',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct>
  distinctByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaCreacion');
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct> distinctByIcono({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'icono', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct> distinctByNombre({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nombre', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct>
  distinctByNombreImpresora({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'nombreImpresora',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct>
  distinctByOrden() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orden');
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct>
  distinctByPuertoImpresora() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'puertoImpresora');
    });
  }

  QueryBuilder<DestinoImpresion, DestinoImpresion, QDistinct> distinctByTipo({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipo', caseSensitive: caseSensitive);
    });
  }
}

extension DestinoImpresionQueryProperty
    on QueryBuilder<DestinoImpresion, DestinoImpresion, QQueryProperty> {
  QueryBuilder<DestinoImpresion, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DestinoImpresion, bool, QQueryOperations> activoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activo');
    });
  }

  QueryBuilder<DestinoImpresion, String, QQueryOperations> colorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'color');
    });
  }

  QueryBuilder<DestinoImpresion, String?, QQueryOperations>
  descripcionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'descripcion');
    });
  }

  QueryBuilder<DestinoImpresion, String?, QQueryOperations>
  direccionImpresoraProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'direccionImpresora');
    });
  }

  QueryBuilder<DestinoImpresion, DateTime, QQueryOperations>
  fechaCreacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaCreacion');
    });
  }

  QueryBuilder<DestinoImpresion, String, QQueryOperations> iconoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'icono');
    });
  }

  QueryBuilder<DestinoImpresion, String, QQueryOperations> nombreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nombre');
    });
  }

  QueryBuilder<DestinoImpresion, String?, QQueryOperations>
  nombreImpresoraProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nombreImpresora');
    });
  }

  QueryBuilder<DestinoImpresion, int, QQueryOperations> ordenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orden');
    });
  }

  QueryBuilder<DestinoImpresion, int?, QQueryOperations>
  puertoImpresoraProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'puertoImpresora');
    });
  }

  QueryBuilder<DestinoImpresion, TipoDestino, QQueryOperations> tipoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipo');
    });
  }
}
