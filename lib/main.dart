import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:image_picker/image_picker.dart';

const String MONGO_URL = "mongodb+srv://vuongday:vuong123@cluster0.ddlkr.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";
const String COLLECTION_NAME = "products";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MongoService.connect();
  } catch (e) {
    print("Lỗi kết nối MongoDB: $e");
  }
  runApp(MyApp());
}

class MongoService {
  static late mongo.Db _db;
  static late mongo.DbCollection _collection;

  static Future<void> connect() async {
    try {
      _db = await mongo.Db.create(MONGO_URL);
      await _db.open();
      _collection = _db.collection(COLLECTION_NAME);
      print("🔗 Kết nối MongoDB thành công!");
    } catch (e) {
      print("Lỗi kết nối MongoDB: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      return await _collection.find().toList();
    } catch (e) {
      print("Lỗi lấy danh sách sản phẩm: $e");
      return [];
    }
  }

  static Future<bool> addProduct(String id, String loaiSP, double gia, String hinhAnh) async {
    try {
      await _collection.insertOne({
        "idsanpham": id,
        "loaisp": loaiSP,
        "gia": gia,
        "hinhanh": hinhAnh
      });
      return true;
    } catch (e) {
      print("Lỗi thêm sản phẩm: $e");
      return false;
    }
  }

  static Future<bool> updateProduct(String id, String loaiSP, double gia, String hinhAnh) async {
    try {
      await _collection.updateOne(
        mongo.where.eq('idsanpham', id),
        mongo.modify.set('loaisp', loaiSP).set('gia', gia).set('hinhanh', hinhAnh),
      );
      return true;
    } catch (e) {
      print("Lỗi sửa sản phẩm: $e");
      return false;
    }
  }

  static Future<bool> deleteProduct(String id) async {
    try {
      await _collection.deleteOne(mongo.where.eq('idsanpham', id));
      return true;
    } catch (e) {
      print("Lỗi xóa sản phẩm: $e");
      return false;
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Map<String, dynamic>>> products;
  String searchQuery = ""; // Biến để lưu từ khóa tìm kiếm

  @override
  void initState() {
    super.initState();
    products = MongoService.getProducts();
  }

  void refreshProducts() {
    setState(() {
      products = MongoService.getProducts();
    });
  }

  Future<void> pickImage(ImageSource source, TextEditingController controller) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        controller.text = pickedFile.path;
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi chọn ảnh: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showProductDialog({String? id, String? loaiSP, double? gia, String? hinhAnh}) {
    TextEditingController loaiSPController = TextEditingController(text: loaiSP ?? "");
    TextEditingController giaController = TextEditingController(text: gia?.toString() ?? "");
    TextEditingController hinhAnhController = TextEditingController(text: hinhAnh ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id == null ? "Thêm sản phẩm mới" : "Chỉnh sửa sản phẩm",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: loaiSPController,
                        decoration: InputDecoration(
                          labelText: "Loại sản phẩm",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: giaController,
                        decoration: InputDecoration(
                          labelText: "Giá (VND)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: hinhAnhController,
                        decoration: InputDecoration(
                          labelText: "Đường dẫn hình ảnh",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        readOnly: true,
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.photo),
                            label: Text("Thư viện"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            ),
                            onPressed: () async {
                              await pickImage(ImageSource.gallery, hinhAnhController);
                              setState(() {});
                            },
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.camera_alt),
                            label: Text("Máy ảnh"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            ),
                            onPressed: () async {
                              await pickImage(ImageSource.camera, hinhAnhController);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      if (hinhAnhController.text.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(hinhAnhController.text),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Hủy", style: TextStyle(color: Colors.grey[600])),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () async {
                              if (loaiSPController.text.isEmpty || giaController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Vui lòng điền đầy đủ thông tin"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              double? gia;
                              try {
                                gia = double.parse(giaController.text);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Giá phải là một số hợp lệ"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              bool success;
                              if (id == null) {
                                success = await MongoService.addProduct(
                                  DateTime.now().millisecondsSinceEpoch.toString(),
                                  loaiSPController.text,
                                  gia,
                                  hinhAnhController.text,
                                );
                              } else {
                                success = await MongoService.updateProduct(
                                  id,
                                  loaiSPController.text,
                                  gia,
                                  hinhAnhController.text,
                                );
                              }

                              if (success) {
                                refreshProducts();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(id == null ? "Thêm thành công" : "Cập nhật thành công"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Thao tác thất bại"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(id == null ? "Thêm" : "Cập nhật"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách sản phẩm"),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 236, 120, 5),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm sản phẩm...",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase(); // Cập nhật từ khóa tìm kiếm
                });
              },
            ),
          ),
          // Danh sách sản phẩm
          Expanded(
            child: FutureBuilder(
              future: products,
              builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: const Color.fromARGB(255, 244, 22, 22)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}", style: TextStyle(color: Colors.red)));
                }
                final products = snapshot.data ?? [];
                // Lọc sản phẩm dựa trên từ khóa tìm kiếm
                final filteredProducts = products.where((product) {
                  final loaiSP = product['loaisp'].toString().toLowerCase();
                  final gia = product['gia'].toString();
                  return loaiSP.contains(searchQuery) || gia.contains(searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(child: Text("Không tìm thấy sản phẩm", style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product['hinhanh'].isNotEmpty
                              ? Image.file(
                                  File(product['hinhanh']),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.broken_image, color: Colors.grey[600]),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image, color: Colors.grey[600]),
                                ),
                        ),
                        title: Text(
                          product['loaisp'],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          "Giá: ${product['gia'].toStringAsFixed(0)} VND",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: const Color.fromARGB(255, 246, 167, 10)),
                              onPressed: () => showProductDialog(
                                id: product['idsanpham'],
                                loaiSP: product['loaisp'],
                                gia: product['gia'].toDouble(),
                                hinhAnh: product['hinhanh'],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                bool success = await MongoService.deleteProduct(product['idsanpham']);
                                if (success) {
                                  refreshProducts();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Xóa thành công"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Xóa thất bại"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 102, 217, 240),
        onPressed: () => showProductDialog(),
        child: Icon(Icons.add, size: 30),
      ),
    );
  }
}