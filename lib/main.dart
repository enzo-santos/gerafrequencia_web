import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gerafrequencia_web/bloc.dart';
import 'package:gerafrequencia_web/blocs.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:responsive_framework/responsive_framework.dart' as rf;

import 'screens/app.dart';

void main() {
  initializeDateFormatting();
  ffb.FieldBlocBuilder.defaultErrorBuilder = (context, error, bloc) {
    return switch (error) {
      ffb.FieldBlocValidatorsErrors.required =>
        (bloc is ffb.MultiSelectFieldBloc || bloc is ffb.SelectFieldBloc)
            ? 'Selecione uma opção.'
            : 'Insira este campo.',
      ffb.FieldBlocValidatorsErrors.email => 'E-mail inválido.',
      ffb.FieldBlocValidatorsErrors.passwordMin6Chars => 'Senha muito curta.',
      ffb.FieldBlocValidatorsErrors.confirmPassword =>
        'Campo deve corresponder à senha.',
      'network-request' => 'Sem conexão.',
      'too-many-requests' => 'Muitas tentativas.',
      'user-not-found' => 'Conta não encontrada.',
      'user-disabled' => 'Conta desativada.',
      'wrong-password' => 'Senha inválida.',
      'pattern' || 'invalid' => 'Valor inválido.',
      _ => '$error',
    };
  };
  GetIt.instance.registerSingleton<FilePicker>(FilePicker.platform);
  GetIt.instance.registerSingleton<FileSaver>(FileSaver.instance);

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<AppBloc>(create: (_) => AppBloc.initial()),
    ],
    child: const App(),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ApiBloc>(create: (_) => ApiBloc()),
      ],
      child: MaterialApp(
        title: 'Gerador de frequências',
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('pt', 'BR')],
        builder: (context, child) {
          child!;
          child = rf.ClampingScrollWrapper.builder(context, child);
          child = rf.ResponsiveBreakpoints.builder(
            child: child,
            breakpoints: const [
              rf.Breakpoint(start: 0, end: 360),
              rf.Breakpoint(start: 361, end: 480, name: rf.MOBILE),
              rf.Breakpoint(start: 481, end: 640, name: rf.PHONE),
              rf.Breakpoint(start: 641, end: 850, name: rf.TABLET),
              rf.Breakpoint(start: 851, end: 1080, name: rf.DESKTOP),
              rf.Breakpoint(start: 1081, end: double.infinity),
            ],
          );
          return child;
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          useMaterial3: true,
        ),
        home: const AppScreen(),
      ),
    );
  }
}
