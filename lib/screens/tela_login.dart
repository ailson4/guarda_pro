import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'tela_login.dart';
import 'painel_do_dia.dart';
import 'tela_cobranca.dart';
import 'tela_novo_morador.dart';
import 'tela_gestao_moradores.dart';
import 'tela_editar_morador.dart';
import 'tela_historico.dart';
import 'tela_perfil.dart';
import 'tela_cobranca_online.dart';
import '../widgets/indicador_progresso_mes.dart';
import '../widgets/cartao_resumo.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;

  Future<void> _fazerLogin() async {
    setState(() => _carregando = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      // Se der certo, o StreamBuilder no topo do app muda de tela automaticamente!
    } on FirebaseAuthException catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('E-mail ou senha incorretos.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- NOVA FUNÇÃO: RECUPERAR SENHA ---
  void _mostrarJanelaRecuperacaoSenha() {
    final TextEditingController resetEmailController = TextEditingController(
      text: _emailController.text,
    );

    showDialog(
      context: context,
      builder: (contextDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.blueAccent, size: 28),
              SizedBox(width: 10),
              Text(
                'Recuperar Senha',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Digite seu e-mail abaixo. Enviaremos um link seguro para você criar uma nova senha.',
                style: TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail cadastrado',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialog),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, digite um e-mail válido.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(contextDialog); // Fecha a janela

                try {
                  // O GATILHO MÁGICO DO FIREBASE
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'E-mail de recuperação enviado! Verifique sua caixa de entrada.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 5),
                    ),
                  );
                } catch (erro) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro: $erro'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Enviar Link',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco puro para fundir com a imagem
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_login.png',
                      height: 320, // Tamanho ainda maior!
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 42, // Aumentado
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                        ),
                        children: [
                          TextSpan(
                            text: 'GUARDA ',
                            style: TextStyle(color: Color(0xFF1E293B)),
                          ),
                          TextSpan(
                            text: 'PRO',
                            style: TextStyle(color: Color(0xFFD4AF37)), // Dourado premium
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 8),

              // BOTÃO DE ESQUECI A SENHA
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _mostrarJanelaRecuperacaoSenha,
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56), // Altura dinâmica que não corta o texto
                ),
                onPressed: _carregando ? null : _fazerLogin,
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENTRAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

