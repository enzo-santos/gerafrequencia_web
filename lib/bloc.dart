import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gerafrequencia/gerafrequencia.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

part 'bloc.g.dart';

enum TabType {
  general,
  departments,
  divisions,
  employees,
}

@CopyWith()
class Properties {
  final Config config;
  final List<Department> departments;
  final List<Division> divisions;
  final List<Employee> employees;

  factory Properties.empty() {
    final DateTime dt = DateTime.now();
    return Properties(
      config: Config(
        year: dt.year,
        month: dt.month,
        headerData: null,
        fill: false,
        holidays: [],
        additionalHolidays: [],
      ),
      departments: [],
      divisions: [],
      employees: [],
    );
  }

  const Properties({
    required this.config,
    required this.departments,
    required this.divisions,
    required this.employees,
  });

  DateTime get date {
    return DateTime(config.year, config.month);
  }
}

enum HolidayType {
  required,
  optional,
}

@CopyWith()
class AppState {
  final Properties? loadedProperties;
  final Properties? currentProperties;
  final TabType? currentTabType;
  final bool editingState;

  const AppState({
    required this.loadedProperties,
    required this.currentProperties,
    required this.currentTabType,
    required this.editingState,
  });

  Properties? get activeProperties {
    final Properties? loadedProperties = this.loadedProperties;
    final Properties? currentProperties = this.currentProperties;
    if (currentProperties == null) {
      return loadedProperties;
    }
    return currentProperties;
  }
}

class AppBloc extends Cubit<AppState> {
  AppBloc.initial()
      : this(const AppState(
          loadedProperties: null,
          currentProperties: null,
          currentTabType: null,
          editingState: false,
        ));

  AppBloc(super.initialState);

  void onNew() {
    emit(AppState(
      loadedProperties: Properties.empty(),
      currentProperties: null,
      currentTabType: null,
      editingState: false,
    ));
  }

  void onOpen() async {
    final FilePickerResult? result =
        await GetIt.instance.get<FilePicker>().pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['gfreq'],
    );
    if (result == null) return;
    Uint8List? bytes = result.files.single.bytes;
    if (bytes == null) return null;

    bytes = Uint8List.fromList(GZipDecoder().decodeBytes(bytes));

    final Map jsonMap = json.decode(utf8.decode(bytes));
    final String? encodedHeaderBytes = jsonMap['config_header'];

    final DateTime now = DateTime.now();
    final int month = jsonMap['config_mes'] ?? now.month;
    final int year = jsonMap['config_ano'] ?? now.year;
    final List<int> holidaysDays =
        (jsonMap['config_feriados'] as List?)?.cast<int>() ?? [];
    final List<int> additionalHolidaysDays =
        (jsonMap['config_facultados'] as List?)?.cast<int>() ?? [];
    emit(AppState(
      loadedProperties: Properties(
        config: Config(
          year: year,
          month: month,
          holidays: holidaysDays,
          additionalHolidays: additionalHolidaysDays,
          fill: false,
          headerData: encodedHeaderBytes == null
              ? null
              : BinaryData(base64.decode(encodedHeaderBytes)),
        ),
        divisions: ((jsonMap['diretorias'] as List?) ?? [])
            .map((data) => Division.fromJson(data))
            .toList(),
        departments: ((jsonMap['departamentos'] as List?) ?? [])
            .map((data) => Department.fromJson(data))
            .toList(),
        employees: ((jsonMap['servidores'] as List?) ?? [])
            .map((data) => Employee.fromJson(data))
            .toList(),
      ),
      currentProperties: null,
      currentTabType: state.currentTabType,
      editingState: false,
    ));
  }

  void onSave() async {
    final Properties? activeProperties = state.activeProperties;
    if (activeProperties == null) return;

    final Uint8List? headerBytes = activeProperties.config.headerData?.bytes;
    final String contents = json.encode({
      'config_ano': activeProperties.config.year,
      'config_mes': activeProperties.config.month,
      'config_feriados': activeProperties.config.holidays,
      'config_facultados': activeProperties.config.additionalHolidays,
      if (headerBytes != null) 'config_header': base64Encode(headerBytes),
      'diretorias': activeProperties.divisions.map((d) => d.toJson()).toList(),
      'departamentos':
          activeProperties.departments.map((d) => d.toJson()).toList(),
      'servidores': activeProperties.employees.map((d) => d.toJson()).toList(),
    });
    Uint8List bytes = utf8.encode(contents);
    bytes = Uint8List.fromList(GZipEncoder().encode(bytes)!);
    await GetIt.instance
        .get<FileSaver>()
        .saveFile(name: 'save.gfreq', bytes: bytes);
  }

  void onExport() async {
    final Properties? activeProperties = state.activeProperties;
    if (activeProperties == null) return;

    await GetIt.instance.get<FileSaver>().saveFile(
          name: 'Frequencia_'
              '${DateFormat('MM-yyyy').format(activeProperties.date)}'
              '.pdf',
          bytes: await createTimesheet(
            config: activeProperties.config,
            allDivisions: activeProperties.divisions,
            allDepartments: activeProperties.departments,
            allEmployees: activeProperties.employees,
          ),
        );
  }

  void onTabSelected(TabType? tabType) {
    emit(state.copyWith(currentTabType: tabType, editingState: false));
  }

  void onSetTabEditing(bool isEditing) {
    emit(state.copyWith(editingState: isEditing));
  }

  void onDaySelected(DateTime dt) {
    final Properties props = state.activeProperties ?? Properties.empty();
    final List<int> holidays = [...props.config.holidays];
    final List<int> additionalHolidays = [...props.config.additionalHolidays];
    final int day = dt.day;

    final int holidaysIndex = holidays.indexOf(day);
    if (holidaysIndex >= 0) {
      // Um feriado, considerar como facultado
      holidays.removeAt(holidaysIndex);
      additionalHolidays.add(day);
    } else {
      final int additionalHolidaysIndex = additionalHolidays.indexOf(day);
      if (additionalHolidaysIndex >= 0) {
        // Um facultado, desconsiderar
        additionalHolidays.removeAt(additionalHolidaysIndex);
      } else {
        // Dia normal, considerar como feriado
        holidays.add(day);
      }
    }
    emit(state.copyWith(
      currentProperties: props.copyWith(
        config: Config(
          year: props.config.year,
          month: props.config.month,
          fill: props.config.fill,
          headerData: props.config.headerData,
          // Updated fields
          holidays: holidays,
          additionalHolidays: additionalHolidays,
        ),
      ),
    ));
  }

  void onMonthSelected(DateTime dt) {
    final Properties props = state.activeProperties ?? Properties.empty();
    emit(state.copyWith(
      currentProperties: props.copyWith(
        config: Config(
          fill: props.config.fill,
          headerData: props.config.headerData,
          // Updated fields
          year: dt.year,
          month: dt.month,
          holidays: [],
          additionalHolidays: [],
        ),
      ),
    ));
  }

  void setHeaderBytes(Uint8List? bytes) {
    final Properties props = state.activeProperties ?? Properties.empty();
    emit(state.copyWith(
      currentProperties: props.copyWith(
        config: Config(
          fill: props.config.fill,
          year: props.config.year,
          month: props.config.month,
          holidays: props.config.holidays,
          additionalHolidays: props.config.additionalHolidays,
          // Updated fields
          headerData: bytes == null ? null : BinaryData(bytes),
        ),
      ),
    ));
  }

  void onUpdateProps(Properties updatedProps) {
    emit(state.copyWith(currentProperties: updatedProps));
  }
}
