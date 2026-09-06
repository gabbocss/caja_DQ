// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buffet_limite_qr_mesa.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBuffetLimiteQrMesaCollection on Isar {
  IsarCollection<BuffetLimiteQrMesa> get buffetLimiteQrMesas =>
      this.collection();
}

const BuffetLimiteQrMesaSchema = CollectionSchema(
  name: r'BuffetLimiteQrMesa',
  id: 5498398824549111560,
  properties: {
    r'fechaUltimoEnvioQr': PropertySchema(
      id: 0,
      name: r'fechaUltimoEnvioQr',
      type: IsarType.dateTime,
    ),
    r'mesaNumero': PropertySchema(
      id: 1,
      name: r'mesaNumero',
      type: IsarType.long,
    ),
    r'productosDistintosEnviadosEnVentana': PropertySchema(
      id: 2,
      name: r'productosDistintosEnviadosEnVentana',
      type: IsarType.longList,
    ),
    r'ventanaIdActual': PropertySchema(
      id: 3,
      name: r'ventanaIdActual',
      type: IsarType.long,
    ),
  },

  estimateSize: _buffetLimiteQrMesaEstimateSize,
  serialize: _buffetLimiteQrMesaSerialize,
  deserialize: _buffetLimiteQrMesaDeserialize,
  deserializeProp: _buffetLimiteQrMesaDeserializeProp,
  idName: r'id',
  indexes: {
    r'mesaNumero': IndexSchema(
      id: 3153117696506690401,
      name: r'mesaNumero',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mesaNumero',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _buffetLimiteQrMesaGetId,
  getLinks: _buffetLimiteQrMesaGetLinks,
  attach: _buffetLimiteQrMesaAttach,
  version: '3.3.2',
);

int _buffetLimiteQrMesaEstimateSize(
  BuffetLimiteQrMesa object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.productosDistintosEnviadosEnVentana.length * 8;
  return bytesCount;
}

void _buffetLimiteQrMesaSerialize(
  BuffetLimiteQrMesa object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.fechaUltimoEnvioQr);
  writer.writeLong(offsets[1], object.mesaNumero);
  writer.writeLongList(offsets[2], object.productosDistintosEnviadosEnVentana);
  writer.writeLong(offsets[3], object.ventanaIdActual);
}

BuffetLimiteQrMesa _buffetLimiteQrMesaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BuffetLimiteQrMesa();
  object.fechaUltimoEnvioQr = reader.readDateTimeOrNull(offsets[0]);
  object.id = id;
  object.mesaNumero = reader.readLong(offsets[1]);
  object.productosDistintosEnviadosEnVentana =
      reader.readLongList(offsets[2]) ?? [];
  object.ventanaIdActual = reader.readLong(offsets[3]);
  return object;
}

P _buffetLimiteQrMesaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLongList(offset) ?? []) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _buffetLimiteQrMesaGetId(BuffetLimiteQrMesa object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _buffetLimiteQrMesaGetLinks(
  BuffetLimiteQrMesa object,
) {
  return [];
}

void _buffetLimiteQrMesaAttach(
  IsarCollection<dynamic> col,
  Id id,
  BuffetLimiteQrMesa object,
) {
  object.id = id;
}

extension BuffetLimiteQrMesaByIndex on IsarCollection<BuffetLimiteQrMesa> {
  Future<BuffetLimiteQrMesa?> getByMesaNumero(int mesaNumero) {
    return getByIndex(r'mesaNumero', [mesaNumero]);
  }

  BuffetLimiteQrMesa? getByMesaNumeroSync(int mesaNumero) {
    return getByIndexSync(r'mesaNumero', [mesaNumero]);
  }

  Future<bool> deleteByMesaNumero(int mesaNumero) {
    return deleteByIndex(r'mesaNumero', [mesaNumero]);
  }

  bool deleteByMesaNumeroSync(int mesaNumero) {
    return deleteByIndexSync(r'mesaNumero', [mesaNumero]);
  }

  Future<List<BuffetLimiteQrMesa?>> getAllByMesaNumero(
    List<int> mesaNumeroValues,
  ) {
    final values = mesaNumeroValues.map((e) => [e]).toList();
    return getAllByIndex(r'mesaNumero', values);
  }

  List<BuffetLimiteQrMesa?> getAllByMesaNumeroSync(List<int> mesaNumeroValues) {
    final values = mesaNumeroValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'mesaNumero', values);
  }

  Future<int> deleteAllByMesaNumero(List<int> mesaNumeroValues) {
    final values = mesaNumeroValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'mesaNumero', values);
  }

  int deleteAllByMesaNumeroSync(List<int> mesaNumeroValues) {
    final values = mesaNumeroValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'mesaNumero', values);
  }

  Future<Id> putByMesaNumero(BuffetLimiteQrMesa object) {
    return putByIndex(r'mesaNumero', object);
  }

  Id putByMesaNumeroSync(BuffetLimiteQrMesa object, {bool saveLinks = true}) {
    return putByIndexSync(r'mesaNumero', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMesaNumero(List<BuffetLimiteQrMesa> objects) {
    return putAllByIndex(r'mesaNumero', objects);
  }

  List<Id> putAllByMesaNumeroSync(
    List<BuffetLimiteQrMesa> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'mesaNumero', objects, saveLinks: saveLinks);
  }
}

extension BuffetLimiteQrMesaQueryWhereSort
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QWhere> {
  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhere>
  anyMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'mesaNumero'),
      );
    });
  }
}

extension BuffetLimiteQrMesaQueryWhere
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QWhereClause> {
  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
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

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  idBetween(
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

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  mesaNumeroEqualTo(int mesaNumero) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'mesaNumero', value: [mesaNumero]),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  mesaNumeroNotEqualTo(int mesaNumero) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mesaNumero',
                lower: [],
                upper: [mesaNumero],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mesaNumero',
                lower: [mesaNumero],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mesaNumero',
                lower: [mesaNumero],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mesaNumero',
                lower: [],
                upper: [mesaNumero],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  mesaNumeroGreaterThan(int mesaNumero, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'mesaNumero',
          lower: [mesaNumero],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  mesaNumeroLessThan(int mesaNumero, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'mesaNumero',
          lower: [],
          upper: [mesaNumero],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterWhereClause>
  mesaNumeroBetween(
    int lowerMesaNumero,
    int upperMesaNumero, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'mesaNumero',
          lower: [lowerMesaNumero],
          includeLower: includeLower,
          upper: [upperMesaNumero],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BuffetLimiteQrMesaQueryFilter
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QFilterCondition> {
  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  fechaUltimoEnvioQrIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fechaUltimoEnvioQr'),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  fechaUltimoEnvioQrIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fechaUltimoEnvioQr'),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  fechaUltimoEnvioQrEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fechaUltimoEnvioQr', value: value),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  fechaUltimoEnvioQrGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fechaUltimoEnvioQr',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  fechaUltimoEnvioQrLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fechaUltimoEnvioQr',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  fechaUltimoEnvioQrBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fechaUltimoEnvioQr',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
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

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
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

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
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

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  mesaNumeroEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mesaNumero', value: value),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  mesaNumeroGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mesaNumero',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  mesaNumeroLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mesaNumero',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  mesaNumeroBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mesaNumero',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'productosDistintosEnviadosEnVentana',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productosDistintosEnviadosEnVentana',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productosDistintosEnviadosEnVentana',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productosDistintosEnviadosEnVentana',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'productosDistintosEnviadosEnVentana',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'productosDistintosEnviadosEnVentana',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'productosDistintosEnviadosEnVentana',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'productosDistintosEnviadosEnVentana',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'productosDistintosEnviadosEnVentana',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  productosDistintosEnviadosEnVentanaLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'productosDistintosEnviadosEnVentana',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  ventanaIdActualEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ventanaIdActual', value: value),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  ventanaIdActualGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ventanaIdActual',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  ventanaIdActualLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ventanaIdActual',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterFilterCondition>
  ventanaIdActualBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ventanaIdActual',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension BuffetLimiteQrMesaQueryObject
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QFilterCondition> {}

extension BuffetLimiteQrMesaQueryLinks
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QFilterCondition> {}

extension BuffetLimiteQrMesaQuerySortBy
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QSortBy> {
  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  sortByFechaUltimoEnvioQr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaUltimoEnvioQr', Sort.asc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  sortByFechaUltimoEnvioQrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaUltimoEnvioQr', Sort.desc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  sortByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.asc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  sortByMesaNumeroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.desc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  sortByVentanaIdActual() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ventanaIdActual', Sort.asc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  sortByVentanaIdActualDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ventanaIdActual', Sort.desc);
    });
  }
}

extension BuffetLimiteQrMesaQuerySortThenBy
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QSortThenBy> {
  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  thenByFechaUltimoEnvioQr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaUltimoEnvioQr', Sort.asc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  thenByFechaUltimoEnvioQrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaUltimoEnvioQr', Sort.desc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  thenByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.asc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  thenByMesaNumeroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.desc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  thenByVentanaIdActual() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ventanaIdActual', Sort.asc);
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QAfterSortBy>
  thenByVentanaIdActualDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ventanaIdActual', Sort.desc);
    });
  }
}

extension BuffetLimiteQrMesaQueryWhereDistinct
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QDistinct> {
  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QDistinct>
  distinctByFechaUltimoEnvioQr() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaUltimoEnvioQr');
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QDistinct>
  distinctByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mesaNumero');
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QDistinct>
  distinctByProductosDistintosEnviadosEnVentana() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productosDistintosEnviadosEnVentana');
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QDistinct>
  distinctByVentanaIdActual() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ventanaIdActual');
    });
  }
}

extension BuffetLimiteQrMesaQueryProperty
    on QueryBuilder<BuffetLimiteQrMesa, BuffetLimiteQrMesa, QQueryProperty> {
  QueryBuilder<BuffetLimiteQrMesa, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, DateTime?, QQueryOperations>
  fechaUltimoEnvioQrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaUltimoEnvioQr');
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, int, QQueryOperations> mesaNumeroProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mesaNumero');
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, List<int>, QQueryOperations>
  productosDistintosEnviadosEnVentanaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productosDistintosEnviadosEnVentana');
    });
  }

  QueryBuilder<BuffetLimiteQrMesa, int, QQueryOperations>
  ventanaIdActualProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ventanaIdActual');
    });
  }
}
