// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserva.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReservaCollection on Isar {
  IsarCollection<Reserva> get reservas => this.collection();
}

const ReservaSchema = CollectionSchema(
  name: r'Reserva',
  id: 1737347736423031362,
  properties: {
    r'alergiasNotas': PropertySchema(
      id: 0,
      name: r'alergiasNotas',
      type: IsarType.string,
    ),
    r'estaPendiente': PropertySchema(
      id: 1,
      name: r'estaPendiente',
      type: IsarType.bool,
    ),
    r'estado': PropertySchema(
      id: 2,
      name: r'estado',
      type: IsarType.string,
      enumMap: _ReservaestadoEnumValueMap,
    ),
    r'fechaActualizacion': PropertySchema(
      id: 3,
      name: r'fechaActualizacion',
      type: IsarType.dateTime,
    ),
    r'fechaCreacion': PropertySchema(
      id: 4,
      name: r'fechaCreacion',
      type: IsarType.dateTime,
    ),
    r'fechaHoraLlegada': PropertySchema(
      id: 5,
      name: r'fechaHoraLlegada',
      type: IsarType.dateTime,
    ),
    r'itemsReservados': PropertySchema(
      id: 6,
      name: r'itemsReservados',
      type: IsarType.objectList,
      target: r'ItemReserva',
    ),
    r'mesaAsignada': PropertySchema(
      id: 7,
      name: r'mesaAsignada',
      type: IsarType.long,
    ),
    r'nombreCliente': PropertySchema(
      id: 8,
      name: r'nombreCliente',
      type: IsarType.string,
    ),
    r'numeroPersonas': PropertySchema(
      id: 9,
      name: r'numeroPersonas',
      type: IsarType.long,
    )
  },
  estimateSize: _reservaEstimateSize,
  serialize: _reservaSerialize,
  deserialize: _reservaDeserialize,
  deserializeProp: _reservaDeserializeProp,
  idName: r'id',
  indexes: {
    r'fechaHoraLlegada': IndexSchema(
      id: -6510729066601338323,
      name: r'fechaHoraLlegada',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fechaHoraLlegada',
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
    )
  },
  links: {},
  embeddedSchemas: {r'ItemReserva': ItemReservaSchema},
  getId: _reservaGetId,
  getLinks: _reservaGetLinks,
  attach: _reservaAttach,
  version: '3.1.0+1',
);

int _reservaEstimateSize(
  Reserva object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.alergiasNotas.length * 3;
  bytesCount += 3 + object.estado.name.length * 3;
  bytesCount += 3 + object.itemsReservados.length * 3;
  {
    final offsets = allOffsets[ItemReserva]!;
    for (var i = 0; i < object.itemsReservados.length; i++) {
      final value = object.itemsReservados[i];
      bytesCount += ItemReservaSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.nombreCliente.length * 3;
  return bytesCount;
}

void _reservaSerialize(
  Reserva object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.alergiasNotas);
  writer.writeBool(offsets[1], object.estaPendiente);
  writer.writeString(offsets[2], object.estado.name);
  writer.writeDateTime(offsets[3], object.fechaActualizacion);
  writer.writeDateTime(offsets[4], object.fechaCreacion);
  writer.writeDateTime(offsets[5], object.fechaHoraLlegada);
  writer.writeObjectList<ItemReserva>(
    offsets[6],
    allOffsets,
    ItemReservaSchema.serialize,
    object.itemsReservados,
  );
  writer.writeLong(offsets[7], object.mesaAsignada);
  writer.writeString(offsets[8], object.nombreCliente);
  writer.writeLong(offsets[9], object.numeroPersonas);
}

Reserva _reservaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Reserva();
  object.alergiasNotas = reader.readString(offsets[0]);
  object.estado =
      _ReservaestadoValueEnumMap[reader.readStringOrNull(offsets[2])] ??
          EstadoReserva.pendiente;
  object.fechaActualizacion = reader.readDateTime(offsets[3]);
  object.fechaCreacion = reader.readDateTime(offsets[4]);
  object.fechaHoraLlegada = reader.readDateTime(offsets[5]);
  object.id = id;
  object.itemsReservados = reader.readObjectList<ItemReserva>(
        offsets[6],
        ItemReservaSchema.deserialize,
        allOffsets,
        ItemReserva(),
      ) ??
      [];
  object.mesaAsignada = reader.readLongOrNull(offsets[7]);
  object.nombreCliente = reader.readString(offsets[8]);
  object.numeroPersonas = reader.readLong(offsets[9]);
  return object;
}

P _reservaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (_ReservaestadoValueEnumMap[reader.readStringOrNull(offset)] ??
          EstadoReserva.pendiente) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readObjectList<ItemReserva>(
            offset,
            ItemReservaSchema.deserialize,
            allOffsets,
            ItemReserva(),
          ) ??
          []) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ReservaestadoEnumValueMap = {
  r'pendiente': r'pendiente',
  r'sentada': r'sentada',
  r'cancelada': r'cancelada',
};
const _ReservaestadoValueEnumMap = {
  r'pendiente': EstadoReserva.pendiente,
  r'sentada': EstadoReserva.sentada,
  r'cancelada': EstadoReserva.cancelada,
};

Id _reservaGetId(Reserva object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _reservaGetLinks(Reserva object) {
  return [];
}

void _reservaAttach(IsarCollection<dynamic> col, Id id, Reserva object) {
  object.id = id;
}

extension ReservaQueryWhereSort on QueryBuilder<Reserva, Reserva, QWhere> {
  QueryBuilder<Reserva, Reserva, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhere> anyFechaHoraLlegada() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'fechaHoraLlegada'),
      );
    });
  }
}

extension ReservaQueryWhere on QueryBuilder<Reserva, Reserva, QWhereClause> {
  QueryBuilder<Reserva, Reserva, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> idBetween(
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

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> fechaHoraLlegadaEqualTo(
      DateTime fechaHoraLlegada) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fechaHoraLlegada',
        value: [fechaHoraLlegada],
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> fechaHoraLlegadaNotEqualTo(
      DateTime fechaHoraLlegada) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaHoraLlegada',
              lower: [],
              upper: [fechaHoraLlegada],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaHoraLlegada',
              lower: [fechaHoraLlegada],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaHoraLlegada',
              lower: [fechaHoraLlegada],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fechaHoraLlegada',
              lower: [],
              upper: [fechaHoraLlegada],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> fechaHoraLlegadaGreaterThan(
    DateTime fechaHoraLlegada, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaHoraLlegada',
        lower: [fechaHoraLlegada],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> fechaHoraLlegadaLessThan(
    DateTime fechaHoraLlegada, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaHoraLlegada',
        lower: [],
        upper: [fechaHoraLlegada],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> fechaHoraLlegadaBetween(
    DateTime lowerFechaHoraLlegada,
    DateTime upperFechaHoraLlegada, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'fechaHoraLlegada',
        lower: [lowerFechaHoraLlegada],
        includeLower: includeLower,
        upper: [upperFechaHoraLlegada],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> estadoEqualTo(
      EstadoReserva estado) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'estado',
        value: [estado],
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterWhereClause> estadoNotEqualTo(
      EstadoReserva estado) {
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
}

extension ReservaQueryFilter
    on QueryBuilder<Reserva, Reserva, QFilterCondition> {
  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> alergiasNotasEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alergiasNotas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      alergiasNotasGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'alergiasNotas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> alergiasNotasLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'alergiasNotas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> alergiasNotasBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'alergiasNotas',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> alergiasNotasStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'alergiasNotas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> alergiasNotasEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'alergiasNotas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> alergiasNotasContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'alergiasNotas',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> alergiasNotasMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'alergiasNotas',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> alergiasNotasIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'alergiasNotas',
        value: '',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      alergiasNotasIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'alergiasNotas',
        value: '',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estaPendienteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estaPendiente',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoEqualTo(
    EstadoReserva value, {
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoGreaterThan(
    EstadoReserva value, {
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoLessThan(
    EstadoReserva value, {
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoBetween(
    EstadoReserva lower,
    EstadoReserva upper, {
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoStartsWith(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoEndsWith(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoContains(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoMatches(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'estado',
        value: '',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> estadoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'estado',
        value: '',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      fechaActualizacionEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaActualizacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      fechaActualizacionBetween(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> fechaCreacionEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaCreacion',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> fechaCreacionLessThan(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> fechaCreacionBetween(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> fechaHoraLlegadaEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaHoraLlegada',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      fechaHoraLlegadaGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fechaHoraLlegada',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      fechaHoraLlegadaLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fechaHoraLlegada',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> fechaHoraLlegadaBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fechaHoraLlegada',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      itemsReservadosLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'itemsReservados',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      itemsReservadosIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'itemsReservados',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      itemsReservadosIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'itemsReservados',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      itemsReservadosLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'itemsReservados',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      itemsReservadosLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'itemsReservados',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      itemsReservadosLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'itemsReservados',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> mesaAsignadaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mesaAsignada',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      mesaAsignadaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mesaAsignada',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> mesaAsignadaEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mesaAsignada',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> mesaAsignadaGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mesaAsignada',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> mesaAsignadaLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mesaAsignada',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> mesaAsignadaBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mesaAsignada',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> nombreClienteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombreCliente',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      nombreClienteGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nombreCliente',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> nombreClienteLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nombreCliente',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> nombreClienteBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nombreCliente',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> nombreClienteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nombreCliente',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> nombreClienteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nombreCliente',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> nombreClienteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nombreCliente',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> nombreClienteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nombreCliente',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> nombreClienteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombreCliente',
        value: '',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      nombreClienteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nombreCliente',
        value: '',
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> numeroPersonasEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numeroPersonas',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition>
      numeroPersonasGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numeroPersonas',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> numeroPersonasLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numeroPersonas',
        value: value,
      ));
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> numeroPersonasBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numeroPersonas',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ReservaQueryObject
    on QueryBuilder<Reserva, Reserva, QFilterCondition> {
  QueryBuilder<Reserva, Reserva, QAfterFilterCondition> itemsReservadosElement(
      FilterQuery<ItemReserva> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'itemsReservados');
    });
  }
}

extension ReservaQueryLinks
    on QueryBuilder<Reserva, Reserva, QFilterCondition> {}

extension ReservaQuerySortBy on QueryBuilder<Reserva, Reserva, QSortBy> {
  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByAlergiasNotas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alergiasNotas', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByAlergiasNotasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alergiasNotas', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByEstaPendiente() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estaPendiente', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByEstaPendienteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estaPendiente', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByEstado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByEstadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByFechaActualizacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByFechaHoraLlegada() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaHoraLlegada', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByFechaHoraLlegadaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaHoraLlegada', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByMesaAsignada() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaAsignada', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByMesaAsignadaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaAsignada', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByNombreCliente() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombreCliente', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByNombreClienteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombreCliente', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByNumeroPersonas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numeroPersonas', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> sortByNumeroPersonasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numeroPersonas', Sort.desc);
    });
  }
}

extension ReservaQuerySortThenBy
    on QueryBuilder<Reserva, Reserva, QSortThenBy> {
  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByAlergiasNotas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alergiasNotas', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByAlergiasNotasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'alergiasNotas', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByEstaPendiente() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estaPendiente', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByEstaPendienteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estaPendiente', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByEstado() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByEstadoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'estado', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByFechaActualizacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaActualizacion', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByFechaHoraLlegada() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaHoraLlegada', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByFechaHoraLlegadaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaHoraLlegada', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByMesaAsignada() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaAsignada', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByMesaAsignadaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mesaAsignada', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByNombreCliente() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombreCliente', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByNombreClienteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombreCliente', Sort.desc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByNumeroPersonas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numeroPersonas', Sort.asc);
    });
  }

  QueryBuilder<Reserva, Reserva, QAfterSortBy> thenByNumeroPersonasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numeroPersonas', Sort.desc);
    });
  }
}

extension ReservaQueryWhereDistinct
    on QueryBuilder<Reserva, Reserva, QDistinct> {
  QueryBuilder<Reserva, Reserva, QDistinct> distinctByAlergiasNotas(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'alergiasNotas',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reserva, Reserva, QDistinct> distinctByEstaPendiente() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estaPendiente');
    });
  }

  QueryBuilder<Reserva, Reserva, QDistinct> distinctByEstado(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'estado', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reserva, Reserva, QDistinct> distinctByFechaActualizacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaActualizacion');
    });
  }

  QueryBuilder<Reserva, Reserva, QDistinct> distinctByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaCreacion');
    });
  }

  QueryBuilder<Reserva, Reserva, QDistinct> distinctByFechaHoraLlegada() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaHoraLlegada');
    });
  }

  QueryBuilder<Reserva, Reserva, QDistinct> distinctByMesaAsignada() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mesaAsignada');
    });
  }

  QueryBuilder<Reserva, Reserva, QDistinct> distinctByNombreCliente(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nombreCliente',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Reserva, Reserva, QDistinct> distinctByNumeroPersonas() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numeroPersonas');
    });
  }
}

extension ReservaQueryProperty
    on QueryBuilder<Reserva, Reserva, QQueryProperty> {
  QueryBuilder<Reserva, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Reserva, String, QQueryOperations> alergiasNotasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'alergiasNotas');
    });
  }

  QueryBuilder<Reserva, bool, QQueryOperations> estaPendienteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estaPendiente');
    });
  }

  QueryBuilder<Reserva, EstadoReserva, QQueryOperations> estadoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'estado');
    });
  }

  QueryBuilder<Reserva, DateTime, QQueryOperations>
      fechaActualizacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaActualizacion');
    });
  }

  QueryBuilder<Reserva, DateTime, QQueryOperations> fechaCreacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaCreacion');
    });
  }

  QueryBuilder<Reserva, DateTime, QQueryOperations> fechaHoraLlegadaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaHoraLlegada');
    });
  }

  QueryBuilder<Reserva, List<ItemReserva>, QQueryOperations>
      itemsReservadosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemsReservados');
    });
  }

  QueryBuilder<Reserva, int?, QQueryOperations> mesaAsignadaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mesaAsignada');
    });
  }

  QueryBuilder<Reserva, String, QQueryOperations> nombreClienteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nombreCliente');
    });
  }

  QueryBuilder<Reserva, int, QQueryOperations> numeroPersonasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numeroPersonas');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ItemReservaSchema = Schema(
  name: r'ItemReserva',
  id: -6389787503835117458,
  properties: {
    r'cantidad': PropertySchema(
      id: 0,
      name: r'cantidad',
      type: IsarType.long,
    ),
    r'nombreProducto': PropertySchema(
      id: 1,
      name: r'nombreProducto',
      type: IsarType.string,
    ),
    r'precioUnitario': PropertySchema(
      id: 2,
      name: r'precioUnitario',
      type: IsarType.double,
    ),
    r'productoId': PropertySchema(
      id: 3,
      name: r'productoId',
      type: IsarType.long,
    ),
    r'subtotal': PropertySchema(
      id: 4,
      name: r'subtotal',
      type: IsarType.double,
    )
  },
  estimateSize: _itemReservaEstimateSize,
  serialize: _itemReservaSerialize,
  deserialize: _itemReservaDeserialize,
  deserializeProp: _itemReservaDeserializeProp,
);

int _itemReservaEstimateSize(
  ItemReserva object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.nombreProducto.length * 3;
  return bytesCount;
}

void _itemReservaSerialize(
  ItemReserva object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.cantidad);
  writer.writeString(offsets[1], object.nombreProducto);
  writer.writeDouble(offsets[2], object.precioUnitario);
  writer.writeLong(offsets[3], object.productoId);
  writer.writeDouble(offsets[4], object.subtotal);
}

ItemReserva _itemReservaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ItemReserva();
  object.cantidad = reader.readLong(offsets[0]);
  object.nombreProducto = reader.readString(offsets[1]);
  object.precioUnitario = reader.readDouble(offsets[2]);
  object.productoId = reader.readLong(offsets[3]);
  return object;
}

P _itemReservaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ItemReservaQueryFilter
    on QueryBuilder<ItemReserva, ItemReserva, QFilterCondition> {
  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition> cantidadEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cantidad',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
      cantidadLessThan(
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition> cantidadBetween(
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
      nombreProductoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nombreProducto',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
      nombreProductoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nombreProducto',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
      nombreProductoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombreProducto',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
      nombreProductoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nombreProducto',
        value: '',
      ));
    });
  }

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
      productoIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productoId',
        value: value,
      ));
    });
  }

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
      productoIdBetween(
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition> subtotalEqualTo(
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition>
      subtotalLessThan(
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

  QueryBuilder<ItemReserva, ItemReserva, QAfterFilterCondition> subtotalBetween(
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

extension ItemReservaQueryObject
    on QueryBuilder<ItemReserva, ItemReserva, QFilterCondition> {}
