import 'package:flutter/material.dart';
import '../../theme/holotrop_colors.dart';
import '../../widgets/holotrop/terminal_text.dart';

/// Sekce bio-hacku - terminalovy styl s instrukcemi pro harm reduction
class HolotropBiohacksSection extends StatefulWidget {
  final VoidCallback onComplete;

  const HolotropBiohacksSection({
    super.key,
    required this.onComplete,
  });

  @override
  State<HolotropBiohacksSection> createState() =>
      _HolotropBiohacksSectionState();
}

class _HolotropBiohacksSectionState extends State<HolotropBiohacksSection> {
  bool _terminalDone = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HolotropColors.terminalGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: HolotropColors.terminalGreen.withAlpha(60),
                  ),
                ),
                child: const Icon(
                  Icons.terminal,
                  color: HolotropColors.terminalGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BIO-HACK PROTOKOL',
                    style: TextStyle(
                      color: HolotropColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rychle instrukce pro stabilizaci',
                    style: TextStyle(
                      color: HolotropColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Terminal vystup
          TerminalText(
            lines: const [
              TerminalLine(
                prefix: '> SYS_CHECK:',
                text: 'Tep zvysen. Vse je v poradku.',
                color: HolotropColors.accentSoft,
              ),
              TerminalLine(
                prefix: '> SYS_CHECK:',
                text: 'CB1 receptor load: HIGH',
                color: HolotropColors.accentSoft,
              ),
              TerminalLine(
                prefix: '> INIT:',
                text: 'Spoustim harm reduction protokol...',
              ),
              TerminalLine(
                prefix: '\$ ACTION 1:',
                text:
                    'Najdi cerny pepr. Rozkousej 2 kulicky. (Beta-karyofylen potlaci THC)',
              ),
              TerminalLine(
                prefix: '\$ ACTION 2:',
                text:
                    'Pij studenou vodu. Cukr pomuze vyrovnat tlak. (Vagus nerve stim.)',
              ),
              TerminalLine(
                prefix: '\$ ACTION 3:',
                text:
                    'CBD olej pod jazyk - antagonista THC, snizi psychoaktivitu.',
              ),
              TerminalLine(
                prefix: '\$ ACTION 4:',
                text:
                    'Citron - limonenovy terpen snizuje uzkost. Ochutnej kuru.',
              ),
              TerminalLine(
                prefix: '> STATUS:',
                text: 'Bio-hack sekvence dokoncena. Monitoring...',
                color: HolotropColors.accent,
              ),
            ],
            onComplete: () {
              if (mounted) {
                setState(() {
                  _terminalDone = true;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          // Info karta
          _buildInfoCard(
            icon: Icons.science_outlined,
            title: 'Proc to funguje?',
            text:
                'Cerny pepr obsahuje beta-karyofylen, terpen ktery se vaze na CB2 receptory a moduluje ucinky THC. Studena voda stimuluje nervus vagus a snizuje tepovou frekvenci.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.warning_amber_rounded,
            title: 'Synteticke kanabinoidy',
            text:
                'Pozor: HHC-P, THCP a dalsi synteticke latky maji delsi polocas rozpadu. Efekt muze trvat dele. Holotrop mod doporucujeme nechat aktivni aspon 2 hodiny.',
            isWarning: true,
          ),
          const SizedBox(height: 24),
          // Tlacitko dalsi - vzdy viditelne
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onComplete,
                borderRadius: BorderRadius.circular(14),
                splashColor: HolotropColors.accent.withAlpha(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        HolotropColors.accent.withAlpha(_terminalDone ? 35 : 15),
                        HolotropColors.accent.withAlpha(_terminalDone ? 15 : 5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: HolotropColors.accent.withAlpha(_terminalDone ? 140 : 50),
                      width: 1.5,
                    ),
                    boxShadow: _terminalDone
                        ? [
                            BoxShadow(
                              color: HolotropColors.accent.withAlpha(25),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'POKRACOVAT K UZEMNENI',
                        style: TextStyle(
                          color: HolotropColors.accent.withAlpha(_terminalDone ? 255 : 120),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: HolotropColors.accent.withAlpha(_terminalDone ? 255 : 120),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String text,
    bool isWarning = false,
  }) {
    final color = isWarning
        ? const Color(0xFFFFB74D)
        : HolotropColors.accent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: HolotropColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
