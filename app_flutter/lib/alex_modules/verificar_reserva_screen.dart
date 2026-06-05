import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificarReservaScreen extends StatefulWidget {
  @override
  _VerificarReservaScreenState createState() => _VerificarReservaScreenState();
}

class _VerificarReservaScreenState extends State<VerificarReservaScreen> {
  final TextEditingController _criterioController = TextEditingController();
  List<dynamic> _resultados = [];
  bool _cargando = false;

  // Lógica para conectar Flutter con tu archivo PHP en XAMPP
  Future<void> _buscarReserva() async {
    setState(() { _cargando = true; });
    
    // NOTA: Si usas emulador de Android usa 'http://10.0.2.2/club_api/...'
    // Si pruebas en Flutter Web o dispositivo físico en la misma red, usa tu IP o 'localhost'
    final url = Uri.parse('http://10.0.2.2/club_api/verificar_reserva.php?criterio=${_criterioController.text}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() { 
          _resultados = json.decode(response.body); 
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión con XAMPP. Verifica tu URL o IP.')),
      );
    } finally {
      setState(() { _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CU5 - Verificar Reserva'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _criterioController,
              decoration: InputDecoration(
                labelText: 'Buscar por Nombre de Cliente o ID',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _buscarReserva, // Llama al backend al presionar
                ),
              ),
            ),
            SizedBox(height: 20),
            _cargando 
                ? CircularProgressIndicator()
                : Expanded(
                    child: _resultados.isEmpty
                        ? Center(child: Text('No se encontraron reservas pendientes.'))
                        : ListView.builder(
                            itemCount: _resultados.length,
                            itemBuilder: (context, index) {
                              final reserva = _resultados[index];
                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: Icon(Icons.calendar_today, color: Colors.green),
                                  title: Text('Cliente: ${reserva['nombre_cliente']}'),
                                  subtitle: Text('Fecha: ${reserva['fecha']} | Hora: ${reserva['hora_inicio']}'),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      // Aquí conectarás al flujo de Alquiler cuando tus compañeros lo tengan
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Reserva vinculada con éxito')),
                                      );
                                    },
                                    child: Text('Vincular'),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}