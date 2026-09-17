import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:jni/jni.dart';
import 'package:path/path.dart' as p;

String get packageRoot {
  final lib = Isolate.resolvePackageUriSync(Uri.parse('package:kosherjava_parity/'))!;
  return p.normalize(p.join(lib.toFilePath(), '..'));
}

void startJvm() {
  final build = p.join(packageRoot, 'build');
  final javaHomeFile = File(p.join(build, 'java_home'));
  if (!javaHomeFile.existsSync()) {
    throw StateError('Run `dart run tool/setup.dart` first');
  }
  final javaHome = javaHomeFile.readAsStringSync().trim();
  if (Platform.isWindows) {
    DynamicLibrary.open(p.join(javaHome, 'bin', 'server', 'jvm.dll'));
  } else if (Platform.isMacOS) {
    DynamicLibrary.open(p.join(javaHome, 'lib', 'server', 'libjvm.dylib'));
  } else {
    DynamicLibrary.open(p.join(javaHome, 'lib', 'server', 'libjvm.so'));
  }
  Jni.spawnIfNotExists(
    dylibDir: p.join(build, 'jni_libs'),
    classPath: [p.join(build, 'jni_libs', 'jni.jar'), p.join(build, 'kosherjava.jar')],
  );
}
