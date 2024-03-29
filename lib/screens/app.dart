import 'dart:typed_data';

import 'package:dartx/dartx.dart';
import 'package:easy_mask/easy_mask.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;
import 'package:gerafrequencia/gerafrequencia.dart';
import 'package:get_it/get_it.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;
import 'package:table_calendar/table_calendar.dart';

import '../bloc.dart';
import '../blocs.dart';
import '../widgets.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<AppBloc, AppState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    'Gerador de frequências',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                _Toolbar(state: state),
                const SizedBox(height: 20),
                Expanded(
                  child: _Body(state: state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final AppState state;

  const _Toolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final AppBloc bloc = context.read();
    final Properties? activeProperties = state.activeProperties;
    final Widget separator = SizedBox(
      width:
          rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE) ? 5 : 20,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Button(
            label: 'Novo',
            color: Colors.black,
            onPressed: () async {
              // TODO
              bloc.onNew();
            },
          ),
          separator,
          Button(
            label: 'Abrir',
            color: Colors.black,
            onPressed: () => bloc.onOpen(),
          ),
          separator,
          if (activeProperties != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Button(
                  label: 'Salvar',
                  color: Colors.purple,
                  onPressed: () => bloc.onSave(),
                ),
                separator,
                if (activeProperties.employees.isNotEmpty)
                  Button(
                    label: 'Exportar como PDF',
                    color: Colors.purple,
                    onPressed: () => bloc.onExport(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final AppState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    final Properties? properties = state.activeProperties;
    if (properties == null) {
      return const Center(
        child: Text('A área de trabalho está vazia.'),
      );
    }
    if (rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE)) {
      final TabType? currentTabType = state.currentTabType;
      if (currentTabType == null) {
        return const _Navigation();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (state.editingState) {
                      context.read<AppBloc>().onSetTabEditing(false);
                    } else {
                      context.read<AppBloc>().onTabSelected(null);
                    }
                  },
                  icon: const Icon(Icons.chevron_left_outlined),
                  label: const Text('Voltar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: _NavigationBody(state: state, properties: properties),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          flex: 4,
          child: _Navigation(),
        ),
        Expanded(
          flex: 8,
          child: _NavigationBody(state: state, properties: properties),
        ),
      ],
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _NavigationOption.fromTabType(TabType.general),
        const _NavigationOption(label: 'Dados'),
        _NavigationOption.fromTabType(TabType.divisions),
        _NavigationOption.fromTabType(TabType.departments),
        _NavigationOption.fromTabType(TabType.employees),
      ],
    );
  }
}

class _NavigationOption extends StatelessWidget {
  final String label;
  final bool selected;
  final void Function()? onPressed;

  static Widget fromTabType(TabType tabType, {Key? key}) {
    return BlocSelector<AppBloc, AppState, TabType?>(
      key: key,
      selector: (state) => state.currentTabType,
      builder: (context, currentTabType) {
        return _NavigationOption(
          label: switch (tabType) {
            TabType.general => 'Geral',
            TabType.divisions => 'Diretorias',
            TabType.departments => 'Departamentos',
            TabType.employees => 'Servidores',
          },
          selected: currentTabType == tabType,
          onPressed: () => context.read<AppBloc>().onTabSelected(
                currentTabType == tabType ? null : tabType,
              ),
        );
      },
    );
  }

  const _NavigationOption({
    super.key,
    required this.label,
    this.selected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final void Function()? onPressed = this.onPressed;
    Widget child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (onPressed == null
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(color: selected ? Colors.purple : null),
            ),
          ),
          if (onPressed != null)
            Icon(
              Icons.arrow_right,
              color: selected ? Colors.purple : null,
            ),
        ],
      ),
    );
    if (onPressed != null) {
      child = InkWell(onTap: onPressed, child: child);
    }
    return child;
  }
}

class _NavigationBody extends StatelessWidget {
  final AppState state;
  final Properties properties;

  const _NavigationBody({
    required this.state,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    final TabType? currentTabType = state.currentTabType;
    if (currentTabType == null) {
      return const Center(child: Text('Selecione uma aba para visualizar.'));
    }
    switch (currentTabType) {
      case TabType.general:
        return _GeneralTabBody(state: state, properties: properties);
      case TabType.divisions:
        return _DataTabBody<Division, DivisionFormBloc>(
          state: state,
          emptyLabel: 'Nenhuma diretoria inserida.',
          decode: (props) => properties.divisions,
          encode: (props, updater) => Properties(
            config: props.config,
            departments: props.departments,
            divisions: updater(props.divisions),
            employees: props.employees,
          ),
          titleBuilder: (item) => item.id,
          subtitleBuilder: (item) => item.name,
          formBuilder: (item, referenceIndex) => DivisionFormBloc(
            division: item,
            referenceIndex: referenceIndex,
          ),
          formBodyBuilder: (context, bloc) {
            return FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ffb.TextFieldBlocBuilder(
                    textFieldBloc: bloc.name,
                    decoration: const InputDecoration(
                      labelText: 'Nome da diretoria',
                    ),
                  ),
                  ffb.TextFieldBlocBuilder(
                    textFieldBloc: bloc.id,
                    decoration: const InputDecoration(
                      labelText: 'Sigla',
                    ),
                  ),
                  ffb.TextFieldBlocBuilder(
                    textFieldBloc: bloc.companyName,
                    decoration: const InputDecoration(
                      labelText: 'Nome da empresa',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Endereço',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ffb.TextFieldBlocBuilder(
                    textFieldBloc: bloc.address.streetName,
                    decoration: const InputDecoration(
                      labelText: 'Logradouro',
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.address.zipCode,
                          maxLength: 10,
                          inputFormatters: [
                            TextInputMask(mask: '99.999-999'),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'CEP',
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.address.number,
                          maxLength: 5,
                          decoration: const InputDecoration(
                            labelText: 'Número',
                          ),
                        ),
                      ),
                    ],
                  ),
                  ffb.TextFieldBlocBuilder(
                    textFieldBloc: bloc.address.districtName,
                    decoration: const InputDecoration(
                      labelText: 'Bairro',
                    ),
                  ),
                  ffb.TextFieldBlocBuilder(
                    textFieldBloc: bloc.address.cityName,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                    ),
                  ),
                  ffb.TextFieldBlocBuilder(
                    textFieldBloc: bloc.address.stateName,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: 'UF',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case TabType.departments:
        return properties.divisions.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(height: 10),
                    Text('Adicione uma diretoria primeiro.'),
                  ],
                ),
              )
            : _DataTabBody<Department, DepartmentFormBloc>(
                state: state,
                emptyLabel: 'Nenhum departamento inserido.',
                decode: (props) => properties.departments,
                encode: (props, updater) => Properties(
                  config: props.config,
                  departments: updater(props.departments),
                  divisions: props.divisions,
                  employees: props.employees,
                ),
                titleBuilder: (item) => item.id,
                subtitleBuilder: (item) => item.name,
                formBuilder: (item, referenceIndex) => DepartmentFormBloc(
                  divisions: properties.divisions,
                  department: item,
                  referenceIndex: referenceIndex,
                ),
                formBodyBuilder: (context, bloc) {
                  return FocusTraversalGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.name,
                          decoration: const InputDecoration(
                            labelText: 'Nome do departamento',
                          ),
                        ),
                        ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.id,
                          decoration: const InputDecoration(
                            labelText: 'Sigla',
                          ),
                        ),
                        ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.phoneNumber,
                          inputFormatters: [
                            TextInputMask(mask: [
                              '(99) 9999-9999',
                              '(99) 99999-9999',
                            ]),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Telefone de contato',
                          ),
                        ),
                        ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.email,
                          decoration: const InputDecoration(
                            labelText: 'E-mail de contato',
                          ),
                        ),
                        ffb.RadioButtonGroupFieldBlocBuilder<Division>(
                          selectFieldBloc: bloc.division,
                          canDeselect: true,
                          canTapItemTile: true,
                          decoration: const InputDecoration(
                            labelText: 'Diretoria',
                          ),
                          itemBuilder: (context, division) => FieldItem(
                            child: Text(
                              '${division.name} (${division.id})',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
      case TabType.employees:
        return properties.departments.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(height: 10),
                    Text('Adicione um departamento primeiro.'),
                  ],
                ),
              )
            : _DataTabBody<Employee, EmployeeFormBloc>(
                state: state,
                emptyLabel: 'Nenhum servidor inserido.',
                decode: (props) => properties.employees,
                encode: (props, updater) => Properties(
                  config: props.config,
                  departments: props.departments,
                  divisions: props.divisions,
                  employees: updater(props.employees),
                ),
                titleBuilder: (item) => item.id ?? '<sem matrícula>',
                subtitleBuilder: (item) => item.name,
                formBuilder: (item, referenceIndex) => EmployeeFormBloc(
                  departments: properties.departments,
                  employee: item,
                  referenceIndex: referenceIndex,
                ),
                formBodyBuilder: (context, bloc) {
                  return FocusTraversalGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.name,
                          decoration: const InputDecoration(
                            labelText: 'Nome do servidor',
                          ),
                        ),
                        ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.id,
                          inputFormatters: [
                            TextInputMask(mask: '999.9999-999'),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Matrícula',
                          ),
                        ),
                        ffb.TextFieldBlocBuilder(
                          textFieldBloc: bloc.role,
                          decoration: const InputDecoration(
                            labelText: 'Cargo',
                          ),
                        ),
                        ffb.RadioButtonGroupFieldBlocBuilder<Department>(
                          selectFieldBloc: bloc.department,
                          canDeselect: true,
                          canTapItemTile: true,
                          decoration: const InputDecoration(
                            labelText: 'Departamento',
                          ),
                          itemBuilder: (context, department) => FieldItem(
                            child: Text(
                              '${department.name} (${department.id})',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
    }
  }
}

class _GeneralTabBody extends StatelessWidget {
  final AppState state;
  final Properties properties;

  const _GeneralTabBody({
    required this.state,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = rf.ResponsiveRowColumn(
      layout: rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE)
          ? rf.ResponsiveRowColumnType.COLUMN
          : rf.ResponsiveRowColumnType.ROW,
      rowCrossAxisAlignment: CrossAxisAlignment.start,
      columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rf.ResponsiveRowColumnItem(
          rowFit: FlexFit.tight,
          rowFlex: 7,
          child: _GeneralTabBodyCalendar(
            currentMonthSelected: properties.date,
            holidays: properties.config.holidays,
            additionalHolidays: properties.config.additionalHolidays,
          ),
        ),
        rf.ResponsiveRowColumnItem(
          child: rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE)
              ? const SizedBox(height: 20)
              : const SizedBox(width: 20),
        ),
        if (rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE))
          rf.ResponsiveRowColumnItem(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Formatação',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        rf.ResponsiveRowColumnItem(
          rowFit: FlexFit.tight,
          rowFlex: 5,
          child: _GeneralTabBodyForm(
            uploadedHeaderBytes: properties.config.headerData?.bytes,
          ),
        ),
      ],
    );
    if (rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE)) {
      child = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: child,
      );
    }
    return child;
  }
}

class _GeneralTabBodyCalendar extends StatelessWidget {
  final DateTime currentMonthSelected;
  final List<int> holidays;
  final List<int> additionalHolidays;

  const _GeneralTabBodyCalendar({
    required this.currentMonthSelected,
    required this.holidays,
    required this.additionalHolidays,
  });

  @override
  Widget build(BuildContext context) {
    final AppBloc bloc = context.read();
    final DateTime now = DateTime.now();
    Widget calendarChild = BlocBuilder<ApiBloc, Map<int, List<Holiday>>>(
      builder: (context, holidaysData) {
        return TableCalendar(
          calendarBuilders: CalendarBuilders(
            selectedBuilder: (context, dt, _) {
              final Holiday? holiday = (holidaysData[dt.year] ?? [])
                  .firstOrNullWhere((h) => h.date.isAtSameDayAs(dt));

              final int day = dt.day;
              final HolidayType? type;
              if (holidays.contains(day)) {
                type = HolidayType.required;
              } else if (additionalHolidays.contains(day)) {
                type = HolidayType.optional;
              } else {
                type = null;
              }

              Widget child = Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: switch (type) {
                        null => null,
                        HolidayType.required => Colors.green,
                        HolidayType.optional => Colors.orange,
                      },
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        '${dt.day}',
                        style: TextStyle(
                          color: type == null
                              ? (holiday == null ? null : Colors.blue)
                              : Colors.white,
                          fontWeight: holiday == null
                              ? (type == null ? null : FontWeight.bold)
                              : FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              if (holiday != null) {
                child = Tooltip(
                  message: holiday.name,
                  child: child,
                );
              }
              return child;
            },
          ),
          focusedDay: currentMonthSelected,
          firstDay: now.subtract(const Duration(days: 365)),
          lastDay: now.add(const Duration(days: 365)),
          locale: 'pt_BR',
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),
          selectedDayPredicate: (dt) =>
              !{6, 7}.contains(dt.weekday) &&
              dt.isAtSameMonthAs(currentMonthSelected),
          onDaySelected: (dt, _) => bloc.onDaySelected(dt),
          onPageChanged: (dt) {
            context.read<ApiBloc>().load(dt.year);
            bloc.onMonthSelected(dt);
          },
          calendarStyle: const CalendarStyle(
            holidayTextStyle: TextStyle(color: Colors.red),
            holidayDecoration: BoxDecoration(border: Border()),
            isTodayHighlighted: false,
          ),
        );
      },
    );
    if (!rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE)) {
      calendarChild = Expanded(child: calendarChild);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        calendarChild,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Expanded(
              flex: 8,
              child: Text(
                'Clique em um dia para alterar seu status ao gerar a '
                'folha de frequência.',
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Legenda',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Feriado',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.orange,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Facultado',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GeneralTabBodyForm extends StatelessWidget {
  final Uint8List? uploadedHeaderBytes;

  const _GeneralTabBodyForm({
    required this.uploadedHeaderBytes,
  });

  @override
  Widget build(BuildContext context) {
    final AppBloc bloc = context.read();
    final Uint8List? uploadedHeaderBytes = this.uploadedHeaderBytes;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Imagem de cabeçalho',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Button(
                label: 'fazer upload',
                color: Colors.purple,
                onPressed: () async {
                  final FilePickerResult? result =
                      await GetIt.instance.get<FilePicker>().pickFiles(
                            type: FileType.image,
                          );
                  if (result == null) return;
                  final Uint8List? bytes = result.files.single.bytes;
                  if (bytes == null) return;
                  bloc.setHeaderBytes(bytes);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: uploadedHeaderBytes == null
                  ? const SizedBox.shrink()
                  : Button(
                      label: 'remover',
                      color: Colors.red,
                      onPressed: () => bloc.setHeaderBytes(null),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (uploadedHeaderBytes != null)
          Image.memory(
            uploadedHeaderBytes,
            fit: BoxFit.contain,
            height: 70,
          ),
      ],
    );
  }
}

class _DataTabBodyBloc<I, O, FB extends ffb.FormBloc<O, void>>
    extends Cubit<FB> {
  final FB Function(I?, int?) blocBuilder;

  _DataTabBodyBloc(this.blocBuilder) : super(blocBuilder(null, null));

  void newCreate() {
    emit(blocBuilder(null, null));
  }

  void newUpdate(I value, int referenceIndex) {
    emit(blocBuilder(value, referenceIndex));
  }
}

class _DataTabBody<T, FB extends ffb.FormBloc<FormBlocResult<T>, void>>
    extends StatelessWidget {
  final AppState state;
  final String emptyLabel;
  final List<T> Function(Properties) decode;
  final Properties Function(Properties, List<T> Function(List<T>)) encode;
  final String Function(T) titleBuilder;
  final String Function(T) subtitleBuilder;
  final FB Function(T?, int?) formBuilder;
  final Widget Function(BuildContext context, FB formBloc) formBodyBuilder;

  const _DataTabBody({
    required this.state,
    required this.decode,
    required this.encode,
    required this.emptyLabel,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.formBuilder,
    required this.formBodyBuilder,
  });

  Widget _buildItems(BuildContext context) {
    final Properties? activeProperties = state.activeProperties;
    final List<T> values =
        activeProperties == null ? [] : decode(activeProperties);
    Widget child;
    if (values.isEmpty) {
      child = Center(child: Text(emptyLabel));
    } else {
      child = ListView.separated(
        separatorBuilder: (context, _) => const SizedBox(height: 5),
        itemCount: values.length,
        itemBuilder: (context, index) {
          final T value = values[index];
          final String title = titleBuilder(value);
          final String subtitle = subtitleBuilder(value);
          return Card(
            child: InkWell(
              onTap: () {
                context.read<AppBloc>().onSetTabEditing(true);
                context
                    .read<_DataTabBodyBloc<T, FormBlocResult<T>, FB>>()
                    .newUpdate(value, index);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Text(
                        title[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    IconButton(
                      onPressed: () {
                        final Properties updatedProps = encode(
                          this.state.activeProperties ?? Properties.empty(),
                          (values) => [...values]..removeAt(index),
                        );
                        context.read<AppBloc>().onUpdateProps(updatedProps);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    if (rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE)) {
      child = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: child),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FloatingActionButton.extended(
                onPressed: () => context.read<AppBloc>().onSetTabEditing(true),
                icon: const Icon(Icons.add),
                label: const Text('adicionar'),
              ),
            ),
          ),
        ],
      );
    }
    return child;
  }

  Widget _buildForm(BuildContext context) {
    return BlocBuilder<_DataTabBodyBloc<T, FormBlocResult<T>, FB>, FB>(
      builder: (context, form) {
        return ffb.FormBlocListener<ffb.FormBloc<FormBlocResult<T>, void>,
            FormBlocResult<T>, void>(
          formBloc: form,
          onSuccess: (context, state) {
            final FormBlocResult<T>? result = state.successResponse;
            if (result == null) return;

            final List<T> Function(List<T>) updater;
            final int? referenceIndex = result.referenceIndex;
            if (referenceIndex == null) {
              updater = (values) => [...values, result.value];
            } else {
              updater = (values) {
                final List<T> updatedValues = [...values];
                updatedValues[referenceIndex] = result.value;
                return updatedValues;
              };
            }
            context.read<AppBloc>().onUpdateProps(encode(
                  this.state.activeProperties ?? Properties.empty(),
                  updater,
                ));
            context
                .read<_DataTabBodyBloc<T, FormBlocResult<T>, FB>>()
                .newCreate();
          },
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Text(
                'Formulário de inserção',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              formBodyBuilder(context, form),
              const SizedBox(height: 20),
              BlocBuilder<FB, ffb.FormBlocState<FormBlocResult<T>, void>>(
                bloc: form,
                builder: (context, state) {
                  return Button(
                    label: state.isEditing ? 'editar' : 'adicionar',
                    color: Colors.purple,
                    onPressed: () {
                      if (this.state.editingState) {
                        context.read<AppBloc>().onSetTabEditing(false);
                      }
                      form.submit();
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              if (!rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE))
                BlocBuilder<FB, ffb.FormBlocState<FormBlocResult<T>, void>>(
                  bloc: form,
                  builder: (context, state) {
                    if (state.isEditing) {
                      return Button(
                        label: 'cancelar',
                        color: Colors.red,
                        onPressed: () => context
                            .read<_DataTabBodyBloc<T, FormBlocResult<T>, FB>>()
                            .newCreate(),
                      );
                    }
                    return Button(
                      label: 'limpar',
                      color: Colors.orange,
                      onPressed: form.clear,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<_DataTabBodyBloc<T, FormBlocResult<T>, FB>>(
      create: (_) => _DataTabBodyBloc(formBuilder),
      child: Builder(
        builder: (context) {
          if (rf.ResponsiveBreakpoints.of(context).smallerThan(rf.PHONE)) {
            final bool isEditing = state.editingState;
            if (!isEditing) {
              return _buildItems(context);
            }
            return _buildForm(context);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 8,
                child: _buildItems(context),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: _buildForm(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
