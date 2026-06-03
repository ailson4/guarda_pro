import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GeradorRecibo {
  static Future<void> gerarECompartilhar({
    required String nomeMorador,
    required String rua,
    required String numeroCasa,
    required String valor,
    required String mesReferencia,
    required DateTime dataPagamento,
  }) async {
    // Busca os dados do Guarda
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docGuarda = await FirebaseFirestore.instance.collection('perfil_guarda').doc(uid).get();
    String tituloApp = 'Guarda Pro - Segurança Noturna';
    if (docGuarda.exists && docGuarda.data()!['nome'] != null && docGuarda.data()!['nome'].toString().trim().isNotEmpty) {
      tituloApp = 'Guarda ${docGuarda.data()!['nome']}';
    }

    final pdf = pw.Document();
    
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(dataPagamento);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'RECIBO DE PAGAMENTO',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    tituloApp,
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.Divider(thickness: 2, height: 40),
                
                pw.Text('Recebemos de:', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                pw.Text(
                  nomeMorador,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Endereço: $rua, Nº $numeroCasa',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('A quantia de:', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                    pw.Text('Referente a:', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'R\$ $valor',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                    ),
                    pw.Text(
                      mesReferencia,
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Pagamento realizado em: $dataFormatada',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                
                pw.Spacer(),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Obrigado pela confiança e colaboração!',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.blueGrey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Salva o PDF em bytes
    final bytes = await pdf.save();

    // Compartilha o arquivo abrindo a gaveta do sistema nativo (WhatsApp, Email, etc)
    // No navegador (Web), isso tentará iniciar um download ou visualização de impressão.
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Recibo_$nomeMorador.pdf',
    );
  }
}
