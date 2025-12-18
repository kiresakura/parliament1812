import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/player.dart';

/// 角色卡元件
class RoleCardWidget extends StatelessWidget {
  final Role role;

  const RoleCardWidget({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getRoleColor(role.roleType);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // 頂部裝飾
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Center(
              child: Text(
                role.typeName,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 角色名稱和年齡
                Text(
                  role.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${role.age} 歲',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),

                // 角色描述
                Text(
                  role.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 立場
                if (role.stance.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role.stance,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 背景故事
                if (role.background.isNotEmpty) ...[
                  _buildSection('背景故事', role.background),
                  const SizedBox(height: 16),
                ],

                // 角色特點
                if (role.characteristics.isNotEmpty) ...[
                  _buildSection('角色特點', null, items: role.characteristics),
                  const SizedBox(height: 16),
                ],

                // 談話要點
                if (role.talkingPoints.isNotEmpty) ...[
                  _buildSection('談話要點', null, items: role.talkingPoints),
                  const SizedBox(height: 16),
                ],

                // 經典台詞
                if (role.quote.isNotEmpty) ...[
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    '"${role.quote}"',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: color,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content, {List<String>? items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (content != null)
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        if (items != null)
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.grey)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
