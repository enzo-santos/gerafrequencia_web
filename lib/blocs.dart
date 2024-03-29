import 'dart:convert';

import 'package:dartx/dartx.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;
import 'package:gerafrequencia/gerafrequencia.dart';
import 'package:http/http.dart' as http;

class ApiBloc extends Cubit<Map<int, List<Holiday>>> {
  static Future<List<Holiday>> _fetch(int year) async {
    const String token = '3699|aaoxgPYa76lKohtZsybZQqLDQZkjQaO1';
    final Uri url = Uri(
      scheme: 'https',
      host: 'api.invertexto.com',
      pathSegments: ['v1', 'holidays', '$year'],
      queryParameters: {'token': token, 'estado': 'PA'},
    );
    final http.Response response = await http.get(url);
    return (json.decode(response.body) as List)
        .cast<Map>()
        .map(Holiday.fromJson)
        .toList();
  }

  ApiBloc() : super({}) {
    load(DateTime.now().year);
  }

  void load(int year) async {
    final Map<int, List<Holiday>> state = this.state;
    List<Holiday>? holidays = state[year];
    if (holidays != null) return;

    holidays = await _fetch(year);
    emit({...state, year: holidays});
  }
}

class FormBlocResult<T> {
  final T value;
  final int? referenceIndex;

  const FormBlocResult({required this.value, this.referenceIndex});
}

class AddressFieldBloc<ExtraData> extends ffb
    .GroupFieldBloc<ffb.FieldBloc<ffb.FieldBlocStateBase>, ExtraData> {
  final ffb.TextFieldBloc<void> streetName;
  final ffb.TextFieldBloc<void> number;
  final ffb.TextFieldBloc<void> districtName;
  final ffb.TextFieldBloc<void> zipCode;
  final ffb.TextFieldBloc<void> cityName;
  final ffb.TextFieldBloc<void> stateName;

  AddressFieldBloc({
    super.name,
    super.extraData,
    required this.streetName,
    required this.number,
    required this.districtName,
    required this.zipCode,
    required this.cityName,
    required this.stateName,
  }) : super(fieldBlocs: [
          streetName,
          number,
          districtName,
          zipCode,
          cityName,
          stateName,
        ]);

  AddressFieldBloc.of([Address? data])
      : this(
          cityName: ffb.TextFieldBloc(
            initialValue: data?.city ?? '',
            validators: [ffb.FieldBlocValidators.required],
          ),
          stateName: ffb.TextFieldBloc(
            initialValue: data?.state ?? '',
            validators: [ffb.FieldBlocValidators.required],
          ),
          streetName: ffb.TextFieldBloc(
            initialValue: data?.streetName ?? '',
            validators: [ffb.FieldBlocValidators.required],
          ),
          zipCode: ffb.TextFieldBloc(
            initialValue: data?.cep ?? '',
            validators: [
              ffb.FieldBlocValidators.required,
              (text) => RegExp(r'\d{2}\.\d{3}-\d{3}').hasMatch(text)
                  ? null
                  : 'pattern',
            ],
          ),
          districtName: ffb.TextFieldBloc(
            initialValue: data?.district ?? '',
            validators: [ffb.FieldBlocValidators.required],
          ),
          number: ffb.TextFieldBloc(
            initialValue: data?.number.toString() ?? '',
            validators: [
              ffb.FieldBlocValidators.required,
              (text) => int.tryParse(text) == null ? 'pattern' : null,
            ],
          ),
        );

  Address get value => Address(
        streetName: streetName.value,
        number: number.valueToInt!,
        district: districtName.value,
        cep: zipCode.value,
        city: cityName.value,
        state: stateName.value,
      );
}

class DivisionFormBloc extends ffb.FormBloc<FormBlocResult<Division>, void> {
  final int? referenceIndex;
  late final ffb.TextFieldBloc<void> name;
  late final ffb.TextFieldBloc<void> id;
  late final ffb.TextFieldBloc<void> companyName;
  late final AddressFieldBloc<void> address;

  DivisionFormBloc({Division? division, this.referenceIndex})
      : super(
          isEditing: division != null,
        ) {
    name = ffb.TextFieldBloc(
      initialValue: division?.name ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    id = ffb.TextFieldBloc(
      initialValue: division?.id ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    companyName = ffb.TextFieldBloc(
      initialValue: division?.companyName ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    address = AddressFieldBloc.of(division?.address);
    addFieldBlocs(fieldBlocs: [name, id, companyName, address]);
  }

  @override
  void onSubmitting() {
    emitSuccess(
      successResponse: FormBlocResult(
        value: Division(
          name: name.value,
          id: id.value,
          address: address.value,
          companyName: companyName.value,
        ),
        referenceIndex: referenceIndex,
      ),
    );
  }
}

class DepartmentFormBloc
    extends ffb.FormBloc<FormBlocResult<Department>, void> {
  final int? referenceIndex;
  late final ffb.TextFieldBloc<void> name;
  late final ffb.TextFieldBloc<void> id;
  late final ffb.TextFieldBloc<void> phoneNumber;
  late final ffb.TextFieldBloc<void> email;
  late final ffb.SelectFieldBloc<Division, void> division;

  DepartmentFormBloc({
    required List<Division> divisions,
    Department? department,
    this.referenceIndex,
  }) : super(
          isEditing: department != null,
        ) {
    name = ffb.TextFieldBloc(
      initialValue: department?.name ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    id = ffb.TextFieldBloc(
      initialValue: department?.id ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    phoneNumber = ffb.TextFieldBloc(
      initialValue: department?.phoneNumber ?? '',
      validators: [
        ffb.FieldBlocValidators.required,
        (text) => RegExp(r'\(\d{2}\) \d?\d{4}-\d{4}').hasMatch(text)
            ? null
            : 'pattern',
      ],
    );
    email = ffb.TextFieldBloc(
      initialValue: department?.email ?? '',
      validators: [
        ffb.FieldBlocValidators.required,
        ffb.FieldBlocValidators.email,
      ],
    );
    final String? divisionKey = department?.location;
    final Division? initialDivisionValue = divisionKey == null
        ? null
        : divisions.firstOrNullWhere((division) =>
            '${division.id}/${division.companyName}' == divisionKey);
    division = ffb.SelectFieldBloc(
      initialValue: initialDivisionValue,
      items: divisions,
      validators: [ffb.FieldBlocValidators.required],
    );
    addFieldBlocs(fieldBlocs: [name, id, phoneNumber, email, division]);
  }

  @override
  void onSubmitting() {
    final Division division = this.division.value!;
    emitSuccess(
      successResponse: FormBlocResult(
        value: Department(
          name: name.value,
          id: id.value,
          phoneNumber: phoneNumber.value,
          email: email.value,
          location: '${division.id}/${division.companyName}',
        ),
        referenceIndex: referenceIndex,
      ),
    );
  }
}

class EmployeeFormBloc extends ffb.FormBloc<FormBlocResult<Employee>, void> {
  final int? referenceIndex;
  late final ffb.TextFieldBloc<void> name;
  late final ffb.TextFieldBloc<void> id;
  late final ffb.TextFieldBloc<void> role;
  late final ffb.SelectFieldBloc<Department, void> department;

  EmployeeFormBloc({
    required List<Department> departments,
    Employee? employee,
    this.referenceIndex,
  }) : super(
          isEditing: employee != null,
        ) {
    name = ffb.TextFieldBloc(
      initialValue: employee?.name ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    id = ffb.TextFieldBloc(
      initialValue: employee?.id ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    role = ffb.TextFieldBloc(
      initialValue: employee?.role ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    final String? departmentKey = employee?.location;
    final Department? initialDepartmentValue = departmentKey == null
        ? null
        : departments.firstOrNullWhere((department) =>
            '${department.id}/${department.location}' == departmentKey);
    department = ffb.SelectFieldBloc(
      initialValue: initialDepartmentValue,
      items: departments,
      validators: [ffb.FieldBlocValidators.required],
    );
    addFieldBlocs(fieldBlocs: [name, id, role, department]);
  }

  @override
  void onSubmitting() {
    final Department department = this.department.value!;
    emitSuccess(
      successResponse: FormBlocResult(
        value: Employee(
          name: name.value,
          id: id.value,
          role: role.value,
          location: '${department.id}/${department.location}',
        ),
        referenceIndex: referenceIndex,
      ),
    );
  }
}
