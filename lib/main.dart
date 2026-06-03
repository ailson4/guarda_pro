import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

import 'screens/tela_login.dart';
import 'screens/painel_do_dia.dart';
import 'screens/tela_cobranca.dart';
import 'screens/tela_novo_morador.dart';
import 'screens/tela_gestao_moradores.dart';
import 'screens/tela_editar_morador.dart';
import 'screens/tela_historico.dart';
import 'screens/tela_perfil.dart';
import 'screens/tela_cobranca_online.dart';
import 'screens/tela_app_lock.dart';
import 'widgets/indicador_progresso_mes.dart';
import 'widgets/cartao_resumo.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          background: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFF1E293B),
          displayColor: const Color(0xFF0F172A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const TelaAppLock(child: VerificadorAssinatura());
          }
          return const TelaLogin();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- TELA DE LOGIN ---

class VerificadorAssinatura extends StatelessWidget {
  const VerificadorAssinatura({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      // Ele vai procurar a pasta 'guardas' e o documento com o ID do usuário
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

        // 1. Se o documento não existir, a gente bloqueia por segurança
        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint('BLOQUEIO: Documento não existe para o UID: $uid');
          return const TelaBloqueioAssinatura();
        }

        final dados = snapshot.data!.data() as Map<String, dynamic>;

        // 2. Procura pela data de vencimento. Se não achar, bloqueia.
        if (!dados.containsKey('vencimento')) {
          debugPrint(
            'BLOQUEIO: O campo "vencimento" não foi encontrado no banco de dados!',
          );
          return const TelaBloqueioAssinatura();
        }

        final vencimentoTimestamp = dados['vencimento'] as Timestamp?;

        // 3. Se a data estiver vazia (nula), bloqueia também
        if (vencimentoTimestamp == null) {
          debugPrint(
            'BLOQUEIO: O campo "vencimento" existe, mas está vazio (null).',
          );
          return const TelaBloqueioAssinatura();
        }

        final dataVencimento = vencimentoTimestamp.toDate();
        final dataAtual = DateTime.now();

        // 4. Limpa as horas para comparar apenas os dias (ex: 18/03 com 18/03)
        final hoje = DateTime(dataAtual.year, dataAtual.month, dataAtual.day);
        final limite = DateTime(
          dataVencimento.year,
          dataVencimento.month,
          dataVencimento.day,
        );

        // A REGRA DE OURO: Se hoje for MAIOR que o limite, a catraca desce!
        if (hoje.isAfter(limite)) {
          debugPrint(
            'BLOQUEIO: Assinatura vencida. Hoje é $hoje e o limite era $limite.',
          );
          return const TelaBloqueioAssinatura();
        }

        // Se passar por todos os testes de segurança acima, libera a catraca!
        debugPrint('SUCESSO: Acesso liberado! Vencimento em: $limite');
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

