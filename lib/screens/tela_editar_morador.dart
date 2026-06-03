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

class TelaEditarMorador extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> dadosIniciais;

  const TelaEditarMorador({
    super.key,
    required this.docId,
    required this.dadosIniciais,
  });

  @override
  State<TelaEditarMorador> createState() => _TelaEditarMoradorState();
}

class _TelaEditarMoradorState extends State<TelaEditarMorador> {
  String _opcaoDia = '5';
  bool _carregandoRuas = true;
  List<String> _ruasCadastradas = [];
  String? _ruaSelecionada;
  String _tipoViaSelecionada = 'Rua';
  late TextEditingController _controleNome;
  late TextEditingController _controleRua;
  late TextEditingController _controleCasa;
  late TextEditingController _controleValor;
  late TextEditingController _controleDia;
  late TextEditingController _controleTelefone;

  @override
  void initState() {
    super.initState();
    _controleNome = TextEditingController(text: widget.dadosIniciais['nome']);
    _controleRua = TextEditingController(
      text: widget.dadosIniciais['endereco_rua'],
    );
    _controleCasa = TextEditingController(
      text: widget.dadosIniciais['endereco_numero']?.toString(),
    );
    _controleValor = TextEditingController(
      text: widget.dadosIniciais['valor_mensalidade']?.toString(),
    );
    _controleDia = TextEditingController(
      text: widget.dadosIniciais['dia_vencimento']?.toString(),
    );
    _controleTelefone = TextEditingController(
      text: widget.dadosIniciais['telefone']?.toString(),
    );

    final diaInicial = widget.dadosIniciais['dia_vencimento']?.toString() ?? '5';
    if (['5', '10', '15', '20', '25'].contains(diaInicial)) {
      _opcaoDia = diaInicial;
    } else {
      _opcaoDia = 'Outro';
    }

    _carregarRuas();
  }

  Future<void> _carregarRuas() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('moradores')
          .where('guarda_id', isEqualTo: uid)
          .get();

      Set<String> ruasUnicas = {};
      for (var doc in snapshot.docs) {
        final rua = (doc.data()['endereco_rua'] ?? '').toString().trim();
        if (rua.isNotEmpty) ruasUnicas.add(_formatarNomeRua(rua));
      }

      final listaRuas = ruasUnicas.toList()..sort();
      listaRuas.add('Nova Rua...');

      final ruaAtual = _formatarNomeRua(widget.dadosIniciais['endereco_rua'] ?? '');
      
      setState(() {
        _ruasCadastradas = listaRuas;
        if (ruaAtual.isNotEmpty && _ruasCadastradas.contains(ruaAtual)) {
          _ruaSelecionada = ruaAtual;
          _controleRua.text = ruaAtual;
        } else {
          _ruaSelecionada = 'Nova Rua...';
          _controleRua.text = ruaAtual;
        }
        _carregandoRuas = false;
      });
    } catch (e) {
      setState(() => _carregandoRuas = false);
    }
  }

  String _formatarNome(String nome) {
    if (nome.trim().isEmpty) return '';
    final palavrasRestritas = ['de', 'da', 'do', 'das', 'dos', 'e'];
    return nome
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((palavra) {
          final pLow = palavra.toLowerCase();
          if (palavrasRestritas.contains(pLow)) return pLow;
          return pLow[0].toUpperCase() + pLow.substring(1);
        })
        .join(' ');
  }

  String _formatarNomeRua(String rua) {
    if (rua.trim().isEmpty) return '';

    String ruaLimpa = rua.trim();
    final lower = ruaLimpa.toLowerCase();
    if (lower.startsWith('rua ')) ruaLimpa = ruaLimpa.substring(4);
    else if (lower.startsWith('av ')) ruaLimpa = ruaLimpa.substring(3);
    else if (lower.startsWith('av. ')) ruaLimpa = ruaLimpa.substring(4);
    else if (lower.startsWith('avenida ')) ruaLimpa = ruaLimpa.substring(8);
    else if (lower.startsWith('travessa ')) ruaLimpa = ruaLimpa.substring(9);

    final palavrasRestritas = ['de', 'da', 'do', 'das', 'dos'];
    return ruaLimpa
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((palavra) {
          final pLow = palavra.toLowerCase();
          if (palavrasRestritas.contains(pLow)) return pLow;
          return pLow[0].toUpperCase() + pLow.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Morador')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          children: [
            const Icon(Icons.manage_accounts, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            TextField(
              controller: _controleNome,
              decoration: const InputDecoration(
                labelText: 'Nome do Morador',
                // borda global
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            if (_carregandoRuas)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                value: _ruaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Selecione a Rua',
                  // borda global
                  prefixIcon: Icon(Icons.signpost),
                ),
                hint: const Text('Escolha uma rua ou Nova Rua...'),
                items: _ruasCadastradas.map((String rua) {
                  return DropdownMenuItem<String>(
                    value: rua,
                    child: Text(rua),
                  );
                }).toList(),
                onChanged: (novoValor) {
                  setState(() {
                    _ruaSelecionada = novoValor;
                    if (novoValor != 'Nova Rua...') {
                      _controleRua.text = novoValor ?? '';
                    } else {
                      _controleRua.clear();
                    }
                  });
                },
              ),
            if (_ruaSelecionada == 'Nova Rua...') ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _tipoViaSelecionada,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: ['Rua', 'Av', 'Travessa']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _tipoViaSelecionada = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _controleRua,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Via',
                        prefixIcon: Icon(Icons.edit_road),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _controleCasa,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número da Casa',
                // borda global
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleTelefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp (Ex: 16999999999)',
                // borda global
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleValor,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor da Mensalidade (Ex: 50,00)',
                // borda global
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _opcaoDia,
              decoration: const InputDecoration(
                labelText: 'Dia do Pagamento',
                // borda global
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: ['5', '10', '15', '20', '25', 'Outro'].map((String valor) {
                return DropdownMenuItem<String>(
                  value: valor,
                  child: Text(valor == 'Outro' ? 'Outro dia...' : 'Dia $valor'),
                );
              }).toList(),
              onChanged: (novoValor) {
                if (novoValor != null) {
                  setState(() {
                    _opcaoDia = novoValor;
                    if (novoValor != 'Outro') {
                      _controleDia.text = novoValor;
                    } else {
                      _controleDia.clear();
                    }
                  });
                }
              },
            ),
            if (_opcaoDia == 'Outro') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _controleDia,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Digite o dia (Ex: 8)',
                  // borda global
                  prefixIcon: Icon(Icons.edit_calendar),
                ),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                if (_controleNome.text.isEmpty ||
                    _controleCasa.text.isEmpty ||
                    _controleValor.text.isEmpty ||
                    _controleDia.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha os campos obrigatórios!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final telefoneLimpo = _controleTelefone.text.replaceAll(RegExp(r'[^0-9]'), '');
                if (telefoneLimpo.isNotEmpty && telefoneLimpo.length != 11) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('O telefone deve ter exatamente 11 números (DDD + 9 dígitos).'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                String ruaFinal = _controleRua.text;
                if (_ruaSelecionada == 'Nova Rua...') {
                  ruaFinal = '$_tipoViaSelecionada ${_formatarNomeRua(_controleRua.text)}'.trim();
                }

                await FirebaseFirestore.instance
                    .collection('moradores')
                    .doc(widget.docId)
                    .update({
                      'nome': _formatarNome(_controleNome.text),
                      'endereco_rua': ruaFinal,
                      'endereco_numero': _controleCasa.text.trim(),
                      'telefone': telefoneLimpo,
                      'valor_mensalidade': _controleValor.text,
                      'dia_vencimento': int.tryParse(_controleDia.text) ?? 1,
                    });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Morador atualizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'SALVAR ALTERAÇÕES',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// --- TELA 7: HISTÓRICO COM BOTÃO DO WHATSAPP DIRETO ---
