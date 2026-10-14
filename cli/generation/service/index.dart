// index.dart
//
// Service generator. Creates a static service class and its four DTOs:
//
//   lib/api/services/<entity>_service.dart
//   lib/api/dtos/<entity>/output/detail_output.dart
//   lib/api/dtos/<entity>/output/list_output.dart
//   lib/api/dtos/<entity>/input/post_input.dart
//   lib/api/dtos/<entity>/input/put_input.dart
//
// Usage (from the repository root):
//   dart cli/generation/service/index.dart --className MyEntity [--route my-entities]
//
// --route defaults to the snake_case class name + "s" (MyEntity → my_entitys);
// pass it explicitly for irregular plurals or kebab-case URLs.

import "dart:io";

import "package:args/args.dart";
import "package:flutter_skeleton/utils/builders/file_path_builder.dart";
import "package:flutter_skeleton/utils/logger/command_filter.dart";
import "package:flutter_skeleton/utils/parsers/string_parser.dart";
import "package:jinja/jinja.dart";
import "package:logger/logger.dart";

const String classNameOptionName = "className";
const String routeOptionName = "route";

/// Template file → destination path segments under lib/, relative to the
/// entity's snake_case name.
Map<String, List<String>> outputFiles(String fileName) => <String, List<String>>{
  "service.dart.jinja": <String>["api", "services", "${fileName}_service.dart"],
  "detail_output.dart.jinja": <String>["api", "dtos", fileName, "output", "detail_output.dart"],
  "list_output.dart.jinja": <String>["api", "dtos", fileName, "output", "list_output.dart"],
  "post_input.dart.jinja": <String>["api", "dtos", fileName, "input", "post_input.dart"],
  "put_input.dart.jinja": <String>["api", "dtos", fileName, "input", "put_input.dart"],
};

Future<void> main(List<String> argumentList) async {
  final Logger logger = Logger(filter: CommandFilter());
  await logger.init;

  final ArgResults argResults = parseArgumentList(argumentList);

  await catchUsageError(
    logger: logger,
    argResults: argResults,
  );

  final String className = argResults.option(classNameOptionName)!;
  final String fileName = StringParser.fromPascal(className).toSnake();
  final String route = argResults.option(routeOptionName) ?? "${fileName}s";
  final Map<String, String> destinations = <String, String>{
    for (final MapEntry<String, List<String>> entry in outputFiles(fileName).entries)
      entry.key: libPath(entry.value),
  };

  await catchGeneralError(
    logger: logger,
    className: className,
    destinations: destinations.values,
  );

  writeFiles(
    destinations: destinations,
    data: <String, Object?>{
      "ClassName": className,
      "file_name": fileName,
      "route": route,
    },
  );

  await success(
    logger: logger,
    className: className,
    destinations: destinations.values,
  );
}

ArgResults parseArgumentList(List<String> argumentList) {
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    classNameOptionName,
    aliases: <String>["c", "cn"],
    mandatory: true,
  );
  argParser.addOption(
    routeOptionName,
    aliases: <String>["r"],
  );
  return argParser.parse(argumentList);
}

/// Builds an absolute path under the package's lib/ directory.
String libPath(List<String> segments) {
  final FilePathBuilder builder = FilePathBuilder.currentPackage()..addSegment("lib");
  segments.forEach(builder.addSegment);
  return builder.build();
}

/// Catch usage error
Future<void> catchUsageError({
  required Logger logger,
  required ArgResults argResults,
}) async {
  final String classNameOption = argResults.option(classNameOptionName)!;
  final bool lessThan2Chars = classNameOption.length < 2;
  final bool notInPascalCase = !StringParser.isPascal(classNameOption);

  if (lessThan2Chars) {
    logger.w("--className=$classNameOption of service must contain at least 2 chars");
  }

  if (notInPascalCase) {
    logger.w("--className=$classNameOption of service must be formatted in pascal case");
  }

  if (lessThan2Chars || notInPascalCase) {
    await logger.close();
    exit(2);
  }
}

/// Catch general error — never overwrite an existing file.
Future<void> catchGeneralError({
  required Logger logger,
  required String className,
  required Iterable<String> destinations,
}) async {
  final List<String> existing = destinations.where((String path) => File(path).existsSync()).toList();
  if (existing.isNotEmpty) {
    logger.e("${className}Service: files already exist:\n${existing.join("\n")}");
    await logger.close();
    exit(1);
  }
}

/// Success and exit
Future<void> success({
  required Logger logger,
  required String className,
  required Iterable<String> destinations,
}) async {
  logger.i("${className}Service created:\n${destinations.join("\n")}");
  await logger.close();
  exit(0);
}

/// File creation
void writeFiles({
  required Map<String, String> destinations,
  required Map<String, Object?> data,
}) {
  final Environment env = Environment(keepTrailingNewLine: true);

  for (final MapEntry<String, String> entry in destinations.entries) {
    final FilePathBuilder templatePathBuilder = FilePathBuilder.currentPackage()
      ..addSegment("cli")
      ..addSegment("generation")
      ..addSegment("service")
      ..addSegment("templates")
      ..addSegment(entry.key);
    final String templateContent = File(templatePathBuilder.build()).readAsStringSync();
    final Template template = env.fromString(templateContent);
    final File destination = File(entry.value);
    destination.parent.createSync(recursive: true);
    destination.writeAsStringSync(template.render(data));
  }
}
