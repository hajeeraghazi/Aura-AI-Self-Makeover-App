import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final List<String> products;

  const ProductCard({super.key, required this.title, required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2)],
                ),
                child: Center(child: Text(products[index], textAlign: TextAlign.center)),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
