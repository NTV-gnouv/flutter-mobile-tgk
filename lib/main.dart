import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';

const String MONGO_URL = "mongodb+srv://vuongday:vuong123@cluster0.ddlkr.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";
const String PRODUCT_COLLECTION = "products";
const String USER_COLLECTION = "users";

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
  static late mongo.DbCollection _products;
  static late mongo.DbCollection _users;

  static Future<void> connect() async {
    try {
      _db = await mongo.Db.create(MONGO_URL);
      await _db.open();
      _products = _db.collection(PRODUCT_COLLECTION);
      _users = _db.collection(USER_COLLECTION);
      print("🔗 Kết nối MongoDB thành công!");
    } catch (e) {
      print("Lỗi kết nối MongoDB: $e");
      rethrow;
    }
  }

  // Product methods
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      return await _products.find().toList();
    } catch (e) {
      print("Lỗi lấy danh sách sản phẩm: $e");
      return [];
    }
  }

  static Future<bool> addProduct(String id, String loaiSP, double gia, String hinhAnh) async {
    try {
      await _products.insertOne({
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
      await _products.updateOne(
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
      await _products.deleteOne(mongo.where.eq('idsanpham', id));
      return true;
    } catch (e) {
      print("Lỗi xóa sản phẩm: $e");
      return false;
    }
  }

  // User methods
  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static Future<bool> registerUser(String username, String password) async {
    try {
      var existingUser = await _users.findOne(mongo.where.eq('username', username));
      if (existingUser != null) return false;
      
      await _users.insertOne({
        "username": username,
        "password": _hashPassword(password),
        "createdAt": DateTime.now()
      });
      return true;
    } catch (e) {
      print("Lỗi đăng ký: $e");
      return false;
    }
  }

  static Future<bool> loginUser(String username, String password) async {
    try {
      var user = await _users.findOne(mongo.where.eq('username', username));
      if (user == null) return false;
      return user['password'] == _hashPassword(password);
    } catch (e) {
      print("Lỗi đăng nhập: $e");
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/products': (context) => ProductListScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Đăng nhập",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _handleLogin,
                child: Text('Đăng nhập', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: Text('Chưa có tài khoản? Đăng ký ngay'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      bool success = await MongoService.loginUser(
        _usernameController.text,
        _passwordController.text,
      );
      if (success) {
        Navigator.pushReplacementNamed(context, '/products');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sai tên đăng nhập hoặc mật khẩu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng ký tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Tên đăng nhập',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                  if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _handleRegister,
                child: Text('Đăng ký'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      bool success = await MongoService.registerUser(
        _usernameController.text,
        _passwordController.text,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tên đăng nhập đã tồn tại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Map<String, dynamic>>> products;
  String searchQuery = "";

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
            child: Container(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      id == null ? "Thêm sản phẩm mới" : "Chỉnh sửa sản phẩm",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    
                    // Hiển thị ảnh preview
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: hinhAnhController.text.isEmpty
                          ? Center(
                              child: Icon(Icons.image, size: 50, color: Colors.grey),
                            )
                          : Image.file(
                              File(hinhAnhController.text),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                    ),
                    SizedBox(height: 15),
                    
                    // Nút chọn ảnh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.photo),
                          label: Text("Thư viện"),
                          onPressed: () async {
                            await pickImage(ImageSource.gallery, hinhAnhController);
                            setState(() {});
                          },
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.camera_alt),
                          label: Text("Máy ảnh"),
                          onPressed: () async {
                            await pickImage(ImageSource.camera, hinhAnhController);
                            setState(() {});
                          },
                        ),
                        if (hinhAnhController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              hinhAnhController.clear();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // Nhập thông tin sản phẩm
                    TextField(
                      controller: loaiSPController,
                      decoration: InputDecoration(
                        labelText: "Tên sản phẩm",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: giaController,
                      decoration: InputDecoration(
                        labelText: "Giá (VND)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 25),
                    
                    // Nút lưu/hủy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("HỦY", style: TextStyle(color: Colors.grey)),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            // Validate dữ liệu
                            if (loaiSPController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Vui lòng nhập tên sản phẩm")),
                              );
                              return;
                            }
                            
                            if (giaController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Vui lòng nhập giá sản phẩm")),
                              );
                              return;
                            }
                            
                            double? parsedGia = double.tryParse(giaController.text);
                            if (parsedGia == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Giá sản phẩm phải là số")),
                              );
                              return;
                            }
                            
                            // Xử lý lưu dữ liệu
                            bool success;
                            if (id == null) {
                              // Thêm mới
                              success = await MongoService.addProduct(
                                DateTime.now().millisecondsSinceEpoch.toString(),
                                loaiSPController.text,
                                parsedGia,
                                hinhAnhController.text,
                              );
                            } else {
                              // Cập nhật
                              success = await MongoService.updateProduct(
                                id,
                                loaiSPController.text,
                                parsedGia,
                                hinhAnhController.text,
                              );
                            }
                            
                            if (success) {
                              Navigator.pop(context);
                              refreshProducts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(id == null 
                                    ? "Thêm sản phẩm thành công" 
                                    : "Cập nhật sản phẩm thành công"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Lỗi khi lưu sản phẩm"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text(id == null ? "THÊM" : "LƯU"),
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildImageField(TextEditingController controller, StateSetter setState) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.photo),
              label: Text("Thư viện"),
              onPressed: () async => await pickImage(ImageSource.gallery, controller),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text("Máy ảnh"),
              onPressed: () async => await pickImage(ImageSource.camera, controller),
            ),
          ],
        ),
        if (controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Image.file(File(controller.text), height: 100),
          ),
      ],
    );
  }

  Widget _buildActionButtons(
    String? id,
    TextEditingController loaiSP,
    TextEditingController gia,
    TextEditingController hinhAnh,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: () => _handleSaveProduct(id, loaiSP.text, gia.text, hinhAnh.text),
          child: Text(id == null ? "Thêm" : "Lưu"),
        ),
      ],
    );
  }

  void _handleSaveProduct(String? id, String loaiSP, String gia, String hinhAnh) async {
    if (loaiSP.isEmpty || gia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng điền đầy đủ thông tin"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double? parsedGia = double.tryParse(gia);
    if (parsedGia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Giá phải là số hợp lệ"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success;
    if (id == null) {
      success = await MongoService.addProduct(
        DateTime.now().millisecondsSinceEpoch.toString(),
        loaiSP,
        parsedGia,
        hinhAnh,
      );
    } else {
      success = await MongoService.updateProduct(id, loaiSP, parsedGia, hinhAnh);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý sản phẩm"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }
                
                final filteredProducts = (snapshot.data ?? []).where((product) {
                  return product['loaisp'].toString().toLowerCase().contains(searchQuery) ||
                      product['gia'].toString().contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ListTile(
                      leading: _buildProductImage(product['hinhanh']),
                      title: Text(product['loaisp']),
                      subtitle: Text("Giá: ${product['gia'].toStringAsFixed(0)} VND"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => showProductDialog(
                              id: product['idsanpham'],
                              loaiSP: product['loaisp'],
                              gia: product['gia'].toDouble(),
                              hinhAnh: product['hinhanh'],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product['idsanpham']),
                          ),
                        ],
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
        child: Icon(Icons.add),
        onPressed: () => showProductDialog(),
      ),
    );
  }

  Widget _buildProductImage(String path) {
    return path.isEmpty
        ? Icon(Icons.image, size: 40)
        : Image.file(File(path), width: 40, height: 40);
  }

  void _deleteProduct(String id) async {
    bool success = await MongoService.deleteProduct(id);
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
  }
}