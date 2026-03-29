
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/read_aloud/http_read_aloud.dart';
import '../../ui/widgets/gold_app_bar.dart';
import '../../ui/widgets/gold_card.dart';
import '../../ui/theme/app_theme.dart';

class CloneTtsSettingsScreen extends ConsumerStatefulWidget {
  const CloneTtsSettingsScreen({super.key});

  @override
  ConsumerState&lt;CloneTtsSettingsScreen&gt; createState() =&gt; _CloneTtsSettingsScreenState();
}

class _CloneTtsSettingsScreenState extends ConsumerState&lt;CloneTtsSettingsScreen&gt; {
  final TextEditingController _voiceController = TextEditingController();
  double _speechRate = 1.0;
  bool _isEnabled = false;

  final HttpReadAloud _httpReadAloud = HttpReadAloud();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future&lt;void&gt; _loadConfig() async {
    final config = _httpReadAloud.config;
    if (config != null &amp;&amp; config.preset == HttpTtsPreset.cloneTts) {
      setState(() {
        _voiceController.text = config.voiceId ?? '';
        _speechRate = config.speechRate ?? 1.0;
        _isEnabled = true;
      });
    }
  }

  void _applyConfig() {
    final config = HttpTtsConfig.cloneTts(
      voice: _voiceController.text,
      speechRate: _speechRate,
    );
    _httpReadAloud.setConfig(config);
    setState(() {
      _isEnabled = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CloneTTS 配置已应用'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _disableConfig() {
    setState(() {
      _isEnabled = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CloneTTS 已禁用'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: const GoldAppBar(title: 'CloneTTS 设置'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GoldCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CloneTTS 集成',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '快速启用 CloneTTS 本地 TTS 引擎，享受离线音色克隆和高保真朗读',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GoldCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '第一步：下载 CloneTTS',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.download, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '访问 GitHub Releases 下载',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'https://github.com/sipeter/CloneTTS/releases',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                        onPressed: () {
                          launchUrl(
                            Uri.parse('https://github.com/sipeter/CloneTTS/releases'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GoldCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '使用说明',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStep(1, '安装 CloneTTS 应用后首次打开，等待模型数据解压完成'),
                  _buildStep(2, '在 CloneTTS 的「音色管理」页面添加音色：\n• 点击右上角 ⋮ → 添加音色\n• 录制 1-3 秒人声或上传音频\n• 填写发音参考文本（必须与音频完全一致）\n• 点击「保存并启用」'),
                  _buildStep(3, '重要！配置电池优化和后台保活：\n• 在 CloneTTS 底部「帮助说明」页面查看详细步骤\n• 将 CloneTTS 的电池优化策略改为「无限制」\n• 在多任务界面下拉 CloneTTS 卡片锁定后台'),
                  _buildStep(4, '在 CloneTTS 的「高级设置」中开启「本地 HTTP API 服务」'),
                  _buildStep(5, '在下方配置音色名称（留空使用默认），点击「启用」即可'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GoldCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '常见问题',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFAQ(
                    '朗读时突然停止怎么办？',
                    '这是因为 CloneTTS 被系统杀掉了。请务必按照「使用说明」第 3 步配置电池优化和后台保活。',
                  ),
                  const SizedBox(height: 12),
                  _buildFAQ(
                    '音色名称怎么填？',
                    '在 CloneTTS 的「音色管理」页面，音色卡片上显示的名称就是音色名称。留空会使用 CloneTTS 当前选中的音色。',
                  ),
                  const SizedBox(height: 12),
                  _buildFAQ(
                    'HTTP API 服务地址是什么？',
                    '默认是 http://127.0.0.1:8080，我们已经帮你配置好了，无需手动修改。',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GoldCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '配置',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _voiceController,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      labelText: '音色名称',
                      labelStyle: TextStyle(color: theme.textColor.withOpacity(0.7)),
                      hintText: '留空使用默认音色',
                      hintStyle: TextStyle(color: theme.textColor.withOpacity(0.5)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '语速: ${_speechRate.toStringAsFixed(1)}x',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textColor,
                              ),
                            ),
                            Slider(
                              value: _speechRate,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.primary.withOpacity(0.3),
                              onChanged: (value) {
                                setState(() {
                                  _speechRate = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isEnabled ? _disableConfig : _applyConfig,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEnabled ? Colors.red : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(_isEnabled ? '禁用 CloneTTS' : '启用 CloneTTS'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 16),
            GoldCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CloneTTS 已启用',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '现在可以在阅读界面使用 CloneTTS 朗读了',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    final theme = ref.watch(appThemeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    final theme = ref.watch(appThemeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.question_answer, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            answer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textColor.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _voiceController.dispose();
    super.dispose();
  }
}
