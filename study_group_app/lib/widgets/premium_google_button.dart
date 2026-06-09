import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PremiumGoogleButton
/// A modern, reusable Google sign-in button with glassmorphism, hover glow,
/// press scale, loading state and dark-mode support. Designed to be
/// production-ready and easy to integrate.
class PremiumGoogleButton extends StatefulWidget {
  const PremiumGoogleButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Google',
    this.height = 60,
    this.radius = 22,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final String label;
  final double height;
  final double radius;

  @override
  State<PremiumGoogleButton> createState() => _PremiumGoogleButtonState();
}

class _PremiumGoogleButtonState extends State<PremiumGoogleButton> {
  bool _hovering = false;
  bool _pressed = false;

  void _onHover(bool hover) {
    setState(() => _hovering = hover);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.colorScheme.brightness == Brightness.dark;

    const Color glowA = Color(0xFF6C63FF);
    const Color glowB = Color(0xFFFF6584);

    final bgColor = isDark ? Colors.white.withOpacity(0.04) : Colors.white;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.height),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glass background + blur
                ClipRRect(
                  borderRadius: BorderRadius.circular(widget.radius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _hovering ? 6.0 : 4.0,
                      sigmaY: _hovering ? 6.0 : 4.0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(widget.radius),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.45 : 0.08,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google logo container
                          Container(
                            width: widget.height - 20,
                            height: widget.height - 20,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.grey.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  'assets/google_icon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.g_mobiledata_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),

                          // Label / loading
                          Expanded(
                            child: widget.isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                glowA,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Signing in...',
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    widget.label,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                          ),

                          // spacer to balance logo
                          SizedBox(width: widget.height - 20),
                        ],
                      ),
                    ),
                  ),
                ),

                // Hover glow (subtle)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _hovering ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.radius),
                          gradient: LinearGradient(
                            colors: [
                              glowA.withOpacity(0.14),
                              glowB.withOpacity(0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: glowA.withOpacity(0.12),
                              blurRadius: 20,
                              spreadRadius: 1.2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
