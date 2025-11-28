import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controller/calculator_controller.dart';

class HistoryScreen extends StatelessWidget {
  final CalculatorController c = Get.find();

  HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "History",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              HapticFeedback.lightImpact();
              c.clearHistory();
            },
          ),
        ],
      ),

      body: Obx(
        () => c.history.isEmpty
            ? Center(
                child: Text(
                  "No history",
                  style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                ),
              )
            : ListView.builder(
                itemCount: c.history.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      c.history[index],
                      style: TextStyle(color: Colors.black, fontSize: 20.sp),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      c.inputExp.value = c.history[index].split(" = ")[0];
                      c.showResult.value = false;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
      ),
    );
  }
}
