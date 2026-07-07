import 'dart:async';

import 'one_click_client.dart';
import 'one_click_models.dart';

/// High-level app stage for a 1Click swap lifecycle.
enum OneClickSwapStage {
  idle,
  quoting,
  quoted,
  awaitingDeposit,
  depositSubmitted,
  processing,
  success,
  refunded,
  failed,
  expired,
}

/// Immutable lifecycle state emitted by [OneClickSwapController].
class OneClickSwapState {
  const OneClickSwapState({
    required this.stage,
    required this.updatedAt,
    this.quote,
    this.status,
    this.error,
  });

  factory OneClickSwapState.idle() => OneClickSwapState(
    stage: OneClickSwapStage.idle,
    updatedAt: DateTime.now().toUtc(),
  );

  final OneClickSwapStage stage;
  final OneClickQuoteResponse? quote;
  final OneClickStatus? status;
  final String? error;
  final DateTime updatedAt;

  String? get depositAddress =>
      quote?.quote.depositAddress ??
      status?.quoteResponse?.quote.depositAddress;

  String? get depositMemo =>
      quote?.quote.depositMemo ?? status?.quoteResponse?.quote.depositMemo;

  bool get isTerminal {
    switch (stage) {
      case OneClickSwapStage.success:
      case OneClickSwapStage.refunded:
      case OneClickSwapStage.failed:
      case OneClickSwapStage.expired:
        return true;
      case OneClickSwapStage.idle:
      case OneClickSwapStage.quoting:
      case OneClickSwapStage.quoted:
      case OneClickSwapStage.awaitingDeposit:
      case OneClickSwapStage.depositSubmitted:
      case OneClickSwapStage.processing:
        return false;
    }
  }

  OneClickSwapState copyWith({
    OneClickSwapStage? stage,
    OneClickQuoteResponse? quote,
    OneClickStatus? status,
    String? error,
  }) {
    return OneClickSwapState(
      stage: stage ?? this.stage,
      quote: quote ?? this.quote,
      status: status ?? this.status,
      error: error,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}

/// Coordinates quote, deposit notification, status refresh, and polling.
class OneClickSwapController {
  OneClickSwapController({required OneClickClient client}) : _client = client;

  final OneClickClient _client;
  final _states = StreamController<OneClickSwapState>.broadcast(sync: true);
  var _state = OneClickSwapState.idle();

  /// Broadcast stream of every lifecycle transition.
  Stream<OneClickSwapState> get states => _states.stream;

  /// Latest known lifecycle state.
  OneClickSwapState get state => _state;

  /// Requests a quote and moves to either preview or deposit instructions.
  Future<OneClickQuoteResponse> quote(OneClickQuoteRequest request) async {
    _emit(_state.copyWith(stage: OneClickSwapStage.quoting));
    try {
      final response = await _client.quote(request);
      final stage =
          request.dry ||
              request.depositType != OneClickDepositType.originChain ||
              response.quote.depositAddress == null
          ? OneClickSwapStage.quoted
          : OneClickSwapStage.awaitingDeposit;
      _emit(
        OneClickSwapState(
          stage: stage,
          quote: response,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      return response;
    } catch (error) {
      _emit(_state.copyWith(stage: OneClickSwapStage.failed, error: '$error'));
      rethrow;
    }
  }

  /// Notifies 1Click that the user deposited funds on the origin chain.
  Future<void> submitDeposit({
    required String depositAddress,
    required String txHash,
    String? nearSenderAccount,
    String? memo,
  }) async {
    try {
      await _client.submitDeposit(
        depositAddress: depositAddress,
        txHash: txHash,
        nearSenderAccount: nearSenderAccount,
        memo: memo,
      );
      _emit(_state.copyWith(stage: OneClickSwapStage.depositSubmitted));
    } catch (error) {
      _emit(_state.copyWith(stage: OneClickSwapStage.failed, error: '$error'));
      rethrow;
    }
  }

  /// Refreshes status once and updates [state].
  Future<OneClickStatus> refreshStatus({
    required String depositAddress,
    String? depositMemo,
  }) async {
    try {
      final status = await _client.status(
        depositAddress: depositAddress,
        depositMemo: depositMemo,
      );
      _emit(
        _state.copyWith(stage: _stageForStatus(status.kind), status: status),
      );
      return status;
    } catch (error) {
      _emit(_state.copyWith(stage: OneClickSwapStage.failed, error: '$error'));
      rethrow;
    }
  }

  /// Polls until a terminal stage is reached or [timeout] expires.
  Stream<OneClickSwapState> pollStatus({
    required String depositAddress,
    String? depositMemo,
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 5),
  }) async* {
    final deadline = DateTime.now().toUtc().add(timeout);
    while (true) {
      await refreshStatus(
        depositAddress: depositAddress,
        depositMemo: depositMemo,
      );
      yield _state;
      if (_state.isTerminal) return;

      if (DateTime.now().toUtc().isAfter(deadline)) {
        _emit(_state.copyWith(stage: OneClickSwapStage.expired));
        yield _state;
        return;
      }
      if (interval > Duration.zero) {
        await Future<void>.delayed(interval);
      }
    }
  }

  /// Resets the lifecycle without closing the controller.
  void reset() {
    _emit(OneClickSwapState.idle());
  }

  void _emit(OneClickSwapState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  /// Closes lifecycle streams. Does not close the injected [OneClickClient].
  void dispose() {
    _states.close();
  }
}

OneClickSwapStage _stageForStatus(OneClickStatusKind kind) {
  switch (kind) {
    case OneClickStatusKind.pendingDeposit:
      return OneClickSwapStage.awaitingDeposit;
    case OneClickStatusKind.knownDepositTx:
      return OneClickSwapStage.depositSubmitted;
    case OneClickStatusKind.processing:
      return OneClickSwapStage.processing;
    case OneClickStatusKind.success:
      return OneClickSwapStage.success;
    case OneClickStatusKind.incompleteDeposit:
    case OneClickStatusKind.refunded:
      return OneClickSwapStage.refunded;
    case OneClickStatusKind.failed:
    case OneClickStatusKind.unknown:
      return OneClickSwapStage.failed;
  }
}
