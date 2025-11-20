import 'package:flutter/material.dart';

/// Pantalla de configuración de la aplicación.
/// 
/// Permite al usuario ajustar preferencias como sonido, dificultad, etc.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Variables de configuración
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _difficulty = 1.0; // 0: Fácil, 1: Normal, 2: Difícil
  String _selectedCarColor = 'Naranja';

  // Opciones disponibles
  final List<String> _carColors = ['Naranja', 'Azul', 'Rojo', 'Verde', 'Amarillo'];

  String _getDifficultyLabel(double value) {
    if (value == 0.0) return 'Fácil';
    if (value == 1.0) return 'Normal';
    return 'Difícil';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección: Audio
          _buildSectionHeader('Audio'),
          _buildSwitchTile(
            title: 'Sonido',
            subtitle: 'Activar efectos de sonido',
            value: _soundEnabled,
            icon: _soundEnabled ? Icons.volume_up : Icons.volume_off,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Vibración',
            subtitle: 'Activar vibración al tocar',
            value: _vibrationEnabled,
            icon: _vibrationEnabled ? Icons.vibration : Icons.phonelink_erase,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
          
          const Divider(height: 40),
          
          // Sección: Juego
          _buildSectionHeader('Juego'),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Text(
                        'Dificultad: ${_getDifficultyLabel(_difficulty)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _difficulty,
                    min: 0.0,
                    max: 2.0,
                    divisions: 2,
                    label: _getDifficultyLabel(_difficulty),
                    onChanged: (value) {
                      setState(() {
                        _difficulty = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Selector de color de coche
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.deepPurple),
              title: const Text(
                'Color del coche',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(_selectedCarColor),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showCarColorDialog();
              },
            ),
          ),
          
          const Divider(height: 40),
          
          // Sección: Acerca de
          _buildSectionHeader('Acerca de'),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
                  title: const Text('Versión'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code, color: Colors.deepPurple),
                  title: const Text('Desarrollador'),
                  subtitle: const Text('Tu nombre'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _showResetDialog();
                },
                icon: const Icon(Icons.restore),
                label: const Text('Restaurar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _saveSettings();
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: Colors.deepPurple),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }

  void _showCarColorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar color del coche'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _carColors.map((color) {
              return RadioListTile<String>(
                title: Text(color),
                value: color,
                groupValue: _selectedCarColor,
                onChanged: (String? value) {
                  setState(() {
                    _selectedCarColor = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restaurar configuración'),
          content: const Text(
            '¿Estás seguro de que deseas restaurar la configuración a los valores predeterminados?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _soundEnabled = true;
                  _vibrationEnabled = true;
                  _difficulty = 1.0;
                  _selectedCarColor = 'Naranja';
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración restaurada'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
  }

  void _saveSettings() {
    // Aquí puedes guardar la configuración en SharedPreferences o base de datos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada correctamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}