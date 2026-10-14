// index.dart
//
// Widget generator. Creates the MVVM boilerplate of a widget:
//
//   lib/widgets/<path>/<ClassName>/index.dart
//   lib/widgets/<path>/<ClassName>/view_model.dart   (stateful only)
//   lib/widgets/<path>/<ClassName>/view.dart
//
// Usage (from the repository root):
//   dart cli/generation/widget/index.dart --className MyWidget [--path core/render] [--stateless]

import "dart:io";

import "package:args/args.dart";
import "package:flutter_skeleton/utils/builders/file_path_builder.dart";
import "package:flutter_skeleton/utils/logger/command_filter.dart";
import "package:flutter_skeleton/utils/parsers/string_parser.dart";
import "package:jinja/jinja.dart";
import "package:logger/logger.dart";

const String classNameOptionName = "className";
const String stateFlagName = "stateless";
const String pathOptionName = "path";

void main(List<String> argumentList) async {
  final Logger logger = Logger(filter: CommandFilter());
  await logger.init;

  final ArgResults argResults = parseArgumentList(argumentList);

  await catchUsageError(
    logger: logger,
    argResults: argResults
  );

  // file properties
  final String className = argResults.option(classNameOptionName)!;
  final FilePathBuilder directoryPathBuilder = FilePathBuilder.currentPackage()
    ..addSegment("lib")
    ..addSegment("widgets");
  final String? path = argResults.option(pathOptionName);
  if (path != null) {
    directoryPathBuilder.concat(path);
  }
  directoryPathBuilder.addSegment(className);
  final String directoryPath = directoryPathBuilder.build();

  await catchGeneralError(
    logger: logger,
    className: className,
    directoryPath: directoryPath
  );

  writeFile(
    isStateless: argResults.flag(stateFlagName),
    fileName: className,
    directoryPath: directoryPath,
    className: className
  );

  await success(
    logger: logger,
    directoryPath: directoryPath,
    className: className
  );
}

ArgResults parseArgumentList(List<String> argumentList) {
  final ArgParser argParser = ArgParser();
  argParser.addOption(
    classNameOptionName,
    aliases: ["c", "cn"],
    mandatory: true
  );
  argParser.addOption(
    pathOptionName,
    aliases: ["p"]
  );
  argParser.addFlag(
    stateFlagName,
    aliases: ["l", "sl"],
  );
  return argParser.parse(argumentList);
}

/// Catch usage error
Future<void> catchUsageError({
  required Logger logger,
  required ArgResults argResults
}) async {
  final String classNameOption = argResults.option(classNameOptionName)!;
  final bool lessThan2Chars = classNameOption.length < 2;
  final bool notInPascalCase = !StringParser.isPascal(classNameOption);

  if (lessThan2Chars) {
    logger.w("--className=$classNameOption of widget must contain at least 2 chars");
  }

  if (notInPascalCase) {
    logger.w("--className=$classNameOption of widget must be formatted in pascal case");
  }

  if (lessThan2Chars || notInPascalCase) {
    await logger.close();
    exit(2);
  }
}

// Catch general error
Future<void> catchGeneralError({
  required Logger logger,
  required String directoryPath,
  required String className
}) async {
  if (Directory(directoryPath).existsSync()) {
    logger.e("$className already exists");
    await logger.close();
    exit(1);
  }
}

// Success and exit
Future<void> success({
  required Logger logger,
  required String directoryPath,
  required String className
}) async {
  logger.i("$className created here $directoryPath");
  await logger.close();
  exit(0);
}

/// File creation
void writeFile({
  required bool isStateless,
  required String fileName,
  required String directoryPath,
  required String className
}) {
  final Environment env = Environment(keepTrailingNewLine: true);

  // directory
  final FilePathBuilder directoryTemplatePathBuilder = FilePathBuilder.currentPackage()
    ..addSegment("cli")
    ..addSegment("generation")
    ..addSegment("widget")
    ..addSegment("templates")
    ..addSegment(isStateless ? "stateless" : "stateful");
  final Directory directory = Directory(directoryPath);
  directory.createSync();

  // index.dart
  final FilePathBuilder indexTemplatePathBuilder = FilePathBuilder.fromOrigin(directoryTemplatePathBuilder.build())
    ..addSegment("index.dart.jinja");
  final String indexTemplatePath = indexTemplatePathBuilder.build();
  final String indexTemplateContent = File(indexTemplatePath).readAsStringSync();
  final Template indexTemplate = env.fromString(indexTemplateContent);
  final String indexTemplateString = indexTemplate.render({
    "ClassName": className
  });
  final FilePathBuilder indexFilePathBuilder = FilePathBuilder.fromOrigin(directoryPath)
    ..addSegment("index.dart");
  File(indexFilePathBuilder.build()).writeAsStringSync(indexTemplateString);

  // view_model.dart
  if (!isStateless) {
    final FilePathBuilder viewModelTemplatePathBuilder = FilePathBuilder.fromOrigin(directoryTemplatePathBuilder.build())
      ..addSegment("view_model.dart.jinja");
    final String viewModelTemplatePath = viewModelTemplatePathBuilder.build();
    final String viewModelTemplateContent = File(viewModelTemplatePath).readAsStringSync();
    final Template viewModelTemplate = env.fromString(viewModelTemplateContent);
    final String viewModelTemplateString = viewModelTemplate.render({
      "ClassName": className
    });
    final FilePathBuilder viewModelFilePathBuilder = FilePathBuilder.fromOrigin(directoryPath)
      ..addSegment("view_model.dart");
    File(viewModelFilePathBuilder.build()).writeAsStringSync(viewModelTemplateString);
  }

  // view.dart
  final FilePathBuilder viewTemplatePathBuilder = FilePathBuilder.fromOrigin(directoryTemplatePathBuilder.build())
    ..addSegment("view.dart.jinja");
  final String viewTemplatePath = viewTemplatePathBuilder.build();
  final String viewTemplateContent = File(viewTemplatePath).readAsStringSync();
  final Template viewTemplate = env.fromString(viewTemplateContent);
  final String viewTemplateString = viewTemplate.render({
    "ClassName": className
  });
  final FilePathBuilder viewFilePathBuilder = FilePathBuilder.fromOrigin(directoryPath)
    ..addSegment("view.dart");
  File(viewFilePathBuilder.build()).writeAsStringSync(viewTemplateString);
}
