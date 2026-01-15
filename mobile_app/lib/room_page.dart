import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class RoomPage extends StatefulWidget {
  final String roomName;
  final String topic;
  final MqttServerClient client;

  const RoomPage({
    super.key,
    required this.roomName,
    required this.topic,
    required this.client,
  });

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final TextEditingController controller = TextEditingController();
  double _forceValue = 50.0;

  void _sendMqttMessage(String message) {
    if (widget.client.connectionStatus?.state != MqttConnectionState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Non connecté au serveur MQTT")),
      );
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    widget.client.publishMessage(widget.topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      _sendMqttMessage(text);
      controller.clear();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.roomName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Force Control Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.speed, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          "Niveau de descente",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${_forceValue.toInt()}%",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.indigo,
                      ),
                    ),
                    Slider(
                      value: _forceValue,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: Colors.indigo,
                      inactiveColor: Colors.indigo.withOpacity(0.2),
                      onChanged: (value) => setState(() => _forceValue = value),
                      onChangeEnd: (value) => _sendMqttMessage(value.toInt().toString()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Directional Controls
            Row(
              children: [
                Expanded(
                  child: _buildControlBtn(
                    label: "HAUT",
                    icon: Icons.arrow_upward,
                    color: Colors.blueAccent,
                    onPressed: () => _sendMqttMessage("up"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildControlBtn(
                    label: "BAS",
                    icon: Icons.arrow_downward,
                    color: Colors.orangeAccent,
                    onPressed: () => _sendMqttMessage("down"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Manual Message Input
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: "Commande Manuelle",
                        hintText: "Entrez une commande...",
                        prefixIcon: const Icon(Icons.terminal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: sendMessage,
                      icon: const Icon(Icons.send),
                      label: const Text("Envoyer la Commande"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}