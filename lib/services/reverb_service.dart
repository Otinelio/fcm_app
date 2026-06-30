import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReverbService {
  static final ReverbService _instance = ReverbService._internal();
  
  factory ReverbService() {
    return _instance;
  }
  
  ReverbService._internal();

  String get appKey => dotenv.env['REVERB_APP_KEY'] ?? '';
  String get host => dotenv.env['REVERB_HOST'] ?? '127.0.0.1';
  int get port => int.tryParse(dotenv.env['REVERB_PORT'] ?? '80') ?? 80;

  WebSocketChannel? _channel;
  String? socketId;

  final _eventsController = StreamController<Map<String, dynamic>>.broadcast();

  /// Flux des événements métier (hors messages internes pusher:*)
  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  final _connectionStateController = StreamController<String>.broadcast();

  /// Flux émettant le socketId chaque fois que la connexion est établie
  Stream<String> get onConnected => _connectionStateController.stream;

  void connect() {
    if (_channel != null) return; // Déjà connecté

    final url = 'ws://$host:$port/app/$appKey';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (rawMessage) {
        final message =
            jsonDecode(rawMessage as String) as Map<String, dynamic>;
        _handleMessage(message);
      },
      onError: (error) {
        print('Erreur WebSocket : $error');
        _channel = null;
        socketId = null;
      },
      onDone: () {
        print('Connexion WebSocket fermée');
        _channel = null;
        socketId = null;
        // Reconnexion automatique après 5 secondes si la connexion coupe
        Future.delayed(const Duration(seconds: 5), () {
          print('Tentative de reconnexion...');
          connect();
        });
      },
    );
  }

  void _handleMessage(Map<String, dynamic> message) {
    final event = message['event'] as String?;

    // Réponse au ping pour garder la connexion active (Heartbeat)
    if (event == 'pusher:ping') {
      _channel?.sink.add(jsonEncode({'event': 'pusher:pong'}));
      return;
    }

    if (event == 'pusher:connection_established') {
      final data =
          jsonDecode(message['data'] as String) as Map<String, dynamic>;
      socketId = data['socket_id'] as String;
      print('Connecté à Reverb. socket_id = $socketId');
      
      _connectionStateController.add(socketId!);
      
      // Se réabonner automatiquement aux canaux publics en cas de reconnexion
      for (final channel in _activeChannels) {
        // Les canaux privés devront être réautorisés par l'UI via le flux onConnected
        if (!channel.startsWith('private-')) {
          subscribeToChannel(channel);
        }
      }
      return;
    }

    if (event == 'pusher_internal:subscription_succeeded') {
      final channel = message['channel'] as String?;
      if (channel != null && channel.startsWith('presence-customer.')) {
        final customerId = channel.split('.').last;
        print('Presence channel rejoint pour customer $customerId');
      } else {
        print('Abonnement confirmé sur $channel');
      }
      return;
    }

    // Événement métier : on le republie sur notre propre Stream, sous une forme utilisable
    _eventsController.add({
      'event': event,
      'channel': message['channel'],
      'data': jsonDecode(message['data'] as String),
    });
  }

  final Set<String> _activeChannels = {};

  void subscribeToChannel(String channelName) {
    _activeChannels.add(channelName);
    _channel?.sink.add(
      jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName},
      }),
    );
  }

  void subscribeToPrivateChannel(String channelName, Map<String, dynamic> authData) {
    _channel?.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
        'auth': authData['auth'],
      },
    }));
  }

  void subscribeToPresenceChannel(String channelName, Map<String, dynamic> authData) {
    final data = <String, dynamic>{
      'channel': channelName,
      'auth': authData['auth'],
    };
    if (authData.containsKey('channel_data')) {
      data['channel_data'] = authData['channel_data'];
    }

    _channel?.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': data,
    }));
  }

  void disconnect() {
    _activeChannels.clear();
    _eventsController.close();
    _connectionStateController.close();
    _channel?.sink.close();
    _channel = null;
    socketId = null;
  }
}
