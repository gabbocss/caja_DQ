// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'configuracion_buffet.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetConfiguracionBuffetCollection on Isar {
  IsarCollection<ConfiguracionBuffet> get configuracionBuffets =>
      this.collection();
}

const ConfiguracionBuffetSchema = CollectionSchema(
  name: r'ConfiguracionBuffet',
  id: 39734388552656899,
  properties: {
    r'activo': PropertySchema(
      id: 0,
      name: r'activo',
      type: IsarType.bool,
    ),
    r'colorTema': PropertySchema(
      id: 1,
      name: r'colorTema',
      type: IsarType.string,
    ),
    r'descripcion': PropertySchema(
      id: 2,
      name: r'descripcion',
      type: IsarType.string,
    ),
    r'diaSemana': PropertySchema(
      id: 3,
      name: r'diaSemana',
      type: IsarType.long,
    ),
    r'edadMaximaInfantil': PropertySchema(
      id: 4,
      name: r'edadMaximaInfantil',
      type: IsarType.long,
    ),
    r'edadMinimaInfantil': PropertySchema(
      id: 5,
      name: r'edadMinimaInfantil',
      type: IsarType.long,
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
    r'horaFin': PropertySchema(
      id: 8,
      name: r'horaFin',
      type: IsarType.string,
    ),
    r'horaInicio': PropertySchema(
      id: 9,
      name: r'horaInicio',
      type: IsarType.string,
    ),
    r'mensajePromocion': PropertySchema(
      id: 10,
      name: r'mensajePromocion',
      type: IsarType.string,
    ),
    r'nombre': PropertySchema(
      id: 11,
      name: r'nombre',
      type: IsarType.string,
    ),
    r'precioAdulto': PropertySchema(
      id: 12,
      name: r'precioAdulto',
      type: IsarType.double,
    ),
    r'precioMenor': PropertySchema(
      id: 13,
      name: r'precioMenor',
      type: IsarType.double,
    ),
    r'precioNino': PropertySchema(
      id: 14,
      name: r'precioNino',
      type: IsarType.double,
    )
  },
  estimateSize: _configuracionBuffetEstimateSize,
  serialize: _configuracionBuffetSerialize,
  deserialize: _configuracionBuffetDeserialize,
  deserializeProp: _configuracionBuffetDeserializeProp,
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
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _configuracionBuffetGetId,
  getLinks: _configuracionBuffetGetLinks,
  attach: _configuracionBuffetAttach,
  version: '3.1.0+1',
);

int _configuracionBuffetEstimateSize(
  ConfiguracionBuffet object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.colorTema;
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
  bytesCount += 3 + object.horaFin.length * 3;
  bytesCount += 3 + object.horaInicio.length * 3;
  {
    final value = object.mensajePromocion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nombre.length * 3;
  return bytesCount;
}

void _configuracionBuffetSerialize(
  ConfiguracionBuffet object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.activo);
  writer.writeString(offsets[1], object.colorTema);
  writer.writeString(offsets[2], object.descripcion);
  writer.writeLong(offsets[3], object.diaSemana);
  writer.writeLong(offsets[4], object.edadMaximaInfantil);
  writer.writeLong(offsets[5], object.edadMinimaInfantil);
  writer.writeDateTime(offsets[6], object.fechaCreacion);
  writer.writeDateTime(offsets[7], object.fechaModificacion);
  writer.writeString(offsets[8], object.horaFin);
  writer.writeString(offsets[9], object.horaInicio);
  writer.writeString(offsets[10], object.mensajePromocion);
  writer.writeString(offsets[11], object.nombre);
  writer.writeDouble(offsets[12], object.precioAdulto);
  writer.writeDouble(offsets[13], object.precioMenor);
  writer.writeDouble(offsets[14], object.precioNino);
}

ConfiguracionBuffet _configuracionBuffetDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ConfiguracionBuffet();
  object.activo = reader.readBool(offsets[0]);
  object.colorTema = reader.readStringOrNull(offsets[1]);
  object.descripcion = reader.readStringOrNull(offsets[2]);
  object.diaSemana = reader.readLongOrNull(offsets[3]);
  object.edadMaximaInfantil = reader.readLong(offsets[4]);
  object.edadMinimaInfantil = reader.readLong(offsets[5]);
  object.fechaCreacion = reader.readDateTime(offsets[6]);
  object.fechaModificacion = reader.readDateTimeOrNull(offsets[7]);
  object.horaFin = reader.readString(offsets[8]);
  object.horaInicio = reader.readString(offsets[9]);
  object.id = id;
  object.mensajePromocion = reader.readStringOrNull(offsets[10]);
  object.nombre = reader.readString(offsets[11]);
  object.precioAdulto = reader.readDouble(offsets[12]);
  object.precioMenor = reader.readDouble(offsets[13]);
  object.precioNino = reader.readDouble(offsets[14]);
  return object;
}

P _configuracionBuffetDeserializeProp<P>(
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
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _configuracionBuffetGetId(ConfiguracionBuffet object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _configuracionBuffetGetLinks(
    ConfiguracionBuffet object) {
  return [];
}

void _configuracionBuffetAttach(
    IsarCollection<dynamic> col, Id id, ConfiguracionBuffet object) {
  object.id = id;
}

extension ConfiguracionBuffetByIndex on IsarCollection<ConfiguracionBuffet> {
  Future<ConfiguracionBuffet?> getByNombre(String nombre) {
    return getByIndex(r'nombre', [nombre]);
  }

  ConfiguracionBuffet? getByNombreSync(String nombre) {
    return getByIndexSync(r'nombre', [nombre]);
  }

  Future<bool> deleteByNombre(String nombre) {
    return deleteByIndex(r'nombre', [nombre]);
  }

  bool deleteByNombreSync(String nombre) {
    return deleteByIndexSync(r'nombre', [nombre]);
  }

  Future<List<ConfiguracionBuffet?>> getAllByNombre(List<String> nombreValues) {
    final values = nombreValues.map((e) => [e]).toList();
    return getAllByIndex(r'nombre', values);
  }

  List<ConfiguracionBuffet?> getAllByNombreSync(List<String> nombreValues) {
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

  Future<Id> putByNombre(ConfiguracionBuffet object) {
    return putByIndex(r'nombre', object);
  }

  Id putByNombreSync(ConfiguracionBuffet object, {bool saveLinks = true}) {
    return putByIndexSync(r'nombre', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByNombre(List<ConfiguracionBuffet> objects) {
    return putAllByIndex(r'nombre', objects);
  }

  List<Id> putAllByNombreSync(List<ConfiguracionBuffet> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'nombre', objects, saveLinks: saveLinks);
  }
}

extension ConfiguracionBuffetQueryWhereSort
    on QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QWhere> {
  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ConfiguracionBuffetQueryWhere
    on QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QWhereClause> {
  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterWhereClause>
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterWhereClause>
      nombreEqualTo(String nombre) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nombre',
        value: [nombre],
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterWhereClause>
      nombreNotEqualTo(String nombre) {
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
}

extension ConfiguracionBuffetQueryFilter on QueryBuilder<ConfiguracionBuffet,
    ConfiguracionBuffet, QFilterCondition> {
  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      activoEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activo',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'colorTema',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'colorTema',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorTema',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorTema',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorTema',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorTema',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'colorTema',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'colorTema',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorTema',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorTema',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorTema',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      colorTemaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorTema',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'descripcion',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'descripcion',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionEqualTo(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionLessThan(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionBetween(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionStartsWith(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionEndsWith(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'descripcion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'descripcion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descripcion',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      descripcionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'descripcion',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      diaSemanaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'diaSemana',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      diaSemanaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'diaSemana',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      diaSemanaEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'diaSemana',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      diaSemanaGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'diaSemana',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      diaSemanaLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'diaSemana',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      diaSemanaBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'diaSemana',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      edadMaximaInfantilEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'edadMaximaInfantil',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      edadMaximaInfantilGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'edadMaximaInfantil',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      edadMaximaInfantilLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'edadMaximaInfantil',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      edadMaximaInfantilBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'edadMaximaInfantil',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      edadMinimaInfantilEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'edadMinimaInfantil',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      edadMinimaInfantilGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'edadMinimaInfantil',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      edadMinimaInfantilLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'edadMinimaInfantil',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      edadMinimaInfantilBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'edadMinimaInfantil',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      fechaCreacionEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaCreacion',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      fechaCreacionLessThan(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      fechaCreacionBetween(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      fechaModificacionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fechaModificacion',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      fechaModificacionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fechaModificacion',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      fechaModificacionEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fechaModificacion',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'horaFin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'horaFin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'horaFin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'horaFin',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'horaFin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'horaFin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'horaFin',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'horaFin',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'horaFin',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaFinIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'horaFin',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'horaInicio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'horaInicio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'horaInicio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'horaInicio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'horaInicio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'horaInicio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'horaInicio',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'horaInicio',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'horaInicio',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      horaInicioIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'horaInicio',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mensajePromocion',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mensajePromocion',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mensajePromocion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mensajePromocion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mensajePromocion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mensajePromocion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mensajePromocion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mensajePromocion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mensajePromocion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mensajePromocion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mensajePromocion',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      mensajePromocionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mensajePromocion',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreEqualTo(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreGreaterThan(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreLessThan(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreBetween(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreStartsWith(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreEndsWith(
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

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nombre',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nombre',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nombre',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      nombreIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nombre',
        value: '',
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioAdultoEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'precioAdulto',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioAdultoGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'precioAdulto',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioAdultoLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'precioAdulto',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioAdultoBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'precioAdulto',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioMenorEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'precioMenor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioMenorGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'precioMenor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioMenorLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'precioMenor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioMenorBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'precioMenor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioNinoEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'precioNino',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioNinoGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'precioNino',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioNinoLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'precioNino',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterFilterCondition>
      precioNinoBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'precioNino',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ConfiguracionBuffetQueryObject on QueryBuilder<ConfiguracionBuffet,
    ConfiguracionBuffet, QFilterCondition> {}

extension ConfiguracionBuffetQueryLinks on QueryBuilder<ConfiguracionBuffet,
    ConfiguracionBuffet, QFilterCondition> {}

extension ConfiguracionBuffetQuerySortBy
    on QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QSortBy> {
  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByActivoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByColorTema() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorTema', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByColorTemaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorTema', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByDescripcion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByDescripcionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByDiaSemana() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diaSemana', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByDiaSemanaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diaSemana', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByEdadMaximaInfantil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edadMaximaInfantil', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByEdadMaximaInfantilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edadMaximaInfantil', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByEdadMinimaInfantil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edadMinimaInfantil', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByEdadMinimaInfantilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edadMinimaInfantil', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByFechaModificacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaModificacion', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByFechaModificacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaModificacion', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByHoraFin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horaFin', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByHoraFinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horaFin', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByHoraInicio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horaInicio', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByHoraInicioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horaInicio', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByMensajePromocion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mensajePromocion', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByMensajePromocionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mensajePromocion', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByNombre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByNombreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByPrecioAdulto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioAdulto', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByPrecioAdultoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioAdulto', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByPrecioMenor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioMenor', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByPrecioMenorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioMenor', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByPrecioNino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioNino', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      sortByPrecioNinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioNino', Sort.desc);
    });
  }
}

extension ConfiguracionBuffetQuerySortThenBy
    on QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QSortThenBy> {
  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByActivoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activo', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByColorTema() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorTema', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByColorTemaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorTema', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByDescripcion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByDescripcionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descripcion', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByDiaSemana() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diaSemana', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByDiaSemanaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'diaSemana', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByEdadMaximaInfantil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edadMaximaInfantil', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByEdadMaximaInfantilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edadMaximaInfantil', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByEdadMinimaInfantil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edadMinimaInfantil', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByEdadMinimaInfantilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edadMinimaInfantil', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByFechaCreacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaCreacion', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByFechaModificacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaModificacion', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByFechaModificacionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fechaModificacion', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByHoraFin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horaFin', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByHoraFinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horaFin', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByHoraInicio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horaInicio', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByHoraInicioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'horaInicio', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByMensajePromocion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mensajePromocion', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByMensajePromocionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mensajePromocion', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByNombre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByNombreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nombre', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByPrecioAdulto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioAdulto', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByPrecioAdultoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioAdulto', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByPrecioMenor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioMenor', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByPrecioMenorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioMenor', Sort.desc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByPrecioNino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioNino', Sort.asc);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QAfterSortBy>
      thenByPrecioNinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'precioNino', Sort.desc);
    });
  }
}

extension ConfiguracionBuffetQueryWhereDistinct
    on QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct> {
  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByActivo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activo');
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByColorTema({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorTema', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByDescripcion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'descripcion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByDiaSemana() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'diaSemana');
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByEdadMaximaInfantil() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'edadMaximaInfantil');
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByEdadMinimaInfantil() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'edadMinimaInfantil');
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByFechaCreacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaCreacion');
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByFechaModificacion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fechaModificacion');
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByHoraFin({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'horaFin', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByHoraInicio({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'horaInicio', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByMensajePromocion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mensajePromocion',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByNombre({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nombre', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByPrecioAdulto() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'precioAdulto');
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByPrecioMenor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'precioMenor');
    });
  }

  QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QDistinct>
      distinctByPrecioNino() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'precioNino');
    });
  }
}

extension ConfiguracionBuffetQueryProperty
    on QueryBuilder<ConfiguracionBuffet, ConfiguracionBuffet, QQueryProperty> {
  QueryBuilder<ConfiguracionBuffet, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ConfiguracionBuffet, bool, QQueryOperations> activoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activo');
    });
  }

  QueryBuilder<ConfiguracionBuffet, String?, QQueryOperations>
      colorTemaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorTema');
    });
  }

  QueryBuilder<ConfiguracionBuffet, String?, QQueryOperations>
      descripcionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'descripcion');
    });
  }

  QueryBuilder<ConfiguracionBuffet, int?, QQueryOperations>
      diaSemanaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'diaSemana');
    });
  }

  QueryBuilder<ConfiguracionBuffet, int, QQueryOperations>
      edadMaximaInfantilProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'edadMaximaInfantil');
    });
  }

  QueryBuilder<ConfiguracionBuffet, int, QQueryOperations>
      edadMinimaInfantilProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'edadMinimaInfantil');
    });
  }

  QueryBuilder<ConfiguracionBuffet, DateTime, QQueryOperations>
      fechaCreacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaCreacion');
    });
  }

  QueryBuilder<ConfiguracionBuffet, DateTime?, QQueryOperations>
      fechaModificacionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fechaModificacion');
    });
  }

  QueryBuilder<ConfiguracionBuffet, String, QQueryOperations>
      horaFinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'horaFin');
    });
  }

  QueryBuilder<ConfiguracionBuffet, String, QQueryOperations>
      horaInicioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'horaInicio');
    });
  }

  QueryBuilder<ConfiguracionBuffet, String?, QQueryOperations>
      mensajePromocionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mensajePromocion');
    });
  }

  QueryBuilder<ConfiguracionBuffet, String, QQueryOperations> nombreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nombre');
    });
  }

  QueryBuilder<ConfiguracionBuffet, double, QQueryOperations>
      precioAdultoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'precioAdulto');
    });
  }

  QueryBuilder<ConfiguracionBuffet, double, QQueryOperations>
      precioMenorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'precioMenor');
    });
  }

  QueryBuilder<ConfiguracionBuffet, double, QQueryOperations>
      precioNinoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'precioNino');
    });
  }
}
