import 'package:recase/recase.dart';
import 'package:template_utils/file_utils.dart';

String templateMockClassDefinition(String className) => "class Mock$className extends Mock implements $className {}";

String templateImport(String package, {String as = '', bool relative = false}) {
  var pkg = relative //
      ? package.replaceFirst(RegExp(r"^package:"), "")
      : package.prefixed("package:");
  var asDirective = as.isEmpty ? '' : ' as $as';
  return "import \"${pkg}\"${asDirective};";
}

String templateMockStaticField(String typeName) => "static late Mock$typeName ${typeName.camelCase};";

String templateMockFieldInit(String typeName) => "${typeName.camelCase} = Mock$typeName();";

String templateRegisterFallback(String typeName) => "registerFallbackValue(Mock$typeName());";

String templateRegisterFactory({
  String? interfaceName,
  required String implementationName,
  List<String> params = const [],
  bool useConst = true,
  String constructorName = '',
}) {
  var shouldWrap = params.length > 2;
  var wrapLine = shouldWrap ? "\n" : "";
  return """
..registerFactory<${interfaceName ?? implementationName}>(
  () =>${useConst ? " const " : " "}$implementationName${constructorName.isEmpty ? "" : ".$constructorName"}($wrapLine${params.join(shouldWrap ? ",\n" : ", ")}$wrapLine),
)
""";
}

String templateRegisterFactoryParam({
  String? interfaceName,
  required String implementationName,
  required String param1TypeName,
  required String param1varName,
  String param2TypeName = "dynamic",
  String param2VarName = "_",
  List<String> params = const [],
  bool useConst = true,
  String constructorName = '',
}) {
  var shouldWrap = params.length > 1;
  var wrapLine = shouldWrap ? "\n" : "";
  return """
..registerFactoryParam<${interfaceName ?? implementationName}, $param1TypeName, $param2TypeName>(
  ($param1varName, $param2VarName) =>${useConst ? " const " : " "}$implementationName${constructorName.isEmpty ? "" : ".$constructorName"}($wrapLine${params.join(shouldWrap ? ",\n" : ", ")}$wrapLine),
)
""";
}
