// widgets/serve_trajectories_widget.dart
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class ServeTrajectoryWidget extends StatefulWidget {
  final GameState gameState;
  final String? selectedPlayerId;
  //final List<Player> players;

  const ServeTrajectoryWidget({
    super.key,
    required this.gameState,
    this.selectedPlayerId,
	//required this.players,
  });

  @override
  _ServeTrajectoryWidgetState createState() => _ServeTrajectoryWidgetState();
}

class _ServeTrajectoryWidgetState extends State<ServeTrajectoryWidget> {
  String? _lastServerId;
  String? _lastServingTeamId;
  String? _lastRotation;

  @override
  void initState() {
    super.initState();
    _lastServerId = _getCurrentServer();
    _lastServingTeamId = widget.gameState.servingTeam.id;
    _lastRotation = widget.gameState.servingTeam.currentRotation;
  }

  @override
  void didUpdateWidget(ServeTrajectoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentServerId = _getCurrentServer();
    final currentServingTeamId = widget.gameState.servingTeam.id;
    final currentRotation = widget.gameState.servingTeam.currentRotation;

    if (_lastServingTeamId != currentServingTeamId ||
        _lastServerId != currentServerId ||
        _lastRotation != currentRotation) {
      
      setState(() {
        _lastServerId = currentServerId;
        _lastServingTeamId = currentServingTeamId;
        _lastRotation = currentRotation;
      });
    }
  }

  String _getCurrentServer() {
    final servingTeam = widget.gameState.servingTeam;
    final serverInZone1 = servingTeam.playerPositions.values
        .where((p) => p.zone == 1)
        .firstOrNull;

    return serverInZone1?.playerId ?? 'UNKNOWN';
  }

  // widgets/serve_trajectories_widget.dart - Metodo _getServeActions
  List<DetailedGameAction> _getServeActions(String playerId) {
  print('📊 _getServeActions per: $playerId');

  // PRIMA: Controlla la storia salvata
  final playerHistory = widget.gameState.serveHistoryManager.getPlayerHistory(playerId);
  print('   - Storia manager per $playerId: ${playerHistory?.serves.length ?? 0} servizi');

  if (playerHistory != null && playerHistory.serves.isNotEmpty) {
    print('   - USANDO storia manager per $playerId');
    final sortedServes = List<DetailedGameAction>.from(playerHistory.serves)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 0; i < sortedServes.length; i++) {
      final serve = sortedServes[i];
      print('     * Servizio ${i + 1}: ${serve.startZone} → ${serve.targetZone}, effetto: ${serve.effect}');
    }

    return sortedServes;
  }

  // FALLBACK: Cerca nelle azioni generali
  final servingTeam = widget.gameState.servingTeam;
  final allServes = widget.gameState.actions
      .where((action) =>
          action.type == ActionType.SERVE &&
          action.playerId == playerId &&
          action.teamId == servingTeam.id &&
          action.startZone != null &&
          action.targetZone != null)
      .toList();

  if (allServes.isNotEmpty) {
    print('   - USANDO fallback azioni generali per $playerId: ${allServes.length} servizi');
    allServes.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // IMPORTANTE: Aggiungi questi servizi alla storia se mancano
    print('   - ⚠️ ATTENZIONE: Servizi trovati nel fallback ma non nella storia!');
    print('   - Questo indica un problema nel salvataggio della storia');

    return allServes;
  }

  print('   - Nessun servizio trovato per $playerId');
  return [];
}

  @override
  Widget build(BuildContext context) {
    final String currentServerId = _getCurrentServer();
    final serveActions = _getServeActions(currentServerId);

    return Container(
      key: ValueKey('serve_trajectory_${widget.gameState.servingTeam.id}_${currentServerId}_${widget.gameState.servingTeam.currentRotation}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(currentServerId),
          const SizedBox(height: 16),
          if (serveActions.isEmpty)
            _buildEmptyState(currentServerId)
          else
            Expanded(child: _buildTrajectoryView(currentServerId, serveActions)),
        ],
      ),
    );
  }

  Widget _buildTrajectoryView(String currentServerId, List<DetailedGameAction> serves) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: CustomPaint(
              painter: ServeTrajectoryPainter(serves, widget.gameState, currentServerId),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: _buildServesList(serves),
        ),
      ],
    );
  }

  Widget _buildServesList(List<DetailedGameAction> serves) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Ultimi ${serves.length} servizi',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: serves.length,
              itemBuilder: (context, index) {
                final serve = serves[index];
                final chronologicalNumber = serves.length - index;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getEffectColor(serve.effect).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getEffectColor(serve.effect).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getEffectColor(serve.effect),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$chronologicalNumber',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${serve.startZone} → ${serve.targetZone}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Effetto: ${serve.effect ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _formatTime(serve.timestamp),
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String serverId) {
    final servingTeam = widget.gameState.servingTeam;
    final serverPosition = servingTeam.playerPositions.values
        .where((p) => p.playerId == serverId)
        .firstOrNull;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            servingTeam.color.withOpacity(0.15),
            servingTeam.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: servingTeam.color.withOpacity(0.4), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: servingTeam.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: servingTeam.color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_volleyball,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AL SERVIZIO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: servingTeam.color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade600,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'ZONA 1',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${servingTeam.name} - $serverId',
                  style: TextStyle(
                    fontSize: 14,
                    color: servingTeam.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      servingTeam.currentRotation,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (serverPosition != null) ...[
                      Text(
                        ' • ${serverPosition.role.name}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildStats(serverId),
        ],
      ),
    );
  }

    Widget _buildStats(String serverId) {
    final serves = _getServeActions(serverId);
    final total = serves.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1), // Ridotto padding
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            total.toString(),
            style: const TextStyle(
              fontSize: 9, // Ridotto font size
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Text(
            'Servizi',
            style: TextStyle(fontSize: 5), // Ridotto font size
          ),
          const SizedBox(height: 1), // Ridotto spazio
          Row(
            mainAxisSize: MainAxisSize.min, // Assicura che la riga sia compatta
            children: [
              Text(
                'A: ${serves.where((s) => s.effect == '#').length} ',
                style: const TextStyle(fontSize: 5, color: Colors.green), // Ridotto font size
              ),
              Text(
                'E: ${serves.where((s) => s.isError).length}',
                style: const TextStyle(fontSize: 5, color: Colors.red), // Ridotto font size
              ),
            ],
          ),
          Text(
            '${total > 0 ? ((total - serves.where((s) => s.isError).length) / total * 100).round() : 0}%',
            style: const TextStyle(fontSize: 5, fontWeight: FontWeight.bold), // Ridotto font size
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String serverId) {
    final servingTeam = widget.gameState.servingTeam;
    
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: servingTeam.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_volleyball_outlined,
                size: 48,
                color: servingTeam.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Primo servizio di $serverId',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: servingTeam.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              servingTeam.name,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Le traiettorie appariranno dopo il primo servizio',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Color _getEffectColor(String? effect) {
    switch (effect) {
      case '#': return Colors.green;
      case '=': return Colors.red;
      case '/': return Colors.purple;
      case '!': return Colors.blue;
      case '+': return Colors.orange;
      case '-': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

// CustomPainter per le traiettorie
class ServeTrajectoryPainter extends CustomPainter {
  final List<DetailedGameAction> serves;
  final GameState gameState;
  final String currentServerId;

  ServeTrajectoryPainter(this.serves, this.gameState, this.currentServerId);

  @override
  void paint(Canvas canvas, Size size) {
    _drawCourt(canvas, size);
    _drawZoneNumbers(canvas, size);
    _drawTrajectories(canvas, size);
    _drawLegend(canvas, size);
  }

  void _drawCourt(Canvas canvas, Size size) {
    final courtPaint = Paint()
      ..color = Colors.green.shade100
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final serveAreaHeight = size.height * 0.3;
    final courtHeight = size.height * 0.6;
    final courtTop = serveAreaHeight;

    // Zona di servizio
    final serveAreaRect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.05,
      size.width * 0.8,
      serveAreaHeight - size.height * 0.05,
    );
    canvas.drawRect(serveAreaRect, Paint()..color = Colors.orange.shade50);
    canvas.drawRect(serveAreaRect, Paint()
      ..color = Colors.orange.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Campo da gioco
    final courtRect = Rect.fromLTWH(
      size.width * 0.1,
      courtTop,
      size.width * 0.8,
      courtHeight,
    );
    canvas.drawRect(courtRect, courtPaint);
    canvas.drawRect(courtRect, linePaint);

    // Rete
    final netY = courtTop + courtHeight * 0.5;
    canvas.drawLine(
      Offset(size.width * 0.1, netY),
      Offset(size.width * 0.9, netY),
      Paint()
        ..color = Colors.brown
        ..strokeWidth = 4,
    );

    _drawCourtLines(canvas, size, linePaint, courtTop, courtHeight);
    _drawServeAreaLines(canvas, size, serveAreaRect);
  }

  void _drawCourtLines(Canvas canvas, Size size, Paint linePaint, double courtTop, double courtHeight) {
    final leftX = size.width * 0.1;
    final rightX = size.width * 0.9;
    final netY = courtTop + courtHeight * 0.5;
    final bottomY = courtTop + courtHeight;

    // Linee verticali
    for (int i = 1; i <= 2; i++) {
      final x = leftX + (rightX - leftX) * i / 3;
      canvas.drawLine(Offset(x, netY), Offset(x, bottomY), linePaint);
    }

    // Linee orizzontali
    for (int i = 1; i <= 2; i++) {
      final bottomFieldY = netY + (bottomY - netY) * i / 3;
      canvas.drawLine(Offset(leftX, bottomFieldY), Offset(rightX, bottomFieldY), linePaint);
    }
  }

  void _drawServeAreaLines(Canvas canvas, Size size, Rect serveArea) {
    final linePaint = Paint()
      ..color = Colors.orange.shade400
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 2; i++) {
      final x = serveArea.left + (serveArea.width * i / 3);
      canvas.drawLine(
        Offset(x, serveArea.top),
        Offset(x, serveArea.bottom),
        linePaint,
      );
    }
  }

  void _drawZoneNumbers(Canvas canvas, Size size) {
    const textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    // Zone di servizio
    final serveZones = [1, 6, 5];
    for (int i = 0; i < serveZones.length; i++) {
      _drawServeZoneNumber(canvas, size, serveZones[i], i, textStyle);
    }

    // Zone ricezione
    final row1Zones = [4, 3, 2];
    for (int i = 0; i < row1Zones.length; i++) {
      _drawZoneNumber(canvas, size, row1Zones[i], false, 0, i, textStyle);
    }

    final row2Zones = [7, 8, 9];
    for (int i = 0; i < row2Zones.length; i++) {
      _drawZoneNumber(canvas, size, row2Zones[i], false, 1, i, textStyle);
    }

    final row3Zones = [5, 6, 1];
    for (int i = 0; i < row3Zones.length; i++) {
      _drawZoneNumber(canvas, size, row3Zones[i], false, 2, i, textStyle);
    }
  }

  void _drawServeZoneNumber(Canvas canvas, Size size, int zone, int col, TextStyle textStyle) {
    final leftX = size.width * 0.1;
    final rightX = size.width * 0.9;
    final fieldWidth = rightX - leftX;
    final zoneWidth = fieldWidth / 3;
    
    final serveAreaHeight = size.height * 0.3;
    final x = leftX + (col + 0.5) * zoneWidth;
    final y = serveAreaHeight * 0.5;
    
    final position = Offset(x, y);
    
    final textPainter = TextPainter(
      text: TextSpan(text: zone.toString(), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final bgRect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 12,
      height: textPainter.height + 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()..color = Colors.orange.withOpacity(0.8),
    );
    
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  void _drawZoneNumber(Canvas canvas, Size size, int zone, bool isServeField, int row, int col, TextStyle textStyle) {
    final leftX = size.width * 0.1;
    final rightX = size.width * 0.9;
    final courtTop = size.height * 0.3;
    final courtHeight = size.height * 0.6;
    final netY = courtTop + courtHeight * 0.5;

    final fieldWidth = rightX - leftX;
    final zoneWidth = fieldWidth / 3;
    final receptionAreaHeight = courtHeight * 0.5;
    final zoneHeight = receptionAreaHeight / 3;
    
    final x = leftX + (col + 0.5) * zoneWidth;
    final y = netY + (row + 0.5) * zoneHeight;

    final position = Offset(x, y);
    
    final textPainter = TextPainter(
      text: TextSpan(text: zone.toString(), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final bgRect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  void _drawTrajectories(Canvas canvas, Size size) {
    for (int i = serves.length - 1; i >= 0; i--) {
      final serve = serves[i];

      if (serve.playerId != currentServerId) {
        continue;
      }

      final serveZone = serve.startZone;
      final targetZone = serve.targetZone;
      final chronologicalNumber = serves.length - i;
      
      if (serveZone != null && targetZone != null) {
        _drawTrajectory(canvas, size, serve, serveZone, targetZone, chronologicalNumber);
      }
    }
  }

  void _drawTrajectory(Canvas canvas, Size size, DetailedGameAction serve, int serveZone, int targetZone, int chronologicalNumber) {
    final startPos = _getZonePosition(serveZone, true, size);
    final endPos = _getZonePosition(targetZone, false, size);
    
    final color = _getEffectColor(serve.effect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Traiettoria curva
    final controlPoint = Offset(
      (startPos.dx + endPos.dx) / 2,
      startPos.dy - 30,
    );
    
    final path = Path()
      ..moveTo(startPos.dx, startPos.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPos.dx, endPos.dy);
    
    canvas.drawPath(path, paint);
    
    // Freccia
    _drawArrowHead(canvas, controlPoint, endPos, paint);
    
    // Numero
    _drawServeNumber(canvas, startPos, chronologicalNumber, color);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowSize = 8.0;
    final angle = (end - start).direction;
    
    final arrowP1 = end + Offset.fromDirection(angle + 2.8, arrowSize);
    final arrowP2 = end + Offset.fromDirection(angle - 2.8, arrowSize);
    
    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowP1.dx, arrowP1.dy)
      ..lineTo(arrowP2.dx, arrowP2.dy)
      ..close();
    
    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawServeNumber(Canvas canvas, Offset position, int number, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    canvas.drawCircle(position, 8, Paint()..color = color);
    
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  void _drawLegend(Canvas canvas, Size size) {
    final legendItems = [
      {'color': Colors.green, 'text': 'ACE (#)'},
      {'color': Colors.purple, 'text': 'Indietro (/)'},
      {'color': Colors.blue, 'text': 'No Cent (!)'},
      {'color': Colors.red, 'text': 'Errore (=)'},
    ];

    final fieldRight = size.width * 0.9;
    final startX = fieldRight + 10;
    final startY = size.height * 0.35;
    
    final availableWidth = size.width - startX;
    if (availableWidth < 80) return;
    
    final legendWidth = availableWidth - 5;
    final legendHeight = legendItems.length * 16.0 + 10;
    
    final legendRect = Rect.fromLTWH(startX, startY, legendWidth, legendHeight);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(legendRect, const Radius.circular(6)),
      Paint()..color = Colors.white.withOpacity(0.95),
    );
    
    for (int i = 0; i < legendItems.length; i++) {
      final item = legendItems[i];
      final y = startY + 8 + (i * 16);
      
      canvas.drawCircle(
        Offset(startX + 8, y + 6),
        3,
        Paint()..color = item['color'] as Color,
      );
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: item['text'] as String,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX + 18, y));
    }
  }

  Offset _getZonePosition(int zone, bool isServeField, Size size) {
    final leftX = size.width * 0.1;
    final rightX = size.width * 0.9;
    final fieldWidth = rightX - leftX;
    final zoneWidth = fieldWidth / 3;

    if (isServeField) {
      final serveZones = [1, 6, 5];
      final col = serveZones.indexOf(zone);
      if (col == -1) return Offset(size.width / 2, size.height * 0.15);

      return Offset(
        leftX + (col + 0.5) * zoneWidth,
        size.height * 0.15,
      );
    } else {
      final courtTop = size.height * 0.3;
      final courtHeight = size.height * 0.6;
      final netY = courtTop + courtHeight * 0.5;
      
      int row = -1, col = -1;
      final actualZone = zone > 100 ? zone - 100 : zone;
      
      if ([4, 3, 2].contains(actualZone)) {
        row = 0;
        col = [4, 3, 2].indexOf(actualZone);
      } else if ([7, 8, 9].contains(actualZone)) {
        row = 1;
        col = [7, 8, 9].indexOf(actualZone);
      } else if ([5, 6, 1].contains(actualZone)) {
        row = 2;
        col = [5, 6, 1].indexOf(actualZone);
      }
      
      if (row == -1 || col == -1) {
        return Offset(leftX + zoneWidth, netY + courtHeight * 0.25);
      }
      
      final receptionHeight = courtHeight * 0.5;
      final zoneHeight = receptionHeight / 3;
      
      return Offset(
        leftX + (col + 0.5) * zoneWidth,
        netY + (row + 0.5) * zoneHeight,
      );
    }
  }

  Color _getEffectColor(String? effect) {
    switch (effect) {
      case '#': return Colors.green;
      case '=': return Colors.red;
      case '/': return Colors.purple;
      case '!': return Colors.blue;
      case '+': return Colors.orange;
      case '-': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! ServeTrajectoryPainter) return true;
    return serves != oldDelegate.serves;
  }
}
