import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/valley_provider.dart';
import '../widgets/valley_card.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valley Control'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<ValleyProvider>(
        builder: (context, provider, child) {
          final devices = provider.devices;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              return ValleyCard(device: devices[index]);
            },
          );
        },
      ),
    );
  }
}