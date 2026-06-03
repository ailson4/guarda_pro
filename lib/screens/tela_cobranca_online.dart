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

class TelaCobrancaOnline extends StatefulWidget {
  const TelaCobrancaOnline({super.key});

  @override
  State<TelaCobrancaOnline> createState() => _TelaCobrancaOnlineState();
}

class _TelaCobrancaOnlineState extends State<TelaCobrancaOnline> {
  String _chavePix = '';
  String _nomeGuarda = '';
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('perfil_guarda')
          .doc(uid)
          .get();

      if (doc.exists) {
        final dados = doc.data()!;
        setState(() {
          _nomeGuarda = dados['nome'] ?? 'Guarda';
          _chavePix = dados['chave_pix'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar PIX: $e');
    }
    setState(() => _carregandoPerfil = false);
  }

  // Envia a mensagem com texto dinâmico e salva no banco que foi cobrado
  Future<void> _cobrarViaWhatsApp(
    String docId,
    Map<String, dynamic> morador,
    String mesAtualNome,
    String mesRef,
    String tipoDaCobranca,
  ) async {
    if (_chavePix.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Atenção: Configure sua Chave PIX em "Configurações" primeiro!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final telefoneBruto = morador['telefone']?.toString() ?? '';
    final telefoneLimpo = telefoneBruto.replaceAll(RegExp(r'[^0-9]'), '');

    if (telefoneLimpo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este morador não tem telefone cadastrado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nome = morador['nome'] ?? 'Sem Nome';
    final numeroCasa = morador['endereco_numero']?.toString() ?? 'S/N';
    final valor = morador['valor_mensalidade']?.toString() ?? '0,00';
    final diaVencimento = morador['dia_vencimento']?.toString() ?? '--';

    // TEXTOS DINÂMICOS BASEADOS NO STATUS E USANDO O NOME DO GUARDA
    String mensagem = "";

    if (tipoDaCobranca == 'atrasado') {
      mensagem =
          "Olá $nome! Tudo bem? Aqui é o $_nomeGuarda da ronda noturna.\n\nVerifiquei aqui que a mensalidade da Casa $numeroCasa referente a $mesAtualNome acabou passando do vencimento (dia $diaVencimento). O valor é R\$ $valor.\n\nPara facilitar, você pode realizar o pagamento direto na minha chave PIX:\n$_chavePix\n\nAssim que fizer, por favor me envie o comprovante. Qualquer dúvida, estou à disposição!";
    } else if (tipoDaCobranca == 'hoje') {
      mensagem =
          "Olá $nome! Tudo bem? Aqui é o $_nomeGuarda da ronda noturna.\n\nPassando apenas para lembrar que a mensalidade da Casa $numeroCasa de $mesAtualNome vence *hoje*! O valor é R\$ $valor.\n\nSegue a minha chave PIX para o pagamento:\n$_chavePix\n\nAssim que transferir, é só mandar o comprovante aqui. Muito obrigado!";
    } else {
      // proximos
      mensagem =
          "Olá $nome! Tudo bem? Aqui é o $_nomeGuarda da ronda noturna.\n\nEnviando antecipadamente a mensalidade da Casa $numeroCasa de $mesAtualNome. O vencimento é dia $diaVencimento e o valor é R\$ $valor.\n\nMinha chave PIX:\n$_chavePix\n\nObrigado pela parceria de sempre!";
    }

    final urlStr =
        "https://wa.me/55$telefoneLimpo?text=${Uri.encodeComponent(mensagem)}";

    try {
      // 1. Abre o WhatsApp
      await launchUrl(Uri.parse(urlStr), mode: LaunchMode.externalApplication);

      // 2. Grava no cadastro do morador que ele já foi cobrado neste mês
      await FirebaseFirestore.instance
          .collection('moradores')
          .doc(docId)
          .update({'ultimo_mes_cobrado': mesRef});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarPagamentoPix(String docId, Map<String, dynamic> morador, String mesRef) async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final nome = morador['nome'] ?? 'Sem Nome';
      final numeroCasa = morador['endereco_numero']?.toString() ?? 'S/N';
      final valor = morador['valor_mensalidade']?.toString() ?? '0,00';
      final telefone = morador['telefone']?.toString() ?? '';

      await FirebaseFirestore.instance.collection('pagamentos').add({
        'casa': numeroCasa,
        'morador': nome,
        'valor': valor,
        'data_pagamento': DateTime.now(),
        'status': 'pago',
        'mes_referencia': mesRef,
        'telefone': telefone,
        'guarda_id': uid,
        'recibo_enviado': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento PIX confirmado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao confirmar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Constrói a Sanfona Inteligente
  Widget _construirSanfona(
    List<QueryDocumentSnapshot> moradores,
    String titulo,
    Color corDestaque,
    IconData icone,
    String mesAtualNome,
    String mesRef,
    String tipoDaCobranca,
    bool expandidoPadrao,
  ) {
    if (moradores.isEmpty) return const SizedBox.shrink();

    List<Widget> cartoes = moradores.map((doc) {
      final dados = doc.data() as Map<String, dynamic>;
      final docId = doc.id;

      final nome = dados['nome'] ?? 'Sem Nome';
      final numeroCasa = dados['endereco_numero']?.toString() ?? 'S/N';
      final valor = dados['valor_mensalidade']?.toString() ?? '0,00';
      final diaVencimento = dados['dia_vencimento']?.toString() ?? '--';

      // Verifica se a etiqueta do mês atual está lá
      final bool jaCobradoNesteMes = dados['ultimo_mes_cobrado'] == mesRef;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: corDestaque.withAlpha(20),
                    radius: 20,
                    child: Icon(Icons.home, color: corDestaque, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Casa $numeroCasa • Vence dia $diaVencimento',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          'Valor: R\$ $valor',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),

                        // Aviso visual se a mensagem já foi enviada
                        if (jaCobradoNesteMes)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.done_all,
                                  color: Colors.green.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cobrança enviada',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jaCobradoNesteMes
                          ? Colors.blueGrey.shade100
                          : Colors.green, // Muda a cor se já cobrou
                      foregroundColor: jaCobradoNesteMes
                          ? Colors.blueGrey.shade800
                          : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: Icon(
                      jaCobradoNesteMes ? Icons.replay : Icons.pix,
                      size: 16,
                    ),
                    label: Text(jaCobradoNesteMes ? 'Reenviar' : 'Cobrar'),
                    onPressed: () => _cobrarViaWhatsApp(
                      docId,
                      dados,
                      mesAtualNome,
                      mesRef,
                      tipoDaCobranca,
                    ),
                  ),
                  if (jaCobradoNesteMes) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Confirmar PIX'),
                      onPressed: () => _confirmarPagamentoPix(docId, dados, mesRef),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expandidoPadrao,
          leading: Icon(icone, color: corDestaque, size: 28),
          title: Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
          subtitle: Text(
            '${moradores.length} casa(s)',
            style: TextStyle(color: corDestaque, fontWeight: FontWeight.bold),
          ),
          iconColor: corDestaque,
          collapsedIconColor: Colors.grey,
          childrenPadding: const EdgeInsets.only(bottom: 12.0),
          children: cartoes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final dataAtual = DateTime.now();
    final diaDeHoje = dataAtual.day;
    final mesRef =
        "${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}";

    const mesesNomes = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro",
    ];
    final mesAtualNome = mesesNomes[dataAtual.month - 1];

    if (_carregandoPerfil) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Central PIX'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('moradores')
            .where('guarda_id', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshotMoradores) {
          if (snapshotMoradores.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshotMoradores.hasData ||
              snapshotMoradores.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum morador cadastrado.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final todosMoradores = snapshotMoradores.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('pagamentos')
                .where('guarda_id', isEqualTo: uid)
                .where('mes_referencia', isEqualTo: mesRef)
                .snapshots(),
            builder: (context, snapshotPagamentos) {
              if (snapshotPagamentos.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());

              final pagamentosDoMes = snapshotPagamentos.data?.docs ?? [];
              final casasPagas = pagamentosDoMes
                  .map(
                    (doc) =>
                        (doc.data() as Map<String, dynamic>)['casa'].toString(),
                  )
                  .toSet();

              List<QueryDocumentSnapshot> atrasados = [];
              List<QueryDocumentSnapshot> venceHoje = [];
              List<QueryDocumentSnapshot> proximosDias = [];

              for (var moradorDoc in todosMoradores) {
                final dados = moradorDoc.data() as Map<String, dynamic>;
                final numeroCasa = dados['endereco_numero']?.toString() ?? '';

                if (casasPagas.contains(numeroCasa)) continue;

                int diaVencimento =
                    int.tryParse(dados['dia_vencimento']?.toString() ?? '0') ??
                    0;

                if (diaVencimento < diaDeHoje) {
                  atrasados.add(moradorDoc);
                } else if (diaVencimento == diaDeHoje) {
                  venceHoje.add(moradorDoc);
                } else {
                  proximosDias.add(moradorDoc);
                }
              }

              if (atrasados.isEmpty &&
                  venceHoje.isEmpty &&
                  proximosDias.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Parabéns!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Todos os moradores já pagaram a\nmensalidade deste mês.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blueGrey,
                    child: Column(
                      children: [
                        Text(
                          'Pendências de $mesAtualNome',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sua Chave PIX: $_chavePix',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sanfona 1: Atrasados (Abre automaticamente se tiver gente)
                  _construirSanfona(
                    atrasados,
                    'Em Atraso',
                    Colors.red,
                    Icons.warning_rounded,
                    mesAtualNome,
                    mesRef,
                    'atrasado',
                    false,
                  ),

                  // Sanfona 2: Vence Hoje (Abre automaticamente se a primeira estiver vazia)
                  _construirSanfona(
                    venceHoje,
                    'Vence Hoje',
                    Colors.orange,
                    Icons.notification_important,
                    mesAtualNome,
                    mesRef,
                    'hoje',
                    false,
                  ),

                  // Sanfona 3: Próximos (Fica fechada por padrão)
                  _construirSanfona(
                    proximosDias,
                    'Próximos Vencimentos',
                    Colors.blue,
                    Icons.calendar_month,
                    mesAtualNome,
                    mesRef,
                    'proximo',
                    false,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
