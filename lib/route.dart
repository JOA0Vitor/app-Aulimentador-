import 'package:aulimentador/home.dart';
import 'package:aulimentador/horarios.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';

final routes = GoRouter(
  initialLocation: '/home',
  routes: <RouteBase>[
    GoRoute(path: '/home', builder: ((context, state) => const Home())),
    GoRoute(path: '/horarios', builder: ((context, state) => const Horarios())),
  ],
);

CustomTransitionPage buildPageWithDefaultTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

Page<dynamic> Function(BuildContext, GoRouterState) defaultPageBuilder<T>(
        Widget child) =>
    (BuildContext context, GoRouterState state) {
      return buildPageWithDefaultTransition<T>(
        context: context,
        state: state,
        child: child,
      );
    };

class CustomNoTransitionPage<T> extends CustomTransitionPage<T> {
  const CustomNoTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: _transitionsBuilder,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          maintainState: false,
        );

  static Widget _transitionsBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
