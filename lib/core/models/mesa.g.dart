// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mesa.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMesaCollection on Isar {
  IsarCollection<Mesa> get mesas => this.collection();
}

const MesaSchema = CollectionSchema(
  name: r'Mesa',
  id: 5173100334568130071,
  properties: {
    r'activa': PropertySchema(
      id: 0,
      name: r'activa',
      type: IsarType.bool,
    ),
    r'capacidad': PropertySchema(
      id: 1,
      name: r'capacidad',
      type: IsarType.long,
    ),
    r'estaDisponible': PropertySchema(
      id: 2,
      name: r'estaDisponible',
      type: IsarType.bool,
    ),
    r'estado': PropertySchema(
      id: 3,
      name: r'estado',
      type: IsarType.string,
      enumMap: _MesaestadoEnumValueMap,
    ),
    r'notas': PropertySchema(
      id: 4,
      name: r'notas',
      type: IsarType.string,
    ),
    r'numero': PropertySchema(
      id: 5,
      name: r'numero',
      type: IsarType.long,
    ),
    r'ubicacion': PropertySchema(
      id: 6,
      name: r'ubicacion',
      type: IsarType.string,
    ),
    r'ultimaActualizacion': PropertySchema(
      id: 7,
      name: r'ultimaActualizacion',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _mesaEstimateSize,
  serialize: _mesaSerialize,
  deserialize: _mesaDeserialize,
  deserializeProp: _mesaDeserializeProp,
  idName: r'id',
  indexes: {
    r'numero': IndexSchema(
      id: -2487710741234600426,
      name: r'numero',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'numero',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _mesaGetId,
  getLinks: _mesaGetLinks,
  attach: _mesaAttach,
  version: '3.1.0+1',
);

int _mesaEstimateSize(
  Mesa object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.estado.name.length * 3;
  {
    final value = object.notas;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.ubicacion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _mesaSerialize(
  Mesa object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.activa);
  writer.writeLong(offsets[1], object.capacidad);
  writer.writeBool(offsets[2], object.estaDisponible);
  writer.writeString(offsets[3], object.estado.name);
  writer.writeString(offsets[4], object.notas);
  writer.writeLong(offsets[5], object.numero);
  writer.writeString(offsets[6], object.ubicacion);
  writer.writeDateTime(offsets[7], object.ultimaActualizacion);
}

Mesa _mesaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Mesa();
  object.activa = reader.readBool(offsets[0]);
  object.capacidad = reader.readLong(offsets[1]);
  object.estado =
      _MesaestadoValueEnumMap[reader.readStringOrNull(offsets[3])] ??
          EstadoMesa.libre;
  object.id = id;
  object.notas = reader.readStringOrNull(offsets[4]);
  object.numero = reader.readLong(offsets[5]);
  object.ubicacion = reader.readStringOrNull(offsets[6]);
  object.ultimaActualizacion = reader.readDateTime(offsets[7]);
  return object;
}

P _mesaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (_MesaestadoValueEnumMap[reader.readStringOrNull(offset)] ??
          EstadoMesa.libre) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MesaestadoEnumValueMap = {
  r'libre': r'libre',
  r'ocupada': r'ocupada',
  r'reservada': r'reservada',
  r'enLimpieza': r'enLimpieza',
};
const _MesaestadoValueEnumMap = {
  r'libre': EstadoMesa.libre,
  r'ocupada': EstadoMesa.ocupada,
  r'reservada': EstadoMesa.reservada,
  r'enLimpieza': EstadoMesa.enLimpieza,
};

Id _mesaGetId(Mesa object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _mesaGetLinks(Mesa object) {
  return [];
}

void _mesaAttach(IsarCollection<dynamic> col, Id id, Mesa object) {
  object.id = id;
}

extension MesaByIndex on IsarCollection<Mesa> {
  Future<Mesa?> getByNumero(int numero) {
    return getByIndex(r'numero', [numero]);
  }

  Mesa? getByNumeroSync(int numero) {
    return getByIndexSync(r'numero', [numero]);
  }

  Future<bool> deleteByNumero(int numero) {
    return deleteByIndex(r'numero', [numero]);
  }

  bool deleteByNumeroSync(int numero) {
    return deleteByIndexSync(r'numero', [numero]);
  }

  Future<List<Mesa?>> getAllByNumero(List<int> numeroValues) {
    final values = numeroValues.map((e) => [e]).toList();
    return getAllByIndex(r'numero', values);
  }

  List<Mesa?> getAllByNumeroSync(List<int> numeroValues) {
    final values = numeroValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'numero', values);
  }

  Future<int> deleteAllByNumero(List<int> numeroValues) {
    final values = numeroValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'numero', values);
  }

  int deleteAllByNumeroSync(List<int> numeroValues) {
    final values = numeroValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'numero', values);
  }

  Future<Id> putByNumero(Mesa object) {
    return putByIndex(r'numero', object);
  }

  Id putByNumeroSync(Mesa object, {bool saveLinks = true}) {
    return putByIndexSync(r'numero', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNumero(List<Mesa> objects) {
    return putAllByIndex(r'numero', objects);
  }

  List<Id> putAllByNumeroSync(List<Mesa> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'numero', objects, saveLinks: saveLinks);
  }
}

extension MesaQueryWhereSort on QueryBuilder<Mesa, Mesa, QWhere> {
  QueryBuilder<Mesa, Mesa, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterWhere> anyNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'numero'),
      );
    });
  }
}

extension MesaQueryWhere on QueryBuilder<Mesa, Mesa, QWhereClause> {
  QueryBuilder<Mesa, Mesa, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> idBetween(
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

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> numeroEqualTo(int numero) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'numero',
        value: [numero],
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> numeroNotEqualTo(int numero) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'numero',
              lower: [],
              upper: [numero],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'numero',
              lower: [numero],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'numero',
              lower: [numero],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'numero',
              lower: [],
              upper: [numero],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> numeroGreaterThan(
    int numero, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'numero',
        lower: [numero],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> numeroLessThan(
    int numero, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'numero',
        lower: [],
        upper: [numero],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterWhereClause> numeroBetween(
    int lowerNumero,
    int upperNumero, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'numero',
        lower: [lowerNumero],
        includeLower: includeLower,
        upper: [upperNumero],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MesaQueryFilter on QueryBuilder<Mesa, Mesa, QFilterCondition> {
  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> activaEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activa',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> capacidadEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'capacidad',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> capacidadGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'capacidad',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> capacidadLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'capacidad',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> capacidadBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'capacidad',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estaDisponibleEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estaDisponible',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoEqualTo(
    EstadoMesa value, {
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoGreaterThan(
    EstadoMesa value, {
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoLessThan(
    EstadoMesa value, {
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoBetween(
    EstadoMesa lower,
    EstadoMesa upper, {
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoStartsWith(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoEndsWith(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'estado',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'estado',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estado',
        value: '',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> estadoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'estado',
        value: '',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notas',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notas',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasEqualTo(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasGreaterThan(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasLessThan(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasBetween(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasStartsWith(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasEndsWith(
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

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notas',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notas',
        value: '',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> notasIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notas',
        value: '',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> numeroEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numero',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> numeroGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numero',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> numeroLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numero',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> numeroBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numero',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ubicacion',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ubicacion',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ubicacion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ubicacion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ubicacion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ubicacion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ubicacion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ubicacion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ubicacion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ubicacion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ubicacion',
        value: '',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ubicacionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ubicacion',
        value: '',
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ultimaActualizacionEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ultimaActualizacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition>
      ultimaActualizacionGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ultimaActualizacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ultimaActualizacionLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ultimaActualizacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterFilterCondition> ultimaActualizacionBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ultimaActualizacion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MesaQueryObject on QueryBuilder<Mesa, Mesa, QFilterCondition> {}

extension MesaQueryLinks on QueryBuilder<Mesa, Mesa, QFilterCondition> {}

extension MesaQuerySortBy on QueryBuilder<Mesa, Mesa, QSortBy> {
  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByActiva() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activa', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByActivaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activa', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByCapacidad() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capacidad', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByCapacidadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capacidad', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByEstaDisponible() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estaDisponible', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByEstaDisponibleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estaDisponible', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByEstado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByEstadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByNotas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notas', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByNotasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notas', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numero', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByNumeroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numero', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByUbicacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ubicacion', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByUbicacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ubicacion', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByUltimaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ultimaActualizacion', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> sortByUltimaActualizacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ultimaActualizacion', Sort.desc);
    });
  }
}

extension MesaQuerySortThenBy on QueryBuilder<Mesa, Mesa, QSortThenBy> {
  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByActiva() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activa', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByActivaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activa', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByCapacidad() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capacidad', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByCapacidadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'capacidad', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByEstaDisponible() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estaDisponible', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByEstaDisponibleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estaDisponible', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByEstado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByEstadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByNotas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notas', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByNotasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notas', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numero', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByNumeroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numero', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByUbicacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ubicacion', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByUbicacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ubicacion', Sort.desc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByUltimaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ultimaActualizacion', Sort.asc);
    });
  }

  QueryBuilder<Mesa, Mesa, QAfterSortBy> thenByUltimaActualizacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ultimaActualizacion', Sort.desc);
    });
  }
}

extension MesaQueryWhereDistinct on QueryBuilder<Mesa, Mesa, QDistinct> {
  QueryBuilder<Mesa, Mesa, QDistinct> distinctByActiva() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activa');
    });
  }

  QueryBuilder<Mesa, Mesa, QDistinct> distinctByCapacidad() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'capacidad');
    });
  }

  QueryBuilder<Mesa, Mesa, QDistinct> distinctByEstaDisponible() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estaDisponible');
    });
  }

  QueryBuilder<Mesa, Mesa, QDistinct> distinctByEstado(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estado', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mesa, Mesa, QDistinct> distinctByNotas(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notas', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mesa, Mesa, QDistinct> distinctByNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numero');
    });
  }

  QueryBuilder<Mesa, Mesa, QDistinct> distinctByUbicacion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ubicacion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Mesa, Mesa, QDistinct> distinctByUltimaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ultimaActualizacion');
    });
  }
}

extension MesaQueryProperty on QueryBuilder<Mesa, Mesa, QQueryProperty> {
  QueryBuilder<Mesa, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Mesa, bool, QQueryOperations> activaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activa');
    });
  }

  QueryBuilder<Mesa, int, QQueryOperations> capacidadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'capacidad');
    });
  }

  QueryBuilder<Mesa, bool, QQueryOperations> estaDisponibleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estaDisponible');
    });
  }

  QueryBuilder<Mesa, EstadoMesa, QQueryOperations> estadoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estado');
    });
  }

  QueryBuilder<Mesa, String?, QQueryOperations> notasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notas');
    });
  }

  QueryBuilder<Mesa, int, QQueryOperations> numeroProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numero');
    });
  }

  QueryBuilder<Mesa, String?, QQueryOperations> ubicacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ubicacion');
    });
  }

  QueryBuilder<Mesa, DateTime, QQueryOperations> ultimaActualizacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ultimaActualizacion');
    });
  }
}
