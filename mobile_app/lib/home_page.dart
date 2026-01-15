import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'room_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MqttServerClient client;

  final String broker = 'broker.hivemq.com';
  final String statusTopic = 'esp32/status';

  String status = "Déconnecté";
  String espStatus = "Hors ligne";

  final List<Map<String, dynamic>> rooms = [
    {'name': 'Chambre 1', 'topic': 'esp32/room1', 'icon': Icons.bedroom_parent},
    {'name': 'Chambre 2', 'topic': 'esp32/room2', 'icon': Icons.bedroom_child},
    {'name': 'Salon',     'topic': 'esp32/room3', 'icon': Icons.living},
  ];

  @override
  void initState() {
    super.initState();
    connect();
  }

  Future<void> connect() async {
    client = MqttServerClient(
      broker,
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
    );
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.logging(on: false);

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean();

    try {
      await client.connect();
      setState(() => status = "Connecté");

      client.subscribe(statusTopic, MqttQos.atLeastOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage msg = c[0].payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(
          msg.payload.message,
        ).trim();

        if (c[0].topic == statusTopic) {
          setState(() {
            espStatus = pt.toLowerCase() == "online" ? "En ligne" : "Hors ligne";
          });
        }
      });
    } catch (e) {
      setState(() => status = "Échec de connexion");
      client.disconnect();
    }
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Contrôle des Volets',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    label: "Lien App",
                    value: status,
                    icon: status == "Connecté" ? Icons.cloud_done : Icons.cloud_off,
                    color: status == "Connecté" ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    label: "Appareil ESP32",
                    value: espStatus,
                    icon: espStatus == "En ligne" ? Icons.memory : Icons.developer_board_off,
                    color: espStatus == "En ligne" ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              "Choisir une pièce",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),

            // Room Cards
            ...rooms.map((room) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRoomCard(room),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(room['icon'] as IconData, color: Colors.indigo, size: 28),
        ),
        title: Text(
          room['name'] as String,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          espStatus == "En ligne" ? "ESP32 connecté" : "ESP32 hors ligne",
          style: TextStyle(
            color: espStatus == "En ligne" ? Colors.green : Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomPage(
                roomName: room['name'] as String,
                topic: room['topic'] as String,
                client: client,
              ),
            ),
          );
        },
      ),
    );
  }
}