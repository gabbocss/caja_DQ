// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrito_qr_mesa.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCarritoQrMesaCollection on Isar {
  IsarCollection<CarritoQrMesa> get carritoQrMesas => this.collection();
}

const CarritoQrMesaSchema = CollectionSchema(
  name: r'CarritoQrMesa',
  id: 1759962447033786257,
  properties: {
    r'fechaActualizacion': PropertySchema(
      id: 0,
      name: r'fechaActualizacion',
      type: IsarType.dateTime,
    ),
    r'items': PropertySchema(
      id: 1,
      name: r'items',
      type: IsarType.objectList,

      target: r'ItemCarritoQr',
    ),
    r'mesaNumero': PropertySchema(
      id: 2,
      name: r'mesaNumero',
      type: IsarType.long,
    ),
  },

  estimateSize: _carritoQrMesaEstimateSize,
  serialize: _carritoQrMesaSerialize,
  deserialize: _carritoQrMesaDeserialize,
  deserializeProp: _carritoQrMesaDeserializeProp,
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
  embeddedSchemas: {r'ItemCarritoQr': ItemCarritoQrSchema},

  getId: _carritoQrMesaGetId,
  getLinks: _carritoQrMesaGetLinks,
  attach: _carritoQrMesaAttach,
  version: '3.3.2',
);

int _carritoQrMesaEstimateSize(
  CarritoQrMesa object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.items.length * 3;
  {
    final offsets = allOffsets[ItemCarritoQr]!;
    for (var i = 0; i < object.items.length; i++) {
      final value = object.items[i];
      bytesCount += ItemCarritoQrSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  return bytesCount;
}

void _carritoQrMesaSerialize(
  CarritoQrMesa object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.fechaActualizacion);
  writer.writeObjectList<ItemCarritoQr>(
    offsets[1],
    allOffsets,
    ItemCarritoQrSchema.serialize,
    object.items,
  );
  writer.writeLong(offsets[2], object.mesaNumero);
}

CarritoQrMesa _carritoQrMesaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CarritoQrMesa();
  object.fechaActualizacion = reader.readDateTime(offsets[0]);
  object.id = id;
  object.items =
      reader.readObjectList<ItemCarritoQr>(
        offsets[1],
        ItemCarritoQrSchema.deserialize,
        allOffsets,
        ItemCarritoQr(),
      ) ??
      [];
  object.mesaNumero = reader.readLong(offsets[2]);
  return object;
}

P _carritoQrMesaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readObjectList<ItemCarritoQr>(
                offset,
                ItemCarritoQrSchema.deserialize,
                allOffsets,
                ItemCarritoQr(),
              ) ??
              [])
          as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _carritoQrMesaGetId(CarritoQrMesa object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _carritoQrMesaGetLinks(CarritoQrMesa object) {
  return [];
}

void _carritoQrMesaAttach(
  IsarCollection<dynamic> col,
  Id id,
  CarritoQrMesa object,
) {
  object.id = id;
}

extension CarritoQrMesaByIndex on IsarCollection<CarritoQrMesa> {
  Future<CarritoQrMesa?> getByMesaNumero(int mesaNumero) {
    return getByIndex(r'mesaNumero', [mesaNumero]);
  }

  CarritoQrMesa? getByMesaNumeroSync(int mesaNumero) {
    return getByIndexSync(r'mesaNumero', [mesaNumero]);
  }

  Future<bool> deleteByMesaNumero(int mesaNumero) {
    return deleteByIndex(r'mesaNumero', [mesaNumero]);
  }

  bool deleteByMesaNumeroSync(int mesaNumero) {
    return deleteByIndexSync(r'mesaNumero', [mesaNumero]);
  }

  Future<List<CarritoQrMesa?>> getAllByMesaNumero(List<int> mesaNumeroValues) {
    final values = mesaNumeroValues.map((e) => [e]).toList();
    return getAllByIndex(r'mesaNumero', values);
  }

  List<CarritoQrMesa?> getAllByMesaNumeroSync(List<int> mesaNumeroValues) {
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

  Future<Id> putByMesaNumero(CarritoQrMesa object) {
    return putByIndex(r'mesaNumero', object);
  }

  Id putByMesaNumeroSync(CarritoQrMesa object, {bool saveLinks = true}) {
    return putByIndexSync(r'mesaNumero', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMesaNumero(List<CarritoQrMesa> objects) {
    return putAllByIndex(r'mesaNumero', objects);
  }

  List<Id> putAllByMesaNumeroSync(
    List<CarritoQrMesa> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'mesaNumero', objects, saveLinks: saveLinks);
  }
}

extension CarritoQrMesaQueryWhereSort
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QWhere> {
  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhere> anyMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'mesaNumero'),
      );
    });
  }
}

extension CarritoQrMesaQueryWhere
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QWhereClause> {
  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause> idBetween(
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause>
  mesaNumeroEqualTo(int mesaNumero) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'mesaNumero', value: [mesaNumero]),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause>
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause>
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause>
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterWhereClause>
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

extension CarritoQrMesaQueryFilter
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QFilterCondition> {
  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  fechaActualizacionEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fechaActualizacion', value: value),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  fechaActualizacionGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fechaActualizacion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  fechaActualizacionLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fechaActualizacion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  fechaActualizacionBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fechaActualizacion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition> idEqualTo(
    Id? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition> idLessThan(
    Id? value, {
    bool include = false,
  }) {
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  itemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, true, length, true);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  itemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, 0, true);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  itemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, false, 999999, true);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  itemsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', 0, true, length, include);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  itemsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'items', length, include, 999999, true);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  itemsLengthBetween(
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  mesaNumeroEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mesaNumero', value: value),
      );
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
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

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
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
}

extension CarritoQrMesaQueryObject
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QFilterCondition> {
  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterFilterCondition>
  itemsElement(FilterQuery<ItemCarritoQr> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'items');
    });
  }
}

extension CarritoQrMesaQueryLinks
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QFilterCondition> {}

extension CarritoQrMesaQuerySortBy
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QSortBy> {
  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy>
  sortByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.asc);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy>
  sortByFechaActualizacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.desc);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy> sortByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.asc);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy>
  sortByMesaNumeroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.desc);
    });
  }
}

extension CarritoQrMesaQuerySortThenBy
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QSortThenBy> {
  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy>
  thenByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.asc);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy>
  thenByFechaActualizacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.desc);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy> thenByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.asc);
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QAfterSortBy>
  thenByMesaNumeroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaNumero', Sort.desc);
    });
  }
}

extension CarritoQrMesaQueryWhereDistinct
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QDistinct> {
  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QDistinct>
  distinctByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaActualizacion');
    });
  }

  QueryBuilder<CarritoQrMesa, CarritoQrMesa, QDistinct> distinctByMesaNumero() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mesaNumero');
    });
  }
}

extension CarritoQrMesaQueryProperty
    on QueryBuilder<CarritoQrMesa, CarritoQrMesa, QQueryProperty> {
  QueryBuilder<CarritoQrMesa, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CarritoQrMesa, DateTime, QQueryOperations>
  fechaActualizacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaActualizacion');
    });
  }

  QueryBuilder<CarritoQrMesa, List<ItemCarritoQr>, QQueryOperations>
  itemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'items');
    });
  }

  QueryBuilder<CarritoQrMesa, int, QQueryOperations> mesaNumeroProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mesaNumero');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ItemCarritoQrSchema = Schema(
  name: r'ItemCarritoQr',
  id: 4876290624810911542,
  properties: {
    r'cantidad': PropertySchema(id: 0, name: r'cantidad', type: IsarType.long),
    r'destinoId': PropertySchema(
      id: 1,
      name: r'destinoId',
      type: IsarType.long,
    ),
    r'nombreDestino': PropertySchema(
      id: 2,
      name: r'nombreDestino',
      type: IsarType.string,
    ),
    r'nombreProducto': PropertySchema(
      id: 3,
      name: r'nombreProducto',
      type: IsarType.string,
    ),
    r'precioUnitario': PropertySchema(
      id: 4,
      name: r'precioUnitario',
      type: IsarType.double,
    ),
    r'productoId': PropertySchema(
      id: 5,
      name: r'productoId',
      type: IsarType.long,
    ),
  },

  estimateSize: _itemCarritoQrEstimateSize,
  serialize: _itemCarritoQrSerialize,
  deserialize: _itemCarritoQrDeserialize,
  deserializeProp: _itemCarritoQrDeserializeProp,
);

int _itemCarritoQrEstimateSize(
  ItemCarritoQr object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.nombreDestino;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nombreProducto.length * 3;
  return bytesCount;
}

void _itemCarritoQrSerialize(
  ItemCarritoQr object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.cantidad);
  writer.writeLong(offsets[1], object.destinoId);
  writer.writeString(offsets[2], object.nombreDestino);
  writer.writeString(offsets[3], object.nombreProducto);
  writer.writeDouble(offsets[4], object.precioUnitario);
  writer.writeLong(offsets[5], object.productoId);
}

ItemCarritoQr _itemCarritoQrDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ItemCarritoQr();
  object.cantidad = reader.readLong(offsets[0]);
  object.destinoId = reader.readLongOrNull(offsets[1]);
  object.nombreDestino = reader.readStringOrNull(offsets[2]);
  object.nombreProducto = reader.readString(offsets[3]);
  object.precioUnitario = reader.readDouble(offsets[4]);
  object.productoId = reader.readLong(offsets[5]);
  return object;
}

P _itemCarritoQrDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ItemCarritoQrQueryFilter
    on QueryBuilder<ItemCarritoQr, ItemCarritoQr, QFilterCondition> {
  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  cantidadEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cantidad', value: value),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  cantidadGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cantidad',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  cantidadLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cantidad',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  cantidadBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cantidad',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  destinoIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'destinoId'),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  destinoIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'destinoId'),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  destinoIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'destinoId', value: value),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  destinoIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'destinoId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  destinoIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'destinoId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  destinoIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'destinoId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'nombreDestino'),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'nombreDestino'),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nombreDestino',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nombreDestino',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nombreDestino',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nombreDestino',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nombreDestino',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nombreDestino',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nombreDestino',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nombreDestino',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nombreDestino', value: ''),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreDestinoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nombreDestino', value: ''),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'nombreProducto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nombreProducto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nombreProducto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nombreProducto',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'nombreProducto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'nombreProducto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'nombreProducto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'nombreProducto',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nombreProducto', value: ''),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  nombreProductoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'nombreProducto', value: ''),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  precioUnitarioEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'precioUnitario',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  precioUnitarioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'precioUnitario',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  precioUnitarioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'precioUnitario',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  precioUnitarioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'precioUnitario',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  productoIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'productoId', value: value),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  productoIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'productoId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  productoIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'productoId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ItemCarritoQr, ItemCarritoQr, QAfterFilterCondition>
  productoIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'productoId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ItemCarritoQrQueryObject
    on QueryBuilder<ItemCarritoQr, ItemCarritoQr, QFilterCondition> {}
