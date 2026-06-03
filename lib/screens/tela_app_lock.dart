import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TelaAppLock extends StatefulWidget {
  final Widget child;

  const TelaAppLock({super.key, required this.child});

  @override
  State<TelaAppLock> createState() => _TelaAppLockState();
}

class _TelaAppLockState extends State<TelaAppLock> with WidgetsBindingObserver {
  bool _isLocked = true; // Começa bloqueado por padrão (abertura do app)
  final LocalAuthentication _localAuth = LocalAuthentication();
  DateTime? _momentoPausa;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autenticar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Marca o tempo exato em que o app foi minimizado
      if (!_isLocked) {
        _momentoPausa = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked) {
        // Se já estava bloqueado (ex: abriu o app agora), pede a senha
        _autenticar();
      } else if (_momentoPausa != null) {
        // Se estava desbloqueado, verifica se passaram 10 minutos
        final diferenca = DateTime.now().difference(_momentoPausa!);
        if (diferenca.inMinutes >= 10) {
          setState(() {
            _isLocked = true;
          });
          _autenticar();
        }
        _momentoPausa = null; // Reseta o cronômetro
      }
    }
  }

  Future<void> _autenticar() async {
    try {
      if (kIsWeb) {
        // Ignora o bloqueio no navegador, pois navegadores não tem leitor de digital configurado
        setState(() => _isLocked = false);
        return;
      }

      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        // Se o dispositivo não suporta biometria ou não tem PIN, libera o acesso
        setState(() => _isLocked = false);
        return;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Desbloqueie para acessar o Guarda Pro',
      );

      if (didAuthenticate) {
        setState(() {
          _isLocked = false;
        });
      }
    } catch (e) {
      debugPrint('Erro na autenticação: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Guarda Pro Bloqueado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Protegendo os dados dos moradores...',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: const Text('Desbloquear Aplicativo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: _autenticar,
            ),
          ],
        ),
      ),
    );
  }
}
