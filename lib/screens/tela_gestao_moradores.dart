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

class TelaGestaoMoradores extends StatefulWidget {
  const TelaGestaoMoradores({super.key});

  @override
  State<TelaGestaoMoradores> createState() => _TelaGestaoMoradoresState();
}

class _TelaGestaoMoradoresState extends State<TelaGestaoMoradores> {
  String _termoBusca = '';

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Lista')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (valor) {
                setState(() => _termoBusca = valor.toLowerCase());
              },
              decoration: const InputDecoration(
                labelText: 'Buscar por nome, rua ou dia...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('moradores')
                  .where('guarda_id', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final moradoresFiltrados = snapshot.data!.docs.where((doc) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final nome = (dados['nome'] ?? '').toString().toLowerCase();
                  final rua = (dados['endereco_rua'] ?? '')
                      .toString()
                      .toLowerCase();
                  final dia = (dados['dia_vencimento'] ?? '').toString();
                  return nome.contains(_termoBusca) ||
                      rua.contains(_termoBusca) ||
                      dia.contains(_termoBusca);
                }).toList();

                if (moradoresFiltrados.isEmpty)
                  return const Center(
                    child: Text('Nenhum morador encontrado.'),
                  );

                // --- NOVA LÓGICA: AGRUPAR POR RUA (MANTENDO O FILTRO DE BUSCA) ---
                Map<String, List<QueryDocumentSnapshot>> moradoresPorRua = {};

                for (var doc in moradoresFiltrados) {
                  final dados = doc.data() as Map<String, dynamic>;
                  final rua =
                      dados['endereco_rua']?.toString().trim() ?? 'Outros';

                  if (!moradoresPorRua.containsKey(rua)) {
                    moradoresPorRua[rua] = [];
                  }
                  moradoresPorRua[rua]!.add(doc);
                }

                // Ordena o nome das ruas em ordem alfabética
                List<String> ruasOrdenadas = moradoresPorRua.keys.toList();
                ruasOrdenadas.sort((a, b) => a.compareTo(b));

                List<Widget> listaVisual = [];

                for (var rua in ruasOrdenadas) {
                  var moradoresDaRua = moradoresPorRua[rua]!;

                  // Ordena as casas da rua pelo número
                  moradoresDaRua.sort((a, b) {
                    final numA =
                        int.tryParse(
                          (a.data() as Map<String, dynamic>)['endereco_numero']
                              .toString(),
                        ) ??
                        0;
                    final numB =
                        int.tryParse(
                          (b.data() as Map<String, dynamic>)['endereco_numero']
                              .toString(),
                        ) ??
                        0;
                    return numA.compareTo(numB);
                  });

                  // Constrói os cartões originais com os botões de editar e excluir
                  List<Widget> cartoesDaRua = moradoresDaRua.map((doc) {
                    final dados = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blueAccent.withAlpha(40),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dados['nome'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Casa ${dados['endereco_numero']} - Dia ${dados['dia_vencimento']}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
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
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.attach_money,
                                    color: Colors.green,
                                  ),
                                  label: const Text(
                                    'Receber',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TelaCobranca(
                                          nomeMorador: dados['nome'] ?? '',
                                          rua: dados['endereco_rua'] ?? '',
                                          numeroCasa: dados['endereco_numero']?.toString() ?? '',
                                          valorCobranca: dados['valor_mensalidade']?.toString() ?? '',
                                          telefoneMorador: dados['telefone']?.toString() ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TelaEditarMorador(
                                          docId: doc.id,
                                          dadosIniciais: dados,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Excluir Morador?'),
                                        content: const Text(
                                          'Tem certeza que deseja apagar este cadastro?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('moradores')
                                                  .doc(doc.id)
                                                  .delete();
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              'Sim, excluir',
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
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

                  // Adiciona a "Sanfona" da rua na lista principal
                  listaVisual.add(
                    Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.holiday_village,
                            color: Colors.blueGrey,
                            size: 28,
                          ),
                          title: Text(
                            rua,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          subtitle: Text(
                            '${cartoesDaRua.length} cadastrado(s)',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          iconColor: Colors.blueGrey,
                          collapsedIconColor: Colors.grey,
                          childrenPadding: const EdgeInsets.only(
                            left: 8.0,
                            right: 8.0,
                            bottom: 12.0,
                          ),
                          children: cartoesDaRua,
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: listaVisual,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- TELA 6: EDITAR MORADOR EXISTENTE ---
