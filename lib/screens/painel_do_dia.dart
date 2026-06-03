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

// --- TELA 1: O PAINEL PRINCIPAL ---
class PainelDoDia extends StatelessWidget {
  const PainelDoDia({super.key});

  @override
  Widget build(BuildContext context) {
    final diaDeHoje = DateTime.now().day;
    final dataAtual = DateTime.now();
    final mesReferencia =
        "${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}";
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Setor'),
        centerTitle: false,
      ),

      // --- O NOVO MENU LATERAL (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho do Menu
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.shield, size: 50, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Guarda Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Painel de Gestão',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Item 1: Cobrança Online
            ListTile(
              leading: const Icon(
                Icons.pix,
                color: Colors.teal,
                size: 28,
              ),
              title: const Text(
                'Central PIX',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Cobrança Remota'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu lateral
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaCobrancaOnline(),
                  ),
                );
              },
            ),

            // Item 2: Dashboard Financeiro
            ListTile(
              leading: const Icon(
                Icons.insert_chart,
                color: Colors.green,
                size: 28,
              ),
              title: const Text(
                'Dashboard Financeiro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Gráficos e Histórico'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaHistorico(),
                  ),
                );
              },
            ),

            const Divider(), // Uma linha divisória elegante
            // Item 3: Gestão de Moradores
            ListTile(
              leading: const Icon(
                Icons.people_alt,
                color: Colors.orange,
                size: 28,
              ),
              title: const Text(
                'Gestão de Moradores',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaGestaoMoradores(),
                  ),
                );
              },
            ),

            // Item 4: Novo Morador
            ListTile(
              leading: const Icon(
                Icons.person_add_alt_1,
                color: Colors.blueAccent,
                size: 28,
              ),
              title: const Text(
                'Novo Morador',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaNovoMorador(),
                  ),
                );
              },
            ),

            const Divider(),

            // Item 5: Configurações
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey, size: 28),
              title: const Text(
                'Configurações',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Chave PIX e Dados'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaPerfil()),
                );
              },
            ),

            // Item 6: Sair
            ListTile(
              leading: const Icon(
                Icons.exit_to_app,
                color: Colors.redAccent,
                size: 28,
              ),
              title: const Text(
                'Sair do Aplicativo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Fecha o menu primeiro
                showDialog(
                  context: context,
                  builder: (contextDialog) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sair da Conta?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: const Text(
                        'Tem certeza que deseja desconectar o seu usuário?',
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(contextDialog);
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text(
                            'Sim, sair',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),

      // --- O CORPO DA TELA (AGORA 100% LIMPO E FOCADO) ---
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Resumo de Hoje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),

          const CartaoResumo(),

          const SizedBox(height: 30),

          const Text(
            'Roteiro de Cobranças',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('moradores')
                .where('guarda_id', isEqualTo: uid)
                .where('dia_vencimento', isLessThanOrEqualTo: diaDeHoje)
                .snapshots(),
            builder: (context, snapshotMoradores) {
              if (snapshotMoradores.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshotMoradores.hasError) {
                return Center(
                  child: Text(
                    'ERRO DO FIREBASE:\n${snapshotMoradores.error}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pagamentos')
                    .where('guarda_id', isEqualTo: uid)
                    .where('mes_referencia', isEqualTo: mesReferencia)
                    .snapshots(),
                builder: (context, snapshotPagamentos) {
                  if (snapshotPagamentos.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<DocumentSnapshot> moradoresDevendo = [];

                  if (snapshotMoradores.hasData && snapshotPagamentos.hasData) {
                    Set<String> casasPagas = {};
                    for (var doc in snapshotPagamentos.data!.docs) {
                      casasPagas.add(
                        (doc.data() as Map<String, dynamic>)['casa'].toString(),
                      );
                    }

                    for (var doc in snapshotMoradores.data!.docs) {
                      final dadosMorador = doc.data() as Map<String, dynamic>;
                      final casaDoMorador = dadosMorador['endereco_numero'].toString();

                      // Verifica se a cobrança só começa no mês que vem
                      final dataInicioTs = dadosMorador['data_inicio_cobranca'] as Timestamp?;
                      if (dataInicioTs != null) {
                        final inicio = dataInicioTs.toDate();
                        // Se a data atual for menor que o início da cobrança, pula esse morador
                        if (dataAtual.isBefore(inicio)) {
                          continue;
                        }
                      }

                      if (!casasPagas.contains(casaDoMorador)) {
                        moradoresDevendo.add(doc);
                      }
                    }
                  }

                  if (moradoresDevendo.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: IndicadorProgressoMes(),
                    );
                  }

                  Map<String, List<DocumentSnapshot>> moradoresPorRua = {};

                  for (var doc in moradoresDevendo) {
                    final dados = doc.data() as Map<String, dynamic>;
                    final rua =
                        dados['endereco_rua']?.toString().trim() ?? 'Outros';

                    if (!moradoresPorRua.containsKey(rua)) {
                      moradoresPorRua[rua] = [];
                    }
                    moradoresPorRua[rua]!.add(doc);
                  }

                  List<String> ruasOrdenadas = moradoresPorRua.keys.toList();
                  ruasOrdenadas.sort((a, b) => a.compareTo(b));

                  List<Widget> listaVisual = [];

                  for (var rua in ruasOrdenadas) {
                    var moradoresDaRua = moradoresPorRua[rua]!;
                    moradoresDaRua.sort((a, b) {
                      final numA =
                          int.tryParse(
                            (a.data()
                                    as Map<String, dynamic>)['endereco_numero']
                                .toString(),
                          ) ??
                          0;
                      final numB =
                          int.tryParse(
                            (b.data()
                                    as Map<String, dynamic>)['endereco_numero']
                                .toString(),
                          ) ??
                          0;
                      return numA.compareTo(numB);
                    });

                    List<Widget> cartoesDaRua = [];
                    for (var documento in moradoresDaRua) {
                      final dados = documento.data() as Map<String, dynamic>;
                      final nome = dados['nome'] ?? 'Sem Nome';
                      final numeroCasa =
                          dados['endereco_numero']?.toString() ?? 'S/N';
                      final valor =
                          dados['valor_mensalidade']?.toString() ?? '0,00';
                      final telefone = dados['telefone']?.toString() ?? '';
                      final diaVencimento =
                          int.tryParse(dados['dia_vencimento'].toString()) ?? 1;

                      cartoesDaRua.add(
                        _construirCartaoMorador(
                          context,
                          numeroCasa,
                          nome,
                          valor,
                          rua,
                          diaVencimento,
                          telefone,
                        ),
                      );
                    }

                    listaVisual.add(
                      Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.blueAccent,
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
                              '${cartoesDaRua.length} cobrança(s)',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            iconColor: Colors.blueAccent,
                            collapsedIconColor: Colors.grey,
                            childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            children: cartoesDaRua,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: listaVisual,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _construirCartaoMorador(
    BuildContext context,
    String numeroCasa,
    String nome,
    String valor,
    String rua,
    int diaVencimento,
    String telefone,
  ) {
    final dataAtual = DateTime.now();
    Color corStatus = Colors.orange;

    if (dataAtual.day > diaVencimento) corStatus = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: corStatus.withAlpha(50), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TelaCobranca(
                nomeMorador: nome,
                rua: rua,
                numeroCasa: numeroCasa,
                valorCobranca: valor,
                telefoneMorador: telefone,
              ),
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: corStatus.withAlpha(38),
            radius: 28,
            child: Text(
              numeroCasa,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: corStatus,
              ),
            ),
          ),
          title: Text(
            nome,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'R\$ $valor',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: corStatus.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Dia $diaVencimento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: corStatus,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: 30,
            color: Colors.grey.shade400,
          ),
        ), // closes ListTile
        ), // closes InkWell
      ), // closes Material
    ); // closes Container
  }
}

// --- COMPONENTE: TERMÔMETRO DO MÊS ---
