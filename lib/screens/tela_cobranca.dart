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

class TelaCobranca extends StatelessWidget {
  final String nomeMorador;
  final String rua;
  final String numeroCasa;
  final String valorCobranca;
  final String telefoneMorador;

  const TelaCobranca({
    super.key,
    required this.nomeMorador,
    required this.rua,
    required this.numeroCasa,
    required this.valorCobranca,
    required this.telefoneMorador,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receber Pagamento')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.receipt_long, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            Text(
              nomeMorador,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Casa $numeroCasa',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            const Text(
              'Valor da Mensalidade:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'R\$ $valorCobranca',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () async {
                try {
                  final dataAtual = DateTime.now();
                  final mesReferencia =
                      "${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}";
                  final String uid = FirebaseAuth.instance.currentUser!.uid;

                  // 1. Salva no banco de dados e GUARDA A REFERÊNCIA DO DOCUMENTO
                  final docRef = await FirebaseFirestore.instance
                      .collection('pagamentos')
                      .add({
                        'casa': numeroCasa,
                        'morador': nomeMorador,
                        'valor': valorCobranca,
                        'data_pagamento': dataAtual,
                        'status': 'pago',
                        'mes_referencia': mesReferencia,
                        'telefone': telefoneMorador,
                        'guarda_id': uid,
                        'recibo_enviado':
                            false, // Começa como falso por padrão!
                      });

                  if (!context.mounted) return;

                  // 2. Prepara a mensagem do recibo e limpa o telefone
                  final dataFormatada =
                      "${dataAtual.day.toString().padLeft(2, '0')}/${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year} às ${dataAtual.hour.toString().padLeft(2, '0')}:${dataAtual.minute.toString().padLeft(2, '0')}";
                  final mensagem =
                      "Olá $nomeMorador! Confirmamos o recebimento da mensalidade da Casa $numeroCasa no valor de R\$ $valorCobranca. Data: $dataFormatada. Obrigado!";
                  final telefoneLimpo = telefoneMorador.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );

                  // 3. Mostra a Janela (Dialog) com as 3 opções!
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (contextDialog) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 60,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Pagamento Salvo!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        content: const Text(
                          'Deseja enviar o comprovante para o morador agora?',
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actionsOverflowDirection: VerticalDirection.down,
                        actions: [
                          // Botão de Gerar Recibo PDF
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Gerar e Compartilhar Recibo (PDF)'),
                            onPressed: () async {
                              // Atualiza no banco que o recibo foi enviado!
                              await docRef.update({'recibo_enviado': true});

                              Navigator.pop(contextDialog); // Fecha a janela
                              Navigator.pop(context); // Volta pra tela principal

                              await GeradorRecibo.gerarECompartilhar(
                                nomeMorador: nomeMorador,
                                rua: rua,
                                numeroCasa: numeroCasa,
                                valor: valorCobranca,
                                mesReferencia: mesReferencia,
                                dataPagamento: dataAtual,
                              );
                            },
                          ),
                          const SizedBox(height: 8),

                          // Botão de SMS
                          ElevatedButton.icon(

                            icon: const Icon(Icons.sms),
                            label: const Text('Enviar via SMS'),
                            onPressed: () async {
                              String urlStr = telefoneLimpo.isNotEmpty
                                  ? "sms:$telefoneLimpo?body=${Uri.encodeComponent(mensagem)}"
                                  : "sms:?body=${Uri.encodeComponent(mensagem)}";

                              // Atualiza no banco que o recibo foi enviado também via SMS!
                              await docRef.update({'recibo_enviado': true});

                              Navigator.pop(contextDialog);
                              Navigator.pop(context);
                              await launchUrl(Uri.parse(urlStr));
                            },
                          ),
                          const SizedBox(height: 8),

                          // Botão de Voltar para a Ronda (Sem enviar nada)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                            onPressed: () {
                              // Aqui NÃO atualizamos nada. O recibo continua como false e aparecerá no Dashboard!
                              Navigator.pop(contextDialog);
                              Navigator.pop(context);
                            },
                            child: const Text('Não enviar, voltar à ronda'),
                          ),
                        ],
                      );
                    },
                  );
                } catch (erro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ERRO: $erro',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 10),
                    ),
                  );
                }
              },
              child: const Text(
                'CONFIRMAR RECEBIMENTO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
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

// --- TELA 3: O COMPONENTE DA CALCULADORA ---
