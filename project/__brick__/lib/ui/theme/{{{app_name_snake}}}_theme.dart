import 'package:{{{app_package_name}}}/ui/theme/{{{app_name_snake}}}_colors.dart';
import 'package:{{{app_package_name}}}/ui/theme/{{{app_name_snake}}}_dimens.dart';
import 'package:{{{app_package_name}}}/ui/theme/{{{app_name_snake}}}_text_styles.dart';
import 'package:flutter/cupertino.dart';

class {{{app_name_pascal}}}Theme extends InheritedWidget {
  const {{{app_name_pascal}}}Theme({
    super.key,
    this.colors = const {{{app_name_pascal}}}Colors(),
    this.textStyles = const {{{app_name_pascal}}}TextStyles(),
    this.dimens = const {{{app_name_pascal}}}Dimens(),
    required super.child,
  });

  static {{{app_name_pascal}}}Theme of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<{{{app_name_pascal}}}Theme>();
    assert(result != null, 'No {{{app_name_pascal}}}Theme found in context');

    return result!;
  }

  final {{{app_name_pascal}}}Colors colors;
  final {{{app_name_pascal}}}TextStyles textStyles;
  final {{{app_name_pascal}}}Dimens dimens;


  @override
  bool updateShouldNotify({{{app_name_pascal}}}Theme oldWidget) => colors != oldWidget.colors || textStyles != oldWidget.textStyles;
}

extension ContextTheme on BuildContext {
  {{{app_name_pascal}}}Theme get theme => {{{app_name_pascal}}}Theme.of(this);
}
