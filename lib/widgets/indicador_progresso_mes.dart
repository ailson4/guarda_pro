import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class IndicadorProgressoMes extends StatelessWidget {
  const IndicadorProgressoMes({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final dataAtual = DateTime.now();
    final mesReferencia =
        "${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('moradores')
          .where('guarda_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshotMoradores) {
        if (!snapshotMoradores.hasData) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pagamentos')
              .where('guarda_id', isEqualTo: uid)
              .where('mes_referencia', isEqualTo: mesReferencia)
              .snapshots(),
          builder: (context, snapshotPagamentos) {
            if (!snapshotPagamentos.hasData) return const SizedBox.shrink();

            int totalCasas = snapshotMoradores.data!.docs.length;
            int casasPagas = 0;

            Set<String> casasQuePagaram = {};
            for (var doc in snapshotPagamentos.data!.docs) {
              final dados = doc.data() as Map<String, dynamic>;
              casasQuePagaram.add(dados['casa']?.toString() ?? '');
            }

            for (var doc in snapshotMoradores.data!.docs) {
              final dados = doc.data() as Map<String, dynamic>;
              final numeroCasa = dados['endereco_numero']?.toString() ?? '';
              if (casasQuePagaram.contains(numeroCasa)) {
                casasPagas++;
              }
            }

            double progresso = totalCasas == 0 ? 0 : casasPagas / totalCasas;
            int porcentagem = (progresso * 100).toInt();

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 80,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Setor em Dia!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nenhuma cobrança pendente para hoje.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(20),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progresso do Mês',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Text(
                            '$porcentagem%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 14,
                          backgroundColor: Colors.blue.shade50,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$casasPagas de $totalCasas casas já realizaram o pagamento este mês.',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- TELA 2: A TELA DE COBRANÇA ---
