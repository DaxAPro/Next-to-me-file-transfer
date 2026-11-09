import 'package:flutter/material.dart';
import '../../../../core/models/device_peer.dart';
import '../../../../core/theme/cyber_colors.dart';
import '../../../common_widgets/cyber_avatar.dart';

/// Modal bottom sheet displaying active network participants with Admin moderation controls.
class ActiveMembersModal extends StatelessWidget {
  final String localDeviceName;
  final bool isHost;
  final List<DevicePeer> connectedPeers;
  final Function(DevicePeer) onRemovePeer;

  const ActiveMembersModal({
    super.key,
    required this.localDeviceName,
    required this.isHost,
    required this.connectedPeers,
    required this.onRemovePeer,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldGreen = Color(0xFF10B981);
    final textPrimary = CyberColors.text(context);
    final textSecondary = CyberColors.subtext(context);
    final surfaceColor = CyberColors.surface(context);
    final borderColor = CyberColors.border(context);

    // Total participants = 1 (ME) + connected peers
    final totalCount = 1 + connectedPeers.length;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Who is in the group?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Active Members ($totalCount)',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isHost
                      ? emeraldGreen.withValues(alpha: 0.15)
                      : CyberColors.electricCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isHost ? '👑 Network Host' : 'Guest Device',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHost ? emeraldGreen : CyberColors.electricCyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. ME Tile (Host or Guest)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CyberAvatar(size: 38, showStatusBadge: true),
            title: Text(
              '$localDeviceName (You)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            subtitle: Text(
              isHost ? 'Group Owner • Can remove peers' : 'Connected to Local Wi-Fi Group',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            trailing: isHost
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: emeraldGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'HOST',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                : null,
          ),
          const Divider(),

          // 2. Connected Peers List
          if (connectedPeers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No other peers connected currently.\nTurn on Wi-Fi Direct or Hotspot to invite friends.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...connectedPeers.map((peer) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF1F5F9),
                    border: Border.all(color: emeraldGreen, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      peer.name.isNotEmpty ? peer.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: emeraldGreen),
                    ),
                  ),
                ),
                title: Text(
                  peer.name,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                subtitle: Text(
                  '${peer.ipAddress} • ${peer.deviceType.name.toUpperCase()}',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
                trailing: isHost
                    ? TextButton.icon(
                        icon: const Icon(Icons.person_remove_outlined, size: 16, color: CyberColors.dangerRed),
                        label: const Text('Remove', style: TextStyle(fontSize: 11, color: CyberColors.dangerRed, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmRemovePeer(context, peer);
                        },
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'GUEST',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textSecondary),
                        ),
                      ),
              );
            }),
        ],
      ),
    );
  }

  void _confirmRemovePeer(BuildContext context, DevicePeer peer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${peer.name}?', style: const TextStyle(fontSize: 16)),
        content: Text(
          'As the Network Host, removing ${peer.name} will disconnect them from this offline chat session.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemovePeer(peer);
            },
            style: ElevatedButton.styleFrom(backgroundColor: CyberColors.dangerRed),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
