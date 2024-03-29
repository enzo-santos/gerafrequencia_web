import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gerafrequencia_web/bloc.dart';
import 'package:gerafrequencia_web/main.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;

import 'widget_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FileSaver>(),
  MockSpec<FilePicker>(),
])
void main() {
  late MockFileSaver mockFileSaver;
  late MockFilePicker mockFilePicker;
  setUp(() {
    mockFileSaver = MockFileSaver();
    mockFilePicker = MockFilePicker();
    GetIt.instance
      ..registerSingleton<FileSaver>(mockFileSaver)
      ..registerSingleton<FilePicker>(mockFilePicker);
  });
  tearDown(() {
    GetIt.instance.reset();
  });
  testWidgets('Inicial', (WidgetTester tester) async {
    await tester.pumpWidget(BlocProvider<AppBloc>(
      create: (_) => AppBloc.initial(),
      child: const App(),
    ));

    expect(find.text('Gerador de frequências'), findsOneWidget);
    expect(find.text('Novo'), findsOneWidget);
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text('A área de trabalho está vazia.'), findsOneWidget);
  });
  testWidgets('Novo', (WidgetTester tester) async {
    await tester.pumpWidget(BlocProvider<AppBloc>(
      create: (_) => AppBloc.initial(),
      child: const App(),
    ));

    await tester.tap(find.text('Novo'));
    await tester.pump();
    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Diretorias'), findsOneWidget);
    expect(find.text('Departamentos'), findsOneWidget);
    expect(find.text('Servidores'), findsOneWidget);
    expect(find.text('Selecione uma aba para visualizar.'), findsOneWidget);
  });
  testWidgets('Abrir, sem seleção', (WidgetTester tester) async {
    await tester.pumpWidget(BlocProvider<AppBloc>(
      create: (_) => AppBloc.initial(),
      child: const App(),
    ));

    mockito
        .when(mockFilePicker.pickFiles(
          withData: true,
          type: FileType.custom,
          allowedExtensions: ['gfreq'],
        ))
        .thenAnswer((_) async => null);

    await tester.tap(find.text('Abrir'));
    await tester.pump();
    mockito
        .verify(mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['gfreq'],
          withData: true,
        ))
        .called(1);
    expect(find.text('Geral'), findsNothing);
  });
  testWidgets('Abrir, com seleção', (WidgetTester tester) async {
    await tester.pumpWidget(BlocProvider<AppBloc>(
      create: (_) => AppBloc.initial(),
      child: const App(),
    ));

    final Uint8List bytes = File('test/assets/save.gfreq').readAsBytesSync();
    mockito
        .when(mockFilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['gfreq'],
    ))
        .thenAnswer((_) async {
      return FilePickerResult([
        PlatformFile(name: 'save.gfreq', size: bytes.length, bytes: bytes),
      ]);
    });

    await tester.tap(find.text('Abrir'));
    await tester.pump();
    mockito
        .verify(mockFilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['gfreq'],
          withData: true,
        ))
        .called(1);

    expect(find.text('Geral'), findsOneWidget);
    expect(find.text('Diretorias'), findsOneWidget);
    expect(find.text('Departamentos'), findsOneWidget);
    expect(find.text('Servidores'), findsOneWidget);
    expect(find.text('Selecione uma aba para visualizar.'), findsOneWidget);
  });
}
