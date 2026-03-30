import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppGuarda());
}

class AppGuarda extends StatelessWidget {
  const AppGuarda({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Guarda',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const VerificadorAssinatura();
          }
          return const TelaLogin();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- TELA DE LOGIN ---
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
          content: Text('Erro ao entrar: ${e.message}'),
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
                decoration: InputDecoration(
                  labelText: 'E-mail cadastrado',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 110,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Guarda Pro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
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

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        title: const Text(
          'Meu Setor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
        centerTitle: false,
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
        // Removemos todos os "actions" daqui. O Flutter vai colocar o ícone de Menu (≡) automaticamente na esquerda!
      ),

      // --- O NOVO MENU LATERAL (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabeçalho do Menu
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey.shade700),
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
                Icons.send_to_mobile,
                color: Colors.teal,
                size: 28,
              ),
              title: const Text(
                'Cobrança Online',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('WhatsApp PIX'),
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
                      final casaDoMorador =
                          (doc.data()
                                  as Map<String, dynamic>)['endereco_numero']
                              .toString();
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: corStatus.withAlpha(128), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TelaCobranca(
                nomeMorador: nome,
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
        ),
      ),
    );
  }
}

// --- COMPONENTE: TERMÔMETRO DO MÊS ---
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
class TelaCobranca extends StatelessWidget {
  final String nomeMorador;
  final String numeroCasa;
  final String valorCobranca;
  final String telefoneMorador;

  const TelaCobranca({
    super.key,
    required this.nomeMorador,
    required this.numeroCasa,
    required this.valorCobranca,
    required this.telefoneMorador,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receber Pagamento')),
      body: Padding(
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
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                          // Botão do WhatsApp
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                            icon: const Icon(Icons.chat),
                            label: const Text('Enviar via WhatsApp'),
                            onPressed: () async {
                              String urlStr = telefoneLimpo.isNotEmpty
                                  ? "https://wa.me/55$telefoneLimpo?text=${Uri.encodeComponent(mensagem)}"
                                  : "https://wa.me/?text=${Uri.encodeComponent(mensagem)}";

                              // Atualiza no banco que o recibo foi enviado!
                              await docRef.update({'recibo_enviado': true});

                              Navigator.pop(contextDialog); // Fecha a janela
                              Navigator.pop(
                                context,
                              ); // Volta pra tela principal
                              await launchUrl(
                                Uri.parse(urlStr),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                          const SizedBox(height: 8),

                          // Botão de SMS
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 45),
                            ),
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
    );
  }
}

// --- TELA 3: O COMPONENTE DA CALCULADORA ---
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A Receber Hoje',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      carregando
                          ? const Text(
                              '...',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            )
                          : Text(
                              // --- APLICAMOS A MÁGICA DA FORMATAÇÃO AQUI ---
                              formatadorMoeda.format(aReceberHoje),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: corDoDinheiro,
                              ),
                            ),
                    ],
                  ),
                  Icon(
                    aReceberHoje <= 0
                        ? Icons.check_circle
                        : Icons.account_balance_wallet,
                    size: 40,
                    color: corDoDinheiro,
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
class TelaNovoMorador extends StatefulWidget {
  const TelaNovoMorador({super.key});

  @override
  State<TelaNovoMorador> createState() => _TelaNovoMoradorState();
}

class _TelaNovoMoradorState extends State<TelaNovoMorador> {
  final _controleNome = TextEditingController();
  final _controleRua = TextEditingController();
  final _controleCasa = TextEditingController();
  final _controleValor = TextEditingController();
  final _controleDia = TextEditingController();
  final _controleTelefone = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Morador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            TextField(
              controller: _controleNome,
              decoration: const InputDecoration(
                labelText: 'Nome do Morador',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleRua,
              decoration: const InputDecoration(
                labelText: 'Nome da Rua',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.signpost),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleCasa,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número da Casa',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleTelefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp (Ex: 16999999999)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleValor,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor da Mensalidade (Ex: 50,00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleDia,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Dia do Pagamento (Ex: 10)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

                final String uid = FirebaseAuth.instance.currentUser!.uid;

                await FirebaseFirestore.instance.collection('moradores').add({
                  'nome': _controleNome.text,
                  'endereco_rua': _controleRua.text,
                  'endereco_numero': _controleCasa.text,
                  'telefone': _controleTelefone.text,
                  'valor_mensalidade': _controleValor.text,
                  'dia_vencimento': int.tryParse(_controleDia.text) ?? 1,
                  'guarda_id': uid,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Morador cadastrado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'SALVAR MORADOR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA 5: GESTÃO DE MORADORES COM FILTRO ---
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
              decoration: InputDecoration(
                labelText: 'Buscar por nome, rua ou dia...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
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
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withAlpha(40),
                          child: const Icon(
                            Icons.person,
                            color: Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          dados['nome'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Casa ${dados['endereco_numero']} - Dia ${dados['dia_vencimento']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                      ),
                    );
                  }).toList();

                  // Adiciona a "Sanfona" da rua na lista principal
                  listaVisual.add(
                    Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Morador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.manage_accounts, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            TextField(
              controller: _controleNome,
              decoration: const InputDecoration(
                labelText: 'Nome do Morador',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleRua,
              decoration: const InputDecoration(
                labelText: 'Nome da Rua',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.signpost),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleCasa,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número da Casa',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleTelefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp (Ex: 16999999999)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleValor,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor da Mensalidade (Ex: 50,00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controleDia,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Dia do Pagamento (Ex: 10)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

                await FirebaseFirestore.instance
                    .collection('moradores')
                    .doc(widget.docId)
                    .update({
                      'nome': _controleNome.text,
                      'endereco_rua': _controleRua.text,
                      'endereco_numero': _controleCasa.text,
                      'telefone': _controleTelefone.text,
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
    );
  }
}

// --- TELA 7: HISTÓRICO COM BOTÃO DO WHATSAPP DIRETO ---
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
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor: Colors
                                                            .green
                                                            .shade600,
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize: const Size(
                                                          double.infinity,
                                                          45,
                                                        ),
                                                      ),
                                                  icon: const Icon(Icons.chat),
                                                  label: const Text(
                                                    'Enviar via WhatsApp',
                                                  ),
                                                  onPressed: () async {
                                                    String urlStr =
                                                        telefoneLimpo.isNotEmpty
                                                        ? "https://wa.me/55$telefoneLimpo?text=${Uri.encodeComponent(mensagem)}"
                                                        : "https://wa.me/?text=${Uri.encodeComponent(mensagem)}";
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
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.blueAccent,
                                                        foregroundColor:
                                                            Colors.white,
                                                        minimumSize: const Size(
                                                          double.infinity,
                                                          45,
                                                        ),
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
class VerificadorAssinatura extends StatelessWidget {
  const VerificadorAssinatura({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      // Ele vai procurar uma pasta chamada 'guardas' e o documento com o ID do usuário
      stream: FirebaseFirestore.instance
          .collection('guardas')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o documento não existir, a gente bloqueia por segurança
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const TelaBloqueioAssinatura();
        }

        final dados = snapshot.data!.data() as Map<String, dynamic>;
        final vencimentoTimestamp = dados['vencimento'] as Timestamp?;

        // Se esquecermos de colocar a data no banco de dados, bloqueia também
        if (vencimentoTimestamp == null) {
          return const TelaBloqueioAssinatura();
        }

        final dataVencimento = vencimentoTimestamp.toDate();
        final dataAtual = DateTime.now();

        // Limpa as horas para comparar apenas os dias (ex: 18/03 com 18/03)
        final hoje = DateTime(dataAtual.year, dataAtual.month, dataAtual.day);
        final limite = DateTime(
          dataVencimento.year,
          dataVencimento.month,
          dataVencimento.day,
        );

        // A REGRA DE OURO: Se hoje for MAIOR que o limite, a catraca desce!
        if (hoje.isAfter(limite)) {
          return const TelaBloqueioAssinatura();
        }

        // Se estiver tudo certo, libera a catraca e mostra o aplicativo!
        return const PainelDoDia();
      },
    );
  }
}

// --- TELA DE BLOQUEIO (COBRANÇA DO SAAS) ---
class TelaBloqueioAssinatura extends StatelessWidget {
  const TelaBloqueioAssinatura({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent.shade700,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_clock, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Acesso Bloqueado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sua assinatura do Guarda Pro venceu.\nPara continuar acessando seus moradores e seu roteiro de cobranças, realize o pagamento da mensalidade.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Chave PIX (Celular)',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  // Mude este número para a sua chave PIX real depois
                  const Text(
                    '(16) 99999-9999',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Valor: R\$ 50,00',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.chat),
              label: const Text(
                'Enviar Comprovante',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                // Altere o número "5516999999999" para o seu WhatsApp pessoal/profissional
                final url = Uri.parse(
                  "https://wa.me/5516999999999?text=Ol%C3%A1%2C+segue+o+comprovante+da+minha+assinatura+do+App+do+Guarda.",
                );
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.exit_to_app, color: Colors.white70),
              label: const Text(
                'Sair da Conta',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
                    decoration: InputDecoration(
                      labelText: 'Seu Nome (Ex: Guarda João)',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo CHAVE PIX
                  TextField(
                    controller: _chavePixController,
                    decoration: InputDecoration(
                      labelText: 'Sua Chave PIX (Celular, CPF, E-mail...)',
                      prefixIcon: const Icon(Icons.pix, color: Colors.teal),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botão SALVAR
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
          child: Row(
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
        title: const Text('Fila de Cobrança'),
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
