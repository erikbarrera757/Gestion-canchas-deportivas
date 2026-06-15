// lib/utils/export_helper_web.dart

import 'dart:html' as html;
import 'dart:convert';

void exportToCsv(String title, List<String> headers, List<List<String>> rows) {
  final csvBuffer = StringBuffer();
  // UTF-8 BOM for Excel compatibility
  csvBuffer.write('\uFEFF');

  // Headers
  csvBuffer.writeln(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));

  // Rows
  for (final row in rows) {
    csvBuffer.writeln(row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','));
  }

  final bytes = utf8.encode(csvBuffer.toString());
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute("download", "${title.toLowerCase().replaceAll(' ', '_')}.csv")
    ..click();

  html.Url.revokeObjectUrl(url);
}

void exportToPdf(String title, List<String> headers, List<List<String>> rows) {
  final htmlContent = StringBuffer();
  htmlContent.write('''
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>$title</title>
    <style>
      body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        margin: 40px;
        color: #333;
      }
      h1 {
        color: #1a1a3a;
        border-bottom: 2px solid #4a9eff;
        padding-bottom: 10px;
        font-size: 24px;
      }
      .meta {
        font-size: 12px;
        color: #666;
        margin-bottom: 20px;
      }
      table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 20px;
      }
      th, td {
        border: 1px solid #ddd;
        padding: 10px;
        text-align: left;
        font-size: 13px;
      }
      th {
        background-color: #f2f2f2;
        color: #1a1a3a;
        font-weight: bold;
      }
      tr:nth-child(even) {
        background-color: #fafafa;
      }
      @media print {
        body { margin: 20px; }
      }
    </style>
  </head>
  <body>
    <h1>$title</h1>
    <div class="meta">Reporte generado el ${DateTime.now().toString().substring(0, 19)}</div>
    <table>
      <thead>
        <tr>
  ''');

  for (final header in headers) {
    htmlContent.write('<th>$header</th>');
  }

  htmlContent.write('''
        </tr>
      </thead>
      <tbody>
  ''');

  for (final row in rows) {
    htmlContent.write('<tr>');
    for (final cell in row) {
      htmlContent.write('<td>$cell</td>');
    }
    htmlContent.write('</tr>');
  }

  htmlContent.write('''
      </tbody>
    </table>
    <script>
      window.onload = function() {
        window.print();
      };
    </script>
  </body>
  </html>
  ''');

  final blob = html.Blob([htmlContent.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
