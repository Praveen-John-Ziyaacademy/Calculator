// ignore_for_file: deprecated_member_use

import 'package:calculator/comp/tap_animation.dart';
import 'package:calculator/controller/calculator_controller.dart';
import 'package:calculator/view/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _modeAnimationController;

  @override
  void initState() {
    super.initState();
    _modeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _modeAnimationController.dispose();
    super.dispose();
  }

  void _switchMode(CalculatorController c) {
    HapticFeedback.mediumImpact();
    if (c.calculatorMode.value == 'basic') {
      c.calculatorMode.value = 'scientific';
      _modeAnimationController.forward();
    } else {
      c.calculatorMode.value = 'basic';
      _modeAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CalculatorController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (c.showHistory.value) {
          return _buildHistory(c);
        }
        return _buildCalculator(c);
      }),
    );
  }

  Widget _buildCalculator(CalculatorController c) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: []),
                      PopupMenuButton<int>(
                        offset: Offset(0.w, 35.h),
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        shadowColor: Colors.black12,
                        icon: const Icon(Icons.more_vert, color: Colors.black),
                        onSelected: (value) {
                          if (value == 1) {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HistoryScreen(),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            height: 25.h,
                            value: 1,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Colors.black54,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  "History",
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 120.h,
                          child: SingleChildScrollView(
                            reverse: true,
                            child: SingleChildScrollView(
                              reverse: true,
                              scrollDirection: Axis.horizontal,
                              child: Obx(
                                () => Text(
                                  c.inputExp.value,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Obx(
                          () => SingleChildScrollView(
                            reverse: true,
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              c.result.value.isEmpty ? "0" : c.result.value,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 48.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => c.calculatorMode.value == 'basic'
                        ? _buildBasicButtons(c)
                        : _buildScientificButtons(c),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicButtons(CalculatorController c) {
    double spacing = 10.w;

    return Padding(
      padding: EdgeInsets.all(14.w),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
        children: [
          _buildButtonSized("AC", Colors.orange, () => c.clear(), 0),
          _buildButtonSized("⌫", Colors.orange, () => c.deleteLastChar(), 0),
          _buildButtonSized(
            "%",
            Colors.orange,
            () => c.applyFunction('percent'),
            0,
          ),
          _buildButtonLargeSized("÷", Colors.orange, () => c.addInput("÷"), 0),
          _buildButtonSized("7", Colors.black, () => c.addInput("7"), 0),
          _buildButtonSized("8", Colors.black, () => c.addInput("8"), 0),
          _buildButtonSized("9", Colors.black, () => c.addInput("9"), 0),
          _buildButtonLargeSized("×", Colors.orange, () => c.addInput("×"), 0),
          _buildButtonSized("4", Colors.black, () => c.addInput("4"), 0),
          _buildButtonSized("5", Colors.black, () => c.addInput("5"), 0),
          _buildButtonSized("6", Colors.black, () => c.addInput("6"), 0),
          _buildButtonLargeSized("-", Colors.orange, () => c.addInput("-"), 0),
          _buildButtonSized("1", Colors.black, () => c.addInput("1"), 0),
          _buildButtonSized("2", Colors.black, () => c.addInput("2"), 0),
          _buildButtonSized("3", Colors.black, () => c.addInput("3"), 0),
          _buildButtonLargeSized("+", Colors.orange, () => c.addInput("+"), 0),
          _buildButtonSized("0", Colors.black, () => c.addInput("0"), 0),
          _buildButtonSized(".", Colors.black, () => c.addInput("."), 0),
          _buildButtonLargeSized("=", Colors.green, () => c.calculate(), 0),
          TapAnimationButton(
            onTap: () => _switchMode(c),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: const Center(
                child: Icon(Icons.swap_horiz_sharp, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScientificButtons(CalculatorController c) {
    double spacing = 10.w;

    List<Widget> sciButtons = [
      _buildButtonSized("sin", Colors.blue, () => c.applyFunction('sin'), 0),
      _buildButtonSized("cos", Colors.blue, () => c.applyFunction('cos'), 0),
      _buildButtonSized("tan", Colors.blue, () => c.applyFunction('tan'), 0),
      _buildButtonSized("√x", Colors.blue, () => c.addInput("√"), 0),
      _buildButtonSized("x²", Colors.blue, () => c.applyFunction('pow2'), 0),
      _buildButtonSized("log", Colors.blue, () => c.applyFunction('log'), 0),
      _buildButtonSized("ln", Colors.blue, () => c.applyFunction('ln'), 0),
      _buildButtonSized(
        "x!",
        Colors.blue,
        () => c.applyFunction('factorial'),
        0,
      ),
      _buildButtonSized(
        "1/x",
        Colors.blue,
        () => c.applyFunction('reciprocal'),
        0,
      ),
      _buildButtonSized("x³", Colors.blue, () => c.applyFunction('pow3'), 0),
      _buildButtonSized("π", Colors.grey, () => c.addInput("3.14159265"), 0),
      _buildButtonSized("e", Colors.grey, () => c.addInput("2.71828182"), 0),
      _buildButtonSized("(", Colors.grey, () => c.addInput("("), 0),
      _buildButtonSized(")", Colors.grey, () => c.addInput(")"), 0),
      _buildButtonSized("|x|", Colors.blue, () => c.applyFunction('abs'), 0),
      _buildButtonSized("AC", Colors.orange, () => c.clear(), 0),
      _buildButtonSized("⌫", Colors.orange, () => c.deleteLastChar(), 0),
      _buildButtonSized(
        "%",
        Colors.orange,
        () => c.applyFunction('percent'),
        0,
      ),
      _buildButtonLargeSized("÷", Colors.orange, () => c.addInput("÷"), 0),
      _buildButtonLargeSized("×", Colors.orange, () => c.addInput("×"), 0),
      _buildButtonSized("1", Colors.black, () => c.addInput("1"), 0),
      _buildButtonSized("2", Colors.black, () => c.addInput("2"), 0),
      _buildButtonSized("3", Colors.black, () => c.addInput("3"), 0),
      _buildButtonSized("4", Colors.black, () => c.addInput("4"), 0),
      _buildButtonLargeSized("-", Colors.orange, () => c.addInput("-"), 0),
      _buildButtonSized("8", Colors.black, () => c.addInput("8"), 0),
      _buildButtonSized("7", Colors.black, () => c.addInput("7"), 0),
      _buildButtonSized("6", Colors.black, () => c.addInput("6"), 0),
      _buildButtonSized("5", Colors.black, () => c.addInput("5"), 0),
      _buildButtonLargeSized("+", Colors.orange, () => c.addInput("+"), 0),
      _buildButtonSized("9", Colors.black, () => c.addInput("9"), 0),
      _buildButtonSized("0", Colors.black, () => c.addInput("0"), 0),
      _buildButtonSized(".", Colors.black, () => c.addInput("."), 0),
      _buildButtonLargeSized("=", Colors.green, () => c.calculate(), 0),
      TapAnimationButton(
        onTap: () => _switchMode(c),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: const Center(
            child: Icon(Icons.swap_horiz_sharp, color: Colors.white),
          ),
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.all(14.w),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 5,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1,
        children: sciButtons,
      ),
    );
  }

  Widget _buildHistory(CalculatorController c) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "History",
                style: TextStyle(color: Colors.black, fontSize: 18.sp),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      c.clearHistory();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      c.showHistory.value = false;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(
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
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp,
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          c.inputExp.value = c.history[index].split(" = ")[0];
                          c.showResult.value = false;
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtonSized(
    String label,
    Color textColor,
    VoidCallback onTap,
    double height,
  ) {
    return TapAnimationButton(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonLargeSized(
    String label,
    Color color,
    VoidCallback onTap,
    double height,
  ) {
    return TapAnimationButton(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
