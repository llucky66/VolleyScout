import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Stato per Regole di Gioco
  int _maxSets = 5;
  final _normalSetScoreController = TextEditingController(text: '25');
  final _finalSetScoreController = TextEditingController(text: '15');
  bool _useLibero = true;
  String _formationSchema = 'PSC';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _maxSets = prefs.getInt('maxSets') ?? 5;
        _normalSetScoreController.text = (prefs.getInt('normalSetScore') ?? 25).toString();
        _finalSetScoreController.text = (prefs.getInt('finalSetScore') ?? 15).toString();
        _useLibero = prefs.getBool('useLibero') ?? true;
        _formationSchema = prefs.getString('formationSchema') ?? 'PSC';
      });
    } catch (e) {
      print('Errore caricamento impostazioni: $e');
      // Gestisci l'errore in modo appropriato (es. visualizza un messaggio)
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('maxSets', _maxSets);
      await prefs.setString('formationSchema', _formationSchema);
      try {
        await prefs.setInt('normalSetScore', int.parse(_normalSetScoreController.text));
        await prefs.setInt('finalSetScore', int.parse(_finalSetScoreController.text));
      } catch (e) {
        print('Errore parsing punteggio set: $e');
        // Gestisci l'errore in modo appropriato (es. visualizza un messaggio)
      }
      await prefs.setBool('useLibero', _useLibero);
    } catch (e) {
      print('Errore salvataggio impostazioni: $e');
      // Gestisci l'errore in modo appropriato (es. visualizza un messaggio)
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _normalSetScoreController.dispose();
    _finalSetScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Regole di Gioco'),
            Tab(text: 'Altro'), // Puoi aggiungere altri tab in futuro
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGameRulesTab(),
          const Center(child: Text('Altre impostazioni...')), // Placeholder per altri tab
        ],
      ),
    );
  }

  Widget _buildGameRulesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildGameLengthSettings(),
          const SizedBox(height: 16),
          _buildSetScoreSettings(),
          const SizedBox(height: 16),
          _buildLiberoSettings(),
          const SizedBox(height: 16),
          _buildPlayerFormationSettings(),
        ],
      ),
    );
  }

  Widget _buildGameLengthSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Durata Partita', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Numero di set:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _maxSets,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 (Best of 3)')),
                    DropdownMenuItem(value: 5, child: Text('5 (Best of 5)')),
                    DropdownMenuItem(value: 0, child: Text('Nessun limite')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _maxSets = value!;
                      _saveSettings();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetScoreSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Punteggio Set', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Punteggio set normali:'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                    controller: _normalSetScoreController,
                    onChanged: (value) {
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Punteggio ultimo set:'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.all(8)),
                    controller: _finalSetScoreController,
                    onChanged: (value) {
                      _saveSettings();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiberoSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Utilizzo Libero', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Usa il Libero:'),
                const SizedBox(width: 16),
                Switch(
                  value: _useLibero,
                  onChanged: (value) {
                    setState(() {
                      _useLibero = value;
                      _saveSettings();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerFormationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schema Formazione', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Schema:'),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _formationSchema,
                  items: const [
                    DropdownMenuItem(value: 'PSC', child: Text('P-S-C')),
                    DropdownMenuItem(value: 'PCS', child: Text('P-C-S')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _formationSchema = value!;
                      _saveSettings();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
