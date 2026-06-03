import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CartaoResumo extends StatelessWidget {
  const CartaoResumo({super.key});

  @override
  Widget build(BuildContext context) {
    final diaDeHoje = DateTime.now().day;
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('moradores')
          .where('guarda_id', isEqualTo: uid)
          .where('dia_vencimento', isLessThanOrEqualTo: diaDeHoje)
          .snapshots(),
      builder: (context, snapshotMoradores) {
        final dataAtual = DateTime.now();
        final mesReferencia =
            "${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}";

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pagamentos')
              .where('guarda_id', isEqualTo: uid)
              .where('mes_referencia', isEqualTo: mesReferencia)
              .snapshots(),
          builder: (context, snapshotPagamentos) {
            double aReceberHoje = 0.0;
            bool carregando = true;

            if (snapshotMoradores.connectionState != ConnectionState.waiting &&
                snapshotPagamentos.connectionState != ConnectionState.waiting) {
              carregando = false;

              if (snapshotMoradores.hasData &&
                  snapshotMoradores.data!.docs.isNotEmpty) {
                double totalEsperado = 0;
                double totalPago = 0;
                List<String> casasNaLista = [];

                for (var doc in snapshotMoradores.data!.docs) {
                  final dados = doc.data() as Map<String, dynamic>;
                  
                  // Ignora se a cobrança só começa no mês que vem
                  final dataInicioTs = dados['data_inicio_cobranca'] as Timestamp?;
                  if (dataInicioTs != null) {
                    final inicio = dataInicioTs.toDate();
                    if (dataAtual.isBefore(inicio)) {
                      continue;
                    }
                  }

                  final valorString =
                      dados['valor_mensalidade']?.toString() ?? '0';
                  totalEsperado += _converterParaNumero(valorString);
                  casasNaLista.add(dados['endereco_numero']?.toString() ?? '');
                }

                if (snapshotPagamentos.hasData) {
                  for (var doc in snapshotPagamentos.data!.docs) {
                    final dados = doc.data() as Map<String, dynamic>;
                    final casaPaga = dados['casa']?.toString() ?? '';
                    if (casasNaLista.contains(casaPaga)) {
                      final valorString = dados['valor']?.toString() ?? '0';
                      totalPago += _converterParaNumero(valorString);
                    }
                  }
                }

                aReceberHoje = totalEsperado - totalPago;
                if (aReceberHoje < 0) aReceberHoje = 0;
              }
            }

            Color corDoDinheiro = aReceberHoje <= 0
                ? Colors.green
                : Colors.orange;

            // --- CRIAMOS O FORMATADOR AQUI ---
            final formatadorMoeda = NumberFormat.currency(
              locale: 'pt_BR',
              symbol: 'R\$',
            );

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A Receber Hoje',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      carregando
                          ? const Text(
                              '...',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              formatadorMoeda.format(aReceberHoje),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ],
                  ),
                  Icon(
                    aReceberHoje <= 0
                        ? Icons.check_circle
                        : Icons.account_balance_wallet,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

double _converterParaNumero(String valor) {
  try {
    return double.parse(valor.replaceAll(',', '.'));
  } catch (e) {
    return 0.0;
  }
}

// --- TELA 4: CADASTRAR NOVO MORADOR ---
