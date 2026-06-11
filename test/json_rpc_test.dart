import 'package:test/test.dart';
import 'package:near_dart/near_dart.dart';

void main() {
  group('JsonRpcRequest', () {
    test('serializes to correct JSON-RPC 2.0 format', () {
      final request = JsonRpcRequest(
        method: 'status',
        params: <String, dynamic>{},
      );

      final json = request.toJson();

      expect(json['jsonrpc'], equals('2.0'));
      expect(json['method'], equals('status'));
      expect(json['params'], isA<Map>());
      expect(json['id'], isNotNull);
    });

    test('generates unique ids for each request', () {
      final request1 = JsonRpcRequest(method: 'status', params: {});
      final request2 = JsonRpcRequest(method: 'status', params: {});

      expect(request1.id, isNot(equals(request2.id)));
    });

    test('allows custom id', () {
      final request = JsonRpcRequest(
        method: 'block',
        params: {'finality': 'final'},
        id: 'custom-id-123',
      );

      expect(request.id, equals('custom-id-123'));
    });

    test('serializes params correctly', () {
      final request = JsonRpcRequest(
        method: 'query',
        params: {
          'request_type': 'view_account',
          'account_id': 'test.near',
          'finality': 'final',
        },
      );

      final json = request.toJson();

      expect(json['params']['request_type'], equals('view_account'));
      expect(json['params']['account_id'], equals('test.near'));
    });
  });

  group('JsonRpcResponse', () {
    test('parses successful response', () {
      final responseJson = {
        'jsonrpc': '2.0',
        'id': 'dontcare',
        'result': {
          'version': {'version': '1.0.0'},
          'chain_id': 'testnet',
        },
      };

      final response = JsonRpcResponse.fromJson(responseJson);

      expect(response.isSuccess, isTrue);
      expect(response.isError, isFalse);
      expect(response.result, isNotNull);
      expect(response.error, isNull);
    });

    test('parses error response', () {
      final responseJson = {
        'jsonrpc': '2.0',
        'id': 'dontcare',
        'error': {
          'code': -32000,
          'message': 'Server error',
          'data': 'Account not found',
        },
      };

      final response = JsonRpcResponse.fromJson(responseJson);

      expect(response.isSuccess, isFalse);
      expect(response.isError, isTrue);
      expect(response.error, isNotNull);
      expect(response.error!.code, equals(-32000));
      expect(response.error!.message, equals('Server error'));
    });

    test('handles null result correctly', () {
      final responseJson = {'jsonrpc': '2.0', 'id': 'dontcare', 'result': null};

      final response = JsonRpcResponse.fromJson(responseJson);

      expect(response.isSuccess, isTrue);
      expect(response.result, isNull);
    });
  });

  group('JsonRpcError', () {
    test('parses standard JSON-RPC error', () {
      final errorJson = {'code': -32600, 'message': 'Invalid Request'};

      final error = JsonRpcError.fromJson(errorJson);

      expect(error.code, equals(-32600));
      expect(error.message, equals('Invalid Request'));
      expect(error.data, isNull);
    });

    test('parses error with data', () {
      final errorJson = {
        'code': -32000,
        'message': 'Server error',
        'data': {
          'cause': {'name': 'UNKNOWN_ACCOUNT'},
        },
      };

      final error = JsonRpcError.fromJson(errorJson);

      expect(error.data, isNotNull);
      expect(error.data, isA<Map>());
    });
  });
}
