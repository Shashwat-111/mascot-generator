import 'package:idb_shim/idb_browser.dart';
import 'package:mascot_studio/service/idb_studio_archive.dart';
import 'package:mascot_studio/service/studio_archive.dart';

StudioArchive createDefaultArchive() => IdbStudioArchive(idbFactoryBrowser);
