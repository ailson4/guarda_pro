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
import '../utils/gerador_recibo.dart';

class TelaHistorico extends StatelessWidget {
  const TelaHistorico({super.key});

  // Função auxiliar para converter o texto do dinheiro em número
  double _converterParaNumero(String valorStr) {
    String limpo = valorStr.replaceAll('R\$', '').trim();
    if (limpo.contains(',') && limpo.contains('.')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    } else if (limpo.contains(',')) {
      limpo = limpo.replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0.0;
  }

  String _obterSiglaMes(String numero) {
    switch (numero) {
      case '01':
        return 'JAN';
      case '02':
        return 'FEV';
      case '03':
        return 'MAR';
      case '04':
        return 'ABR';
      case '05':
        return 'MAI';
      case '06':
        return 'JUN';
      case '07':
        return 'JUL';
      case '08':
        return 'AGO';
      case '09':
        return 'SET';
      case '10':
        return 'OUT';
      case '11':
        return 'NOV';
      case '12':
        return 'DEZ';
      default:
        return '---';
    }
  }

  String _obterNomeMes(String numero) {
    switch (numero) {
      case '01':
        return 'Janeiro';
      case '02':
        return 'Fevereiro';
      case '03':
        return 'Março';
      case '04':
        return 'Abril';
      case '05':
        return 'Maio';
      case '06':
        return 'Junho';
      case '07':
        return 'Julho';
      case '08':
        return 'Agosto';
      case '09':
        return 'Setembro';
      case '10':
        return 'Outubro';
      case '11':
        return 'Novembro';
      case '12':
        return 'Dezembro';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final formatadorMoeda = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    // Formatador para os números laterais do gráfico (ex: 1.000)
    final formatadorMilhar = NumberFormat.decimalPattern('pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pagamentos')
            .where('guarda_id', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshotPagamentos) {
          if (snapshotPagamentos.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshotPagamentos.hasData ||
              snapshotPagamentos.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum pagamento registrado ainda.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // 1. Agrupa os recibos
          final recibos = snapshotPagamentos.data!.docs.toList();
          Map<String, List<DocumentSnapshot>> pagamentosPorMes = {};

          for (var doc in recibos) {
            final dados = doc.data() as Map<String, dynamic>;
            String mesRef = dados['mes_referencia']?.toString() ?? '';

            if (mesRef.isEmpty) {
              final ts = dados['data_pagamento'] as Timestamp?;
              if (ts != null) {
                final dt = ts.toDate();
                mesRef = "${dt.month.toString().padLeft(2, '0')}/${dt.year}";
              } else {
                mesRef = "Desconhecido";
              }
            }
            if (!pagamentosPorMes.containsKey(mesRef))
              pagamentosPorMes[mesRef] = [];
            pagamentosPorMes[mesRef]!.add(doc);
          }

          // 2. Ordena os meses (mais novo no topo da lista)
          List<String> mesesOrdenados = pagamentosPorMes.keys.toList();
          mesesOrdenados.sort((a, b) {
            try {
              final partsA = a.split('/');
              final partsB = b.split('/');
              final dtA = DateTime(int.parse(partsA[1]), int.parse(partsA[0]));
              final dtB = DateTime(int.parse(partsB[1]), int.parse(partsB[0]));
              return dtB.compareTo(dtA);
            } catch (e) {
              return 0;
            }
          });

          // Limita a 12 meses
          if (mesesOrdenados.length > 12)
            mesesOrdenados = mesesOrdenados.sublist(0, 12);

          // --- 3. PREPARAÇÃO DO GRÁFICO ---
          List<String> mesesGrafico = mesesOrdenados
              .take(12)
              .toList()
              .reversed
              .toList();
          List<BarChartGroupData> barGroups = [];
          List<String> labelsGrafico = [];
          double maxRecebido = 0;

          for (int i = 0; i < mesesGrafico.length; i++) {
            String mesAno = mesesGrafico[i];
            double totalMes = 0;
            for (var rec in pagamentosPorMes[mesAno]!) {
              final dadosRec = rec.data() as Map<String, dynamic>;
              totalMes += _converterParaNumero(
                dadosRec['valor']?.toString() ?? '0',
              );
            }

            if (totalMes > maxRecebido) maxRecebido = totalMes;
            String sigla = _obterSiglaMes(
              mesAno.contains('/') ? mesAno.split('/')[0] : '00',
            );
            labelsGrafico.add(sigla);

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: totalMes,
                    color: Colors.green.shade500,
                    width: 14,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxRecebido <= 5000
                          ? 5000
                          : maxRecebido * 1.2, // Teto inteligente adaptável
                      color: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
            );
          }

          // 4. CONSTRUÇÃO DA TELA
          return Column(
            children: [
              // --- O GRÁFICO DE BARRAS ---
              Container(
                height: 240,
                padding: const EdgeInsets.only(
                  top: 24,
                  right: 24,
                  left: 12,
                  bottom: 10,
                ),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12.0, bottom: 20.0),
                      child: Text(
                        'Evolução Anual de Recebimentos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxRecebido <= 5000
                              ? 5000
                              : maxRecebido *
                                    1.2, // O gráfico vai pelo menos até 5000
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      formatadorMoeda.format(rod.toY),
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                      if (value >= 0 &&
                                          value < labelsGrafico.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            labelsGrafico[value.toInt()],
                                            style: const TextStyle(
                                              color: Colors.blueGrey,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1000, // <--- O PULO DE 1.000 EM 1.000
                                reservedSize:
                                    42, // <--- Espaço ajustado para caber "5.000"
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('');
                                  return Text(
                                    formatadorMilhar.format(
                                      value,
                                    ), // Formata para 1.000, 2.000...
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                1000, // <--- Linhas pontilhadas também a cada 1.000
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: barGroups,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- A LISTA DE SANFONAS MENSAL ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mesesOrdenados.length,
                  itemBuilder: (context, index) {
                    final mesAno = mesesOrdenados[index];
                    final recibosDoMes = pagamentosPorMes[mesAno]!;

                    double totalRecebidoMes = 0;
                    for (var rec in recibosDoMes) {
                      final dadosRec = rec.data() as Map<String, dynamic>;
                      totalRecebidoMes += _converterParaNumero(
                        dadosRec['valor']?.toString() ?? '0',
                      );
                    }

                    String numeroMes = mesAno.contains('/')
                        ? mesAno.split('/')[0]
                        : '00';
                    String ano = mesAno.contains('/')
                        ? mesAno.split('/')[1]
                        : '';
                    String siglaMes = _obterSiglaMes(numeroMes);
                    String nomeMes = _obterNomeMes(numeroMes);
                    Color corPadrao = Colors.blueGrey;

                    List<Widget> cartoesRecibos = recibosDoMes.map((docRecibo) {
                      final dados = docRecibo.data() as Map<String, dynamic>;
                      final docId = docRecibo.id;
                      final timestamp = dados['data_pagamento'] as Timestamp?;
                      final data = timestamp?.toDate() ?? DateTime.now();
                      final dataFormatada = DateFormat(
                        "dd/MM/yyyy 'às' HH:mm",
                      ).format(data);
                      final bool reciboEnviado =
                          dados['recibo_enviado'] ?? false;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.green,
                                radius: 16,
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dados['morador'] ?? 'Sem Nome',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Casa ${dados['casa']} - $dataFormatada',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatadorMoeda.format(
                                      _converterParaNumero(
                                        dados['valor']?.toString() ?? '0',
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (reciboEnviado)
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.done_all,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Enviado',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      icon: const Icon(Icons.send, size: 14),
                                      label: const Text(
                                        'Recibo',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        final mensagem =
                                            "Olá ${dados['morador']}! Confirmamos o recebimento da mensalidade da Casa ${dados['casa']} no valor de R\$ ${dados['valor']}. Data: $dataFormatada. Obrigado!";
                                        final telefoneBruto =
                                            dados['telefone']?.toString() ?? '';
                                        final telefoneLimpo = telefoneBruto
                                            .replaceAll(RegExp(r'[^0-9]'), '');

                                        showDialog(
                                          context: context,
                                          builder: (contextDialog) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: const Text(
                                                'Enviar Recibo',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: const Text(
                                                'Escolha como deseja enviar o comprovante:',
                                                textAlign: TextAlign.center,
                                              ),
                                              actionsAlignment:
                                                  MainAxisAlignment.center,
                                              actionsOverflowDirection:
                                                  VerticalDirection.down,
                                              actions: [
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red.shade600,
                                                  ),
                                                  icon: const Icon(Icons.picture_as_pdf),
                                                  label: const Text('Gerar e Compartilhar Recibo (PDF)'),
                                                  onPressed: () async {
                                                    await FirebaseFirestore.instance
                                                        .collection('pagamentos')
                                                        .doc(docId)
                                                        .update({'recibo_enviado': true});
                                                    
                                                    if (context.mounted) Navigator.pop(contextDialog);
                                                    
                                                    final dataPagamentoTs = dados['data_pagamento'] as Timestamp?;
                                                    final dataPag = dataPagamentoTs?.toDate() ?? DateTime.now();

                                                    await GeradorRecibo.gerarECompartilhar(
                                                      nomeMorador: dados['morador'] ?? 'Sem Nome',
                                                      rua: dados['endereco_rua'] ?? 'Não informada',
                                                      numeroCasa: dados['casa']?.toString() ?? 'S/N',
                                                      valor: dados['valor']?.toString() ?? '0,00',
                                                      mesReferencia: dados['mes_referencia'] ?? '',
                                                      dataPagamento: dataPag,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blueAccent,
                                                  ),
                                                  icon: const Icon(Icons.sms),
                                                  label: const Text(
                                                    'Enviar via SMS',
                                                  ),
                                                  onPressed: () async {
                                                    String urlStr =
                                                        telefoneLimpo.isNotEmpty
                                                        ? "sms:$telefoneLimpo?body=${Uri.encodeComponent(mensagem)}"
                                                        : "sms:?body=${Uri.encodeComponent(mensagem)}";
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                          'pagamentos',
                                                        )
                                                        .doc(docId)
                                                        .update({
                                                          'recibo_enviado':
                                                              true,
                                                        });
                                                    if (context.mounted)
                                                      Navigator.pop(
                                                        contextDialog,
                                                      );
                                                    await launchUrl(
                                                      Uri.parse(urlStr),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.grey.shade700,
                                                    minimumSize: const Size(
                                                      double.infinity,
                                                      45,
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        contextDialog,
                                                      ),
                                                  child: const Text('Cancelar'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: corPadrao.withAlpha(20),
                            radius: 28,
                            child: Text(
                              siglaMes,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: corPadrao,
                              ),
                            ),
                          ),
                          title: Text(
                            '$nomeMes $ano',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Text(
                                  'Recebido: ',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  formatadorMoeda.format(totalRecebidoMes),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          iconColor: corPadrao,
                          collapsedIconColor: Colors.grey.shade400,
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          children: cartoesRecibos,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- O GUARDA DE TRÂNSITO (VERIFICADOR DE ASSINATURA) ---
