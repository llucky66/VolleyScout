// widgets/live_stats_widget.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/stats_service.dart';

class LiveStatsWidget extends StatelessWidget {
  final GameState gameState;
  final String? selectedPlayerId;
  final Function(String)? onPlayerSelected;

  const LiveStatsWidget({
    super.key,
    required this.gameState,
    this.selectedPlayerId,
    this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: selectedPlayerId != null
                ? _buildPlayerStats()
                : _buildTeamStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.analytics, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          selectedPlayerId != null ? 'Statistiche Giocatore' : 'Statistiche Squadra',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (selectedPlayerId != null)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => onPlayerSelected?.call(''),
            tooltip: 'Torna alle statistiche squadra',
          ),
      ],
    );
  }

  Widget _buildTeamStats() {
    final homeStats = StatsService.calculateTeamStats(gameState.actions, gameState.homeTeam.id);
    final awayStats = StatsService.calculateTeamStats(gameState.actions, gameState.awayTeam.id);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTeamComparison('Servizio', homeStats['serve'], awayStats['serve']),
          const SizedBox(height: 16),
          _buildTeamComparison('Ricezione', homeStats['reception'], awayStats['reception']),
          const SizedBox(height: 16),
          _buildTeamComparison('Attacco', homeStats['attack'], awayStats['attack']),
          const SizedBox(height: 16),
          _buildTeamComparison('Muro', homeStats['block'], awayStats['block']),
          const SizedBox(height: 16),
          _buildRallyStats(homeStats['rallies'], awayStats['rallies']),
        ],
      ),
    );
  }

  Widget _buildPlayerStats() {
    if (selectedPlayerId == null) return Container();

    final stats = StatsService.calculatePlayerStats(gameState.actions, selectedPlayerId!);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giocatore: $selectedPlayerId',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPlayerStatCard('Servizio', stats['serve'], Icons.sports_volleyball),
          const SizedBox(height: 12),
          _buildPlayerStatCard('Ricezione', stats['reception'], Icons.sports_handball),
          const SizedBox(height: 12),
          _buildPlayerStatCard('Attacco', stats['attack'], Icons.sports_tennis),
          const SizedBox(height: 12),
          _buildPlayerStatCard('Muro', stats['block'], Icons.block),
          const SizedBox(height: 12),
          _buildPlayerStatCard('Alzata', stats['set'], Icons.touch_app),
          const SizedBox(height: 12),
          _buildPlayerStatCard('Difesa', stats['dig'], Icons.shield),
        ],
      ),
    );
  }

  Widget _buildTeamComparison(String title, Map<String, dynamic> homeStats, Map<String, dynamic> awayStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameState.homeTeam.name,
                        style: TextStyle(
                          color: gameState.homeTeam.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatRow('Totale', homeStats['total']),
                      _buildStatRow('Efficienza', '${homeStats['efficiency']}%'),
                      if (homeStats['errors'] != null)
                        _buildStatRow('Errori', homeStats['errors']),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        gameState.awayTeam.name,
                        style: TextStyle(
                          color: gameState.awayTeam.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatRow('Totale', awayStats['total'], isRight: true),
                      _buildStatRow('Efficienza', '${awayStats['efficiency']}%', isRight: true),
                      if (awayStats['errors'] != null)
                        _buildStatRow('Errori', awayStats['errors'], isRight: true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStatCard(String title, Map<String, dynamic> stats, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatChip('Tot', stats['total']),
                if (stats['efficiency'] != null)
                  _buildStatChip('Eff', '${stats['efficiency']}%'),
                if (stats['errors'] != null)
                  _buildStatChip('Err', stats['errors']),
                if (stats['aces'] != null)
                  _buildStatChip('Ace', stats['aces']),
                if (stats['kills'] != null)
                  _buildStatChip('Kill', stats['kills']),
                if (stats['perfect'] != null)
                  _buildStatChip('Perf', stats['perfect']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value, {bool isRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isRight) ...[
            Text(
              '$label: ',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' :$label',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildRallyStats(Map<String, dynamic> homeRallies, Map<String, dynamic> awayRallies) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiche Rally',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameState.homeTeam.name,
                        style: TextStyle(
                          color: gameState.homeTeam.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatRow('Rally vinti', homeRallies['won_rallies']),
                      _buildStatRow('% Vittorie', '${homeRallies['win_percentage']}%'),
                      _buildStatRow('Lungh. media', homeRallies['average_length']),
                    ],
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        gameState.awayTeam.name,
                        style: TextStyle(
                          color: gameState.awayTeam.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatRow('Rally vinti', awayRallies['won_rallies'], isRight: true),
                      _buildStatRow('% Vittorie', '${awayRallies['win_percentage']}%', isRight: true),
                      _buildStatRow('Lungh. media', awayRallies['average_length'], isRight: true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
