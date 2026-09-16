import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:mascot_studio/service/archive_factory.dart';
import 'package:mascot_studio/service/studio_archive.dart';
import 'package:mascot_studio/service/studio_controller.dart';
import 'package:mascot_studio/ui/studio_router.dart';
import 'package:mascot_studio/ui/theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();
  runApp(MascotStudioRoot(initialApiKey: _apiKey()));
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (_) {
    // Tests and dart-define builds can run without an asset .env.
  }
}

String _apiKey() {
  const dartDefine = String.fromEnvironment('GEMINI_API_KEY');
  if (dartDefine.isNotEmpty) return dartDefine;
  const googleDefine = String.fromEnvironment('GOOGLE_GENAI_API_KEY');
  if (googleDefine.isNotEmpty) return googleDefine;
  return dotenv.env['GEMINI_API_KEY'] ??
      dotenv.env['GOOGLE_GENAI_API_KEY'] ??
      '';
}

class MascotStudioRoot extends StatefulWidget {
  const MascotStudioRoot({
    super.key,
    this.initialApiKey = '',
    this.archive,
    this.controller,
  });

  final String initialApiKey;
  final StudioArchive? archive;
  final StudioController? controller;

  @override
  State<MascotStudioRoot> createState() => _MascotStudioRootState();
}

class _MascotStudioRootState extends State<MascotStudioRoot> {
  late final StudioController _controller;
  late final GoRouter _router;
  var _ownsController = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.controller;
    if (existing != null) {
      _controller = existing;
    } else {
      _ownsController = true;
      _controller = StudioController(
        initialApiKey: widget.initialApiKey,
        archive: widget.archive ?? createDefaultArchive(),
      );
    }
    _router = buildStudioRouter(_controller);
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _router.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: MaterialApp.router(
        title: 'Mascot Studio',
        debugShowCheckedModeBanner: false,
        theme: buildStudioTheme(),
        routerConfig: _router,
      ),
    );
  }
}
