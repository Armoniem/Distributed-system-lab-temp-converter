import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/temp_conv_service.dart';

// ── Backend URL ────────────────────────────────────────────────────────────────
// Override this at build time via --dart-define=BACKEND_URL=https://...
const String _backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  runApp(TempConvApp(service: TempConvService(baseUrl: _backendUrl)));
}

// ─────────────────────────────────────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────────────────────────────────────

class TempConvApp extends StatelessWidget {
  final TempConvService service;
  const TempConvApp({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TempConv – Temperature Converter',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: TempConvHomePage(service: service),
    );
  }

  ThemeData _buildTheme() {
    const seedColor = Color(0xFF6C63FF);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Inter',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversion direction
// ─────────────────────────────────────────────────────────────────────────────

enum ConversionDirection { celsiusToFahrenheit, fahrenheitToCelsius }

extension ConversionDirectionX on ConversionDirection {
  String get label =>
      this == ConversionDirection.celsiusToFahrenheit ? '°C → °F' : '°F → °C';

  String get inputUnit =>
      this == ConversionDirection.celsiusToFahrenheit ? '°C' : '°F';

  String get outputUnit =>
      this == ConversionDirection.celsiusToFahrenheit ? '°F' : '°C';

  String get inputHint => this == ConversionDirection.celsiusToFahrenheit
      ? 'Enter temperature in Celsius'
      : 'Enter temperature in Fahrenheit';
}

// ─────────────────────────────────────────────────────────────────────────────
// Home page
// ─────────────────────────────────────────────────────────────────────────────

class TempConvHomePage extends StatefulWidget {
  final TempConvService service;
  const TempConvHomePage({super.key, required this.service});

  @override
  State<TempConvHomePage> createState() => _TempConvHomePageState();
}

class _TempConvHomePageState extends State<TempConvHomePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  ConversionDirection _direction = ConversionDirection.celsiusToFahrenheit;
  ConversionResult? _result;
  bool _loading = false;
  String? _errorMessage;
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Conversion logic ──────────────────────────────────────────────────────

  Future<void> _convert() async {
    if (!_formKey.currentState!.validate()) return;

    final value = double.parse(_inputController.text.trim());
    setState(() {
      _loading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final ConversionResult res;
      if (_direction == ConversionDirection.celsiusToFahrenheit) {
        res = await widget.service.celsiusToFahrenheit(value);
      } else {
        res = await widget.service.fahrenheitToCelsius(value);
      }
      setState(() {
        _result = res;
        _loading = false;
        _requestCount++;
      });
      _pulseCtrl
        ..reset()
        ..forward();
    } on TempConvException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: could not reach the backend.\n$e';
        _loading = false;
      });
    }
  }

  void _swap() {
    setState(() {
      _direction = _direction == ConversionDirection.celsiusToFahrenheit
          ? ConversionDirection.fahrenheitToCelsius
          : ConversionDirection.celsiusToFahrenheit;
      _result = null;
      _errorMessage = null;
    });
  }

  void _copyResult() {
    if (_result == null) return;
    final text = '${_result!.result.toStringAsFixed(4)} ${_result!.unit}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$text" to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                _Header(requestCount: _requestCount),
                const SizedBox(height: 32),

                // ── Card ─────────────────────────────────────────────────────
                _GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Direction toggle
                        _DirectionToggle(
                          direction: _direction,
                          onChanged: (d) => setState(() {
                            _direction = d;
                            _result = null;
                            _errorMessage = null;
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Input field
                        TextFormField(
                          key: const Key('temperature_input'),
                          controller: _inputController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: _direction.inputHint,
                            labelStyle: TextStyle(
                              color: const Color(0xFF6C63FF).withOpacity(0.8),
                            ),
                            suffixText: _direction.inputUnit,
                            suffixStyle: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF6C63FF),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter a temperature value';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _convert(),
                        ),
                        const SizedBox(height: 20),

                        // Swap button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [_SwapButton(onTap: _swap)],
                        ),
                        const SizedBox(height: 20),

                        // Convert button
                        _ConvertButton(
                          loading: _loading,
                          onPressed: _convert,
                          direction: _direction,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Result ──────────────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  child: _result != null
                      ? ScaleTransition(
                          key: ValueKey(_requestCount),
                          scale: _pulseAnim,
                          child: _ResultCard(
                            result: _result!,
                            direction: _direction,
                            onCopy: _copyResult,
                          ),
                        )
                      : _errorMessage != null
                      ? _ErrorCard(message: _errorMessage!)
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),

                // ── Footer ──────────────────────────────────────────────────
                const _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int requestCount;
  const _Header({required this.requestCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glowing icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.thermostat_rounded,
            size: 42,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'TempConv',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Powered by gRPC · Go Backend',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
        if (requestCount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
              ),
            ),
            child: Text(
              '$requestCount conversion${requestCount == 1 ? '' : 's'} done',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DirectionToggle extends StatelessWidget {
  final ConversionDirection direction;
  final ValueChanged<ConversionDirection> onChanged;

  const _DirectionToggle({required this.direction, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ConversionDirection.values.map((d) {
        final selected = d == direction;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(
                right: d == ConversionDirection.celsiusToFahrenheit ? 6 : 0,
                left: d == ConversionDirection.fahrenheitToCelsius ? 6 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9C8EFF)],
                      )
                    : null,
                color: selected ? null : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                d.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SwapButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SwapButton({required this.onTap});

  @override
  State<_SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<_SwapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotAnim = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Swap direction',
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: RotationTransition(
            turns: _rotAnim,
            child: const Icon(
              Icons.swap_vert_rounded,
              color: Color(0xFF6C63FF),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConvertButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final ConversionDirection direction;

  const _ConvertButton({
    required this.loading,
    required this.onPressed,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          key: const Key('convert_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: loading ? null : onPressed,
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Convert ${direction.label}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ConversionResult result;
  final ConversionDirection direction;
  final VoidCallback onCopy;

  const _ResultCard({
    required this.result,
    required this.direction,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.15),
            const Color(0xFFFF6584).withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Result',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              IconButton(
                key: const Key('copy_result_button'),
                icon: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
                tooltip: 'Copy result',
                onPressed: onCopy,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.result.toStringAsFixed(4),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '°${result.unit[0]}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              result.formula,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFF4444).withOpacity(0.1),
        border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF6666),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Text(
      'TempConv · gRPC + Go + Flutter Web · GKE Deployment',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.25)),
    );
  }
}
