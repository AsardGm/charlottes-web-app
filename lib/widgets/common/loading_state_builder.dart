import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'skeleton_widgets.dart';

/// Smart loading state builder with skeleton support
/// Handles loading, error, and empty states automatically
class LoadingStateBuilder<T> extends StatelessWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final Widget? loadingSkeleton;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final String? emptyMessage;
  final bool Function(T data)? isEmpty;

  const LoadingStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.loadingSkeleton,
    this.errorWidget,
    this.emptyWidget,
    this.emptyMessage,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => loadingSkeleton ?? _defaultLoadingSkeleton(),
      error: (error, stack) =>
          errorWidget ?? _defaultErrorWidget(context, error),
      data: (data) {
        // Check if data is empty
        if (isEmpty != null && isEmpty!(data)) {
          return emptyWidget ??
              _defaultEmptyWidget(context, emptyMessage ?? 'Žádná data');
        }

        // Check for empty lists
        if (data is List && data.isEmpty) {
          return emptyWidget ??
              _defaultEmptyWidget(context, emptyMessage ?? 'Žádné položky');
        }

        return builder(data);
      },
    );
  }

  Widget _defaultLoadingSkeleton() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _defaultErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Něco se pokazilo',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultEmptyWidget(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state builder specifically for lists
class ListLoadingStateBuilder<T> extends StatelessWidget {
  final AsyncValue<List<T>> state;
  final Widget Function(List<T> data) builder;
  final Widget? itemSkeleton;
  final int skeletonItemCount;
  final String? emptyMessage;
  final Widget? emptyWidget;

  const ListLoadingStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.itemSkeleton,
    this.skeletonItemCount = 5,
    this.emptyMessage,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingStateBuilder<List<T>>(
      state: state,
      builder: builder,
      loadingSkeleton: itemSkeleton != null
          ? SkeletonList(
              skeletonItem: itemSkeleton!,
              itemCount: skeletonItemCount,
            )
          : null,
      emptyMessage: emptyMessage,
      emptyWidget: emptyWidget,
      isEmpty: (data) => data.isEmpty,
    );
  }
}

/// Loading state builder for single data item
class DataLoadingStateBuilder<T> extends StatelessWidget {
  final AsyncValue<T?> state;
  final Widget Function(T data) builder;
  final Widget? skeleton;
  final String? notFoundMessage;

  const DataLoadingStateBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.skeleton,
    this.notFoundMessage,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingStateBuilder<T?>(
      state: state,
      builder: (data) {
        if (data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notFoundMessage ?? 'Data nenalezena',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return builder(data);
      },
      loadingSkeleton: skeleton,
    );
  }
}

/// Simple refresh indicator with loading state
class RefreshableLoadingState<T> extends StatelessWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) builder;
  final Future<void> Function() onRefresh;
  final Widget? loadingSkeleton;
  final String? emptyMessage;

  const RefreshableLoadingState({
    super.key,
    required this.state,
    required this.builder,
    required this.onRefresh,
    this.loadingSkeleton,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LoadingStateBuilder<T>(
        state: state,
        builder: builder,
        loadingSkeleton: loadingSkeleton,
        emptyMessage: emptyMessage,
      ),
    );
  }
}
