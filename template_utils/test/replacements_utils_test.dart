import 'package:template_utils/template_utils.dart';
import 'package:test/test.dart';

void main() {
  test("import does not have double quote", () {
    expect(templateImport("lib/test/import").contains("\""), false);
  });
}
