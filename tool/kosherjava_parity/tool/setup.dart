import 'dart:io';
import 'dart:isolate';

import 'package:jnigen/jnigen.dart';
import 'package:path/path.dart' as p;

const kosherJavaRepository = 'https://github.com/KosherJava/zmanim.git';
const kosherJavaCommit = '30122aa43deff76dbc46124c5c8d313797cf97b6';

final packageRoot = p.normalize(p.join(p.dirname(Platform.script.toFilePath()), '..'));
final buildDir = p.join(packageRoot, 'build');
final kosherJavaDir = p.join(buildDir, 'kosherjava');
final jniLibsDir = p.join(buildDir, 'jni_libs');

Future<void> main(List<String> args) async {
  final javaHome = resolveJavaHome(args);
  stdout.writeln('JDK: $javaHome');
  Directory(buildDir).createSync(recursive: true);
  File(p.join(buildDir, 'java_home')).writeAsStringSync(javaHome);

  await checkoutKosherJava();
  await compileKosherJava(javaHome);
  await generateBindings();
  await buildJniJar(javaHome);
  await buildDartJni(javaHome);
  stdout.writeln('Ready. Run: dart run bin/parity.dart');
}

String resolveJavaHome(List<String> args) {
  final flag = args.indexOf('--java-home');
  if (flag != -1) return args[flag + 1];
  final fromEnv = Platform.environment['JAVA_HOME'];
  if (fromEnv != null && File(p.join(fromEnv, 'bin', exe('javac'))).existsSync()) {
    return fromEnv;
  }
  final result = Process.runSync('java', ['-XshowSettings:properties', '-version'], runInShell: true);
  final match = RegExp(r'java\.home = (.+)').firstMatch('${result.stderr}');
  if (match == null) throw StateError('No JDK found: set JAVA_HOME or pass --java-home');
  return match.group(1)!.trim();
}

String exe(String name) => Platform.isWindows ? '$name.exe' : name;

Future<void> run(String executable, List<String> arguments, {String? workingDirectory}) async {
  stdout.writeln('+ $executable ${arguments.join(' ')}');
  final process = await Process.start(executable, arguments,
      workingDirectory: workingDirectory, mode: ProcessStartMode.inheritStdio, runInShell: Platform.isWindows);
  final code = await process.exitCode;
  if (code != 0) throw ProcessException(executable, arguments, 'exit code $code', code);
}

Future<void> checkoutKosherJava() async {
  if (!Directory(p.join(kosherJavaDir, '.git')).existsSync()) {
    await run('git', ['clone', '--quiet', kosherJavaRepository, kosherJavaDir]);
  }
  final head = Process.runSync('git', ['-C', kosherJavaDir, 'rev-parse', 'HEAD']).stdout.toString().trim();
  if (head == kosherJavaCommit) return;
  final known = Process.runSync('git', ['-C', kosherJavaDir, 'cat-file', '-e', '$kosherJavaCommit^{commit}']);
  if (known.exitCode != 0) await run('git', ['-C', kosherJavaDir, 'fetch', '--quiet', 'origin']);
  await run('git', ['-C', kosherJavaDir, 'checkout', '--quiet', '--detach', kosherJavaCommit]);
}

Future<void> compileKosherJava(String javaHome) async {
  final sources = Directory(p.join(kosherJavaDir, 'src', 'main', 'java'))
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.java'))
      .map((file) => '"${file.path.replaceAll(r'\', '/')}"');
  final classes = Directory(p.join(buildDir, 'classes'));
  if (classes.existsSync()) classes.deleteSync(recursive: true);
  final argFile = File(p.join(buildDir, 'javac-sources'))..writeAsStringSync(sources.join('\n'));
  final bin = p.join(javaHome, 'bin');
  await run(p.join(bin, exe('javac')),
      ['-encoding', 'UTF-8', '--release', '11', '-nowarn', '-d', classes.path, '@${argFile.path}']);
  await run(p.join(bin, exe('jar')), ['cf', p.join(buildDir, 'kosherjava.jar'), '-C', classes.path, '.']);
}

Future<void> generateBindings() async {
  await JniGenerator(
    input: Input(
      classes: [
        'com.kosherjava.zmanim',
        'java.time.Instant',
        'java.time.LocalDate',
        'java.time.LocalTime',
        'java.time.ZoneId',
        'java.time.ZonedDateTime',
        'java.time.chrono.ChronoZonedDateTime',
        'java.time.Duration',
        'java.time.ZoneOffset',
        'java.time.zone.ZoneRules',
        'java.time.zone.ZoneOffsetTransition',
      ],
      sourcePath: [Uri.directory(p.join(kosherJavaDir, 'src', 'main', 'java'))],
      classPath: [Uri.file(p.join(buildDir, 'kosherjava.jar'))],
    ),
    output: Output(
      dart: DartOutput(
        path: Uri.file(p.join(packageRoot, 'lib', 'src', 'kosherjava.g.dart')),
        structure: OutputStructure.singleFile,
      ),
    ),
  ).generate();
}

Future<String> jniPackageRoot() async {
  final lib = await Isolate.resolvePackageUri(Uri.parse('package:jni/jni.dart'));
  return p.normalize(p.join(p.dirname(lib!.toFilePath()), '..'));
}

Future<void> buildJniJar(String javaHome) async {
  final javaSources = p.join(await jniPackageRoot(), 'java');
  Directory(jniLibsDir).createSync(recursive: true);
  final gradlew = p.join(javaSources, Platform.isWindows ? 'gradlew.bat' : 'gradlew');
  final process = await Process.start(gradlew, ['jar', '-Pjni.targetDir=$jniLibsDir'],
      workingDirectory: javaSources,
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
      environment: {'JAVA_HOME': javaHome});
  if (await process.exitCode != 0) throw StateError('building jni.jar failed');
}

Future<void> buildDartJni(String javaHome) async {
  if (!Platform.isWindows) {
    await run(Platform.resolvedExecutable, ['run', 'jni:setup', '--build-path', jniLibsDir],
        workingDirectory: packageRoot);
    return;
  }
  final jniRoot = await jniPackageRoot();
  final source = p.join(buildDir, 'dartjni_src');
  if (Directory(source).existsSync()) Directory(source).deleteSync(recursive: true);
  await copyDirectory(Directory(p.join(jniRoot, 'src')), Directory(source));
  final header = File(p.join(source, 'dartjni.h'));
  // gcc ignores __declspec(thread), which would share one JNIEnv across every thread.
  const msvcThreadLocal = '#define THREAD_LOCAL __declspec(thread)';
  final text = header.readAsStringSync();
  if (!text.contains(msvcThreadLocal)) throw StateError('dartjni.h no longer defines $msvcThreadLocal');
  header.writeAsStringSync(text.replaceFirst(msvcThreadLocal, '#define THREAD_LOCAL _Thread_local'));
  await run('gcc', [
    '-shared',
    '-O2',
    '-static-libgcc',
    '-DDART_SHARED_LIB',
    '-I',
    source,
    '-I',
    p.join(jniRoot, 'third_party'),
    p.join(source, 'dartjni.c'),
    p.join(source, 'third_party', 'global_jni_env.c'),
    p.join(source, 'include', 'dart_api_dl.c'),
    '-L',
    p.join(javaHome, 'lib'),
    '-ljvm',
    '-lole32',
    '-Wl,-Bstatic',
    '-lwinpthread',
    '-o',
    p.join(jniLibsDir, 'dartjni.dll'),
  ]);
}

Future<void> copyDirectory(Directory from, Directory to) async {
  to.createSync(recursive: true);
  for (final entity in from.listSync()) {
    final target = p.join(to.path, p.basename(entity.path));
    if (entity is Directory) {
      await copyDirectory(entity, Directory(target));
    } else if (entity is File) {
      entity.copySync(target);
    }
  }
}
