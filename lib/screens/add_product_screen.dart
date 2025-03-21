// import 'package:flutter/material.dart';
// import '../services/mongo_database.dart';

// class AddProductScreen extends StatefulWidget {
//   @override
//   _AddProductScreenState createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController categoryController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//   String? imageUrl;

//   void addProduct() async {
//     var product = {
//       "tensanpham": nameController.text,
//       "loaisp": categoryController.text,
//       "gia": double.parse(priceController.text),
//       "hinhanh": imageUrl ?? "",
//     };

//     await MongoDatabase.productCollection.insertOne(product);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Thêm sản phẩm")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên sản phẩm")),
//             TextField(controller: categoryController, decoration: InputDecoration(labelText: "Loại sản phẩm")),
//             TextField(controller: priceController, decoration: InputDecoration(labelText: "Giá")),
//             SizedBox(height: 20),
//             ElevatedButton(onPressed: addProduct, child: Text("Thêm sản phẩm")),
//           ],
//         ),
//       ),
//     );
//   }
// }
