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

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final _nomeController = TextEditingController();
  final _chavePixController = TextEditingController();
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  // 1. Busca os dados no Firebase quando a tela abre
  Future<void> _carregarPerfil() async {
    setState(() => _carregando = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('perfil_guarda')
          .doc(uid)
          .get();

      if (doc.exists) {
        final dados = doc.data()!;
        _nomeController.text = dados['nome'] ?? '';
        _chavePixController.text = dados['chave_pix'] ?? '';
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    }
    setState(() => _carregando = false);
  }

  // 2. Salva os dados no Firebase quando o guarda aperta o botão
  Future<void> _salvarPerfil() async {
    if (_nomeController.text.isEmpty || _chavePixController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _carregando = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // O SetOptions(merge: true) atualiza apenas o que mudou, sem apagar outros dados
      await FirebaseFirestore.instance
          .collection('perfil_guarda')
          .doc(uid)
          .set({
            'nome': _nomeController.text.trim(),
            'chave_pix': _chavePixController.text.trim(),
            'atualizado_em': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chave PIX salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Fecha a tela de configurações e volta pro app
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _carregando = false);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _chavePixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Recebimento'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Meus Dados Financeiros',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A sua chave PIX será enviada automaticamente nas mensagens de cobrança pelo WhatsApp para os moradores.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // Campo NOME
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Seu Nome (Ex: Guarda João)',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo CHAVE PIX
                  TextField(
                    controller: _chavePixController,
                    decoration: const InputDecoration(
                      labelText: 'Sua Chave PIX (Celular, CPF, E-mail...)',
                      prefixIcon: Icon(Icons.pix, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botão SALVAR
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: _salvarPerfil,
                    child: const Text(
                      'SALVAR DADOS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

//--Tela cobrança online--//

