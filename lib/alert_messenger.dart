import 'package:flutter/material.dart';

const _kAlertHeight = 80.0;

const _initialText = 'Seu texto de alerta de prioridade aparecerá aqui';

enum AlertPriority {
  error(2, 'Oops, ocorreu um erro. Pedimos desculpas.'),
  warning(1, 'Atenção! Você foi avisado.'),
  info(0, 'Este é um aplicativo escrito em Flutter.');

  const AlertPriority(this.value, this.text);
  final int value;
  final String text;
}

class Alert extends StatelessWidget {
  const Alert({
    super.key,
    required this.backgroundColor,
    required this.child,
    required this.leading,
    required this.priority,
  });

  final Color backgroundColor;
  final Widget child;
  final Widget leading;
  final AlertPriority priority;

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;
    return Material(
      child: Ink(
        color: backgroundColor,
        height: _kAlertHeight + statusbarHeight,
        child: Column(
          children: [
            SizedBox(height: statusbarHeight),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 28.0),
                  IconTheme(
                    data: const IconThemeData(
                      color: Colors.white,
                      size: 36,
                    ),
                    child: leading,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28.0),
          ],
        ),
      ),
    );
  }
}

class AlertMessenger extends StatefulWidget {
  const AlertMessenger({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AlertMessenger> createState() => AlertMessengerState();

  static AlertMessengerState of(BuildContext context) {
    try {
      final scope = _AlertMessengerScope.of(context);
      return scope.state;
    } catch (error) {
      throw FlutterError.fromParts(
        [
          ErrorSummary('No AlertMessenger was found in the Element tree'),
          ErrorDescription(
              'AlertMessenger is required in order to show and hide alerts.'),
          ...context.describeMissingAncestor(
              expectedAncestorType: AlertMessenger),
        ],
      );
    }
  }
}

class AlertMessengerState extends State<AlertMessenger>
    with TickerProviderStateMixin {
  late final AnimationController _infoController;
  late final AnimationController _warningController;
  late final AnimationController _errorController;

  late final Animation<double> _infoAnimation;
  late final Animation<double> _warningAnimation;
  late final Animation<double> _errorAnimation;

  ValueNotifier<String> text = ValueNotifier(_initialText);

  Alert? infoAlert;
  Alert? warningAlert;
  Alert? errorAlert;

  @override
  void initState() {
    super.initState();

    _infoController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _warningController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alertHeight = MediaQuery.of(context).padding.top + _kAlertHeight;

    _infoAnimation = Tween<double>(begin: -alertHeight, end: 0.0).animate(
      CurvedAnimation(parent: _infoController, curve: Curves.easeInOut),
    );

    _warningAnimation = Tween<double>(begin: -alertHeight, end: 0.0).animate(
      CurvedAnimation(parent: _warningController, curve: Curves.easeInOut),
    );

    _errorAnimation = Tween<double>(begin: -alertHeight, end: 0.0).animate(
      CurvedAnimation(parent: _errorController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _infoController.dispose();
    _warningController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  void showAlert({required Alert alert}) {
    switch (alert.priority) {
      case AlertPriority.info:
        setState(() => infoAlert = alert);
        _infoController.forward();
      case AlertPriority.warning:
        setState(() => warningAlert = alert);
        _warningController.forward();
      case AlertPriority.error:
        setState(() => errorAlert = alert);
        _errorController.forward();
    }
    text.value = errorAlert?.priority.text ??
        warningAlert?.priority.text ??
        infoAlert?.priority.text ??
        _initialText;
  }

  void hideAlert() {
    if (errorAlert != null) {
      _errorController.reverse().whenComplete(() => setState(() {
            errorAlert = null;
            text.value = warningAlert?.priority.text ?? _initialText;
          }));
    } else if (warningAlert != null) {
      _warningController.reverse().whenComplete(() => setState(() {
            warningAlert = null;
            text.value = infoAlert?.priority.text ?? _initialText;
          }));
    } else {
      _infoController.reverse().whenComplete(() => setState(() {
            infoAlert = null;
            text.value = _initialText;
          }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _infoAnimation,
          builder: (_, child) {
            final position = _infoAnimation.value + _kAlertHeight;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  top: position <= statusbarHeight
                      ? 0
                      : position - statusbarHeight,
                  child: _AlertMessengerScope(
                    state: this,
                    child: widget.child,
                  ),
                ),
                Positioned(
                  top: _infoAnimation.value,
                  left: 0,
                  right: 0,
                  child: infoAlert ?? const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
        Visibility(
          visible: warningAlert != null,
          child: AnimatedBuilder(
            animation: _warningAnimation,
            builder: (_, child) {
              final position = _warningAnimation.value + _kAlertHeight;

              return Stack(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                children: [
                  Positioned.fill(
                    top: position <= statusbarHeight
                        ? 0
                        : position - statusbarHeight,
                    child: _AlertMessengerScope(
                      state: this,
                      child: widget.child,
                    ),
                  ),
                  Positioned(
                    top: _warningAnimation.value,
                    left: 0,
                    right: 0,
                    child: warningAlert ?? const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
        ),
        Visibility(
          visible: errorAlert != null,
          child: AnimatedBuilder(
            animation: _errorAnimation,
            builder: (_, child) {
              final position = _errorAnimation.value + _kAlertHeight;

              return Stack(
                clipBehavior: Clip.antiAliasWithSaveLayer,
                children: [
                  Positioned.fill(
                    top: position <= statusbarHeight
                        ? 0
                        : position - statusbarHeight,
                    child: _AlertMessengerScope(
                      state: this,
                      child: widget.child,
                    ),
                  ),
                  Positioned(
                    top: _errorAnimation.value,
                    left: 0,
                    right: 0,
                    child: errorAlert ?? const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlertMessengerScope extends InheritedWidget {
  const _AlertMessengerScope({
    required this.state,
    required super.child,
  });

  final AlertMessengerState state;

  @override
  bool updateShouldNotify(_AlertMessengerScope oldWidget) =>
      state != oldWidget.state;

  static _AlertMessengerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AlertMessengerScope>();
  }

  static _AlertMessengerScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No _AlertMessengerScope found in context');
    return scope!;
  }
}
