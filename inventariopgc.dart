import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class InventarioPGC extends StatefulWidget {
  @override
  _InventarioPGCState createState() => _InventarioPGCState();
}

class _InventarioPGCState extends State<InventarioPGC> {
  final List<Producto> productos = [];
  final codigoController = TextEditingController();
  final cantidadController = TextEditingController();
  final palletController = TextEditingController();
  final responsableController = TextEditingController();
  int numeroProducto = 1;
  bool finIngresoDatos = false;

  @override
  void dispose() {
    codigoController.dispose();
    cantidadController.dispose();
    palletController.dispose();
    responsableController.dispose();
    super.dispose();
  }

  void reiniciarValores() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reiniciar valores'),
          content: Text('¿Desea borrar todos los datos ingresados?'),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                setState(() {
                  productos.clear();
                  numeroProducto = 1;
                  codigoController.clear();
                  cantidadController.clear();
                  palletController.clear();
                  responsableController.clear();
                  finIngresoDatos = false;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void agregarProducto() {
    final codigo = codigoController.text;
    final cantidad = cantidadController.text;

    final producto = Producto(codigo, numeroProducto.toString(), cantidad);
    productos.add(producto);

    codigoController.clear();
    cantidadController.clear();

    mostrarMensaje('Producto agregado');

    setState(() {
      numeroProducto++;
    });
  }

  Future<void> scanBarcode() async {
    String barcodeScanResult = await FlutterBarcodeScanner.scanBarcode(
      '#FF0000',
      'Cancelar',
      true,
      ScanMode.BARCODE,
    );

    if (barcodeScanResult != '-1') {
      setState(() {
        codigoController.text = barcodeScanResult;
      });
    }
  }

  void modificarProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nuevoCodigoController =
            TextEditingController(text: producto.codigo);
        final nuevaCantidadController =
            TextEditingController(text: producto.cantidad);

        return AlertDialog(
          title: Text('Modificar producto'),
          content: Column(
            children: [
              TextFormField(
                controller: nuevoCodigoController,
                decoration: InputDecoration(
                  labelText: 'Nuevo código',
                ),
              ),
              TextFormField(
                controller: nuevaCantidadController,
                decoration: InputDecoration(labelText: 'Nueva cantidad'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                final nuevoCodigo = nuevoCodigoController.text;
                final nuevaCantidad = nuevaCantidadController.text;
                setState(() {
                  producto.codigo = nuevoCodigo;
                  producto.cantidad = nuevaCantidad;
                });
                Navigator.of(context).pop();
                mostrarMensaje('Producto modificado');
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void copiarProductos() {
    final String pallet = palletController.text;
    final String responsable = responsableController.text;

    final List<String> filas = [
      'PALLET TRABAJADO: $pallet, RESPONSABLE: $responsable',
      'Código   Número de caja   Cantidad',
      ...productos.map((producto) =>
          '${producto.codigo}   ${producto.caja}   ${producto.cantidad}'),
    ];

    final String productosOrdenados = filas.join('\n');

    Clipboard.setData(ClipboardData(text: productosOrdenados));
    mostrarMensaje('Productos copiados al portapapeles');
  }

  void mostrarMensaje(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mensaje'),
          content: Text(mensaje),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void generarYGuardarExcel() async {
    // Crea una instancia de la clase Excel
    var excel = Excel.createExcel();

    // Crea una hoja en el archivo de Excel
    var hoja = excel['Hoja1'];

    // Agrega datos a la hoja de Excel
    hoja.appendRow(['Caja', 'Codigo', 'Cantidad']);
    for(var product in productos){
      hoja.appendRow([product.caja, product.codigo, product.cantidad]);
    }

    // Obtiene el directorio de documentos del dispositivo
    var directorio = await getApplicationDocumentsDirectory();
    var ruta = '${directorio.path}/archivo_excel.xlsx';

    // Guarda el archivo de Excel en la ruta especificada
    var bytes = excel.encode()!;
    await File(ruta).writeAsBytes(bytes);

    print('Archivo Excel generado y guardado en: $ruta');

    descargarExcel(ruta);
  }

  void descargarExcel(String ruta) async {
    try {

      // Lee el archivo de Excel como bytes
      final bytes = await File(ruta).readAsBytes();

      // Escribe los bytes en el directorio de almacenamiento externo (tarjeta SD)
      final directorioDescarga = await getExternalStorageDirectory();
      final archivoDescarga = File('${directorioDescarga!.path}/archivo_excel.xlsx');
      await archivoDescarga.writeAsBytes(bytes);
      
      // Abre el archivo despues de descargarlo
      OpenFile.open(archivoDescarga.path);

    } catch (e) {
      print('Error al descargar el archivo: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventariando ando'),
        actions: [
          GestureDetector(
            onTap: (){
              await generarYGuardarExcel();
            },
            child: Icon(Icons.download),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              'Caja N° : $numeroProducto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(13),
                    ],
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner),
                  onPressed: scanBarcode,
                ),
              ],
            ),
            TextFormField(
              controller: cantidadController,
              decoration: InputDecoration(labelText: 'Cantidad'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.0),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                      primary: Color.fromARGB(255, 4, 75, 26)),
                  onPressed: agregarProducto,
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Copiar productos'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('¿Qué pallet se trabajó?'),
                              TextFormField(
                                controller: palletController,
                              ),
                              SizedBox(height: 8.0),
                              Text('Nombre'),
                              TextFormField(
                                controller: responsableController,
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Aceptar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                copiarProductos();
                              },
                            ),
                            TextButton(
                              child: Text('Cancelar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: reiniciarValores,
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final producto = productos[index];
                  return ListTile(
                    title: Text(
                        'Caja n°${producto.caja}:     Codigo: ${producto.codigo}'),
                    subtitle: Text('Cantidad: ${producto.cantidad}'),
                    onTap: () => modificarProducto(producto),
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

class Producto {
  String codigo;
  String caja;
  String cantidad;

  Producto(this.codigo, this.caja, this.cantidad);
}
