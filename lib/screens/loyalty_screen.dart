import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/reverb_service.dart';

class LoyaltyScreen extends StatefulWidget {
  final int customerId;
  const LoyaltyScreen({super.key, required this.customerId});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final ReverbService _reverb = ReverbService();
  StreamSubscription? _reverbSubscription;
  StreamSubscription? _connectionSubscription;

  int? _points;

  @override
  void initState() {
    super.initState();
    _loadInitialPoints();
    
    _reverb.connect();
    final channelName = 'private-loyalty.${widget.customerId}';
    
    void _handleAuth(String socketId) async {
      try {
        final authData = await ApiService.authorizeChannel(socketId, channelName);
        _reverb.subscribeToPrivateChannel(channelName, authData);
      } catch (e) {
        print("Erreur auth Reverb: $e");
      }
    }

    _connectionSubscription = _reverb.onConnected.listen(_handleAuth);

    if (_reverb.socketId != null) {
      _handleAuth(_reverb.socketId!);
    }
    
    _reverbSubscription = _reverb.events.listen(_onRealtimeEvent);
  }

  Future<void> _loadInitialPoints() async {
    try {
      final points = await ApiService.getLoyaltyPoints(widget.customerId);
      if (mounted) {
        setState(() => _points = points);
      }
    } catch (e) {
      print('Erreur de chargement des points: $e');
    }
  }

  void _onRealtimeEvent(Map<String, dynamic> message) {
    final expectedChannel = 'private-loyalty.${widget.customerId}';
    if (message['channel'] == expectedChannel) {
      final data = message['data'] as Map<String, dynamic>;
      if (mounted) {
        setState(() => _points = data['loyalty_points'] as int);
      }
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _reverbSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes points de fidélité')),
      body: Center(
        child: _points == null
            ? const CircularProgressIndicator()
            : Text('$_points points', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
