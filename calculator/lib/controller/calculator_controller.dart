// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:math' as math;

class CalculatorController extends GetxController {
  final box = GetStorage();

  var inputExp = ''.obs;
  var result = ''.obs;
  var showResult = false.obs;
  var calculatorMode = 'basic'.obs;
  var history = <String>[].obs;
  var showHistory = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  void loadHistory() {
    try {
      List<dynamic>? saved = box.read("calc_history");
      if (saved != null) {
        history.assignAll(saved.map((e) => e.toString()).toList());
      }
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  void saveHistory() {
    try {
      box.write("calc_history", history.toList());
    } catch (e) {
      print("Error saving history: $e");
    }
  }

  void addInput(String value) {
    showResult.value = false;

    // Handle % button
    if (value == '%') {
      if (inputExp.value.isEmpty) return;

      // Get the last number (after last operator or start)
      int lastOpIndex = inputExp.value.lastIndexOf(RegExp(r'[+\-×÷(]'));
      String lastPart = lastOpIndex == -1
          ? inputExp.value
          : inputExp.value.substring(lastOpIndex + 1);

      // Remove any existing % or trailing dot
      lastPart = lastPart.replaceAll('%', '').trim();

      if (lastPart.isEmpty || !_isNumber(lastPart)) return;

      // Don't allow double %%
      if (inputExp.value.endsWith('%')) return;

      inputExp.value += '%';
      return;
    }

    const ops = '+-×÷';

    if (ops.contains(value)) {
      if (inputExp.value.isEmpty) {
        if (value == '-') inputExp.value = '-';
        return;
      }

      final last = inputExp.value[inputExp.value.length - 1];

      // Don't allow operator right after %
      if (last == '%') return;

      if (ops.contains(last)) {
        if (last == '-' && value == '-') return;
        inputExp.value =
            inputExp.value.substring(0, inputExp.value.length - 1) + value;
        return;
      }
    }

    if (value == '.') {
      int lastOp = inputExp.value.lastIndexOf(RegExp(r'[+\-×÷(√]'));
      String lastNumber = lastOp == -1
          ? inputExp.value
          : inputExp.value.substring(lastOp + 1);

      String clean = lastNumber.replaceAll('%', '');
      if (clean.contains('.')) return;
      if (clean.isEmpty) inputExp.value += '0';
    }

    inputExp.value += value;
  }

  void clear() {
    inputExp.value = "";
    result.value = "";
    showResult.value = false;
  }

  void clearHistory() {
    history.clear();
    saveHistory();
  }

  void deleteLastChar() {
    if (inputExp.value.isNotEmpty) {
      inputExp.value = inputExp.value.substring(0, inputExp.value.length - 1);
      showResult.value = false;
    }
  }

  void calculate() {
    try {
      String exp = inputExp.value.trim();
      if (exp.isEmpty) return;

      while (exp.isNotEmpty && RegExp(r'[+\-×÷]$').hasMatch(exp)) {
        exp = exp.substring(0, exp.length - 1);
      }
      exp = exp.trim();

      if (exp.isEmpty) return;

      exp = exp.replaceAll('×', '*').replaceAll('÷', '/');

      exp = _processPercent(exp);

      exp = _processNthRoot(exp);

      final tokens = _tokenize(exp);
      final rpn = _toRPN(tokens);
      final total = _evalRPN(rpn);

      result.value = _formatResult(total);
      showResult.value = true;

      String historyItem = "$inputExp = $result";
      history.insert(0, historyItem);
      if (history.length > 50) history.removeLast();
      saveHistory();
    } catch (e) {
      result.value = "Error";
      showResult.value = true;
    }
  }

  String _processPercent(String exp) {
    exp = exp.replaceAllMapped(RegExp(r'(\d+\.?\d*)\s*%'), (m) {
      return '(${m.group(1)}/100)';
    });

    exp = exp.replaceAllMapped(RegExp(r'([+\-×÷])\s*(\d+\.?\d*)\s*%'), (match) {
      String op = match.group(1)!;
      String num = match.group(2)!;

      String fullBefore = exp.substring(0, exp.indexOf(op, 0));
      RegExp lastNumRegex = RegExp(r'([\d\.]+)(?=\s*$)');
      String? baseNum = lastNumRegex.firstMatch(fullBefore)?.group(1);

      if (baseNum == null) return match.group(0)!; // fallback

      String mulOp = (op == '×')
          ? '*'
          : (op == '÷')
          ? '/'
          : '*';
      return '$op($baseNum$mulOp$num/100)';
    });

    return exp;
  }

  String _processNthRoot(String exp) {
    RegExp nthRootPattern = RegExp(r'(\d+\.?\d*)\s*√\s*([^√+\-×÷()]+)');
    exp = exp.replaceAllMapped(nthRootPattern, (match) {
      String root = match.group(1)!;
      String number = match.group(2)!.trim();
      return 'pow($number,1/$root)';
    });

    RegExp sqrtPattern = RegExp(r'√\s*([^√+\-×÷()]+)');
    exp = exp.replaceAllMapped(sqrtPattern, (match) {
      String number = match.group(1)!.trim();
      return 'pow($number,0.5)';
    });

    return exp;
  }

  void applyFunction(String func) {
    try {
      String exp = inputExp.value
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .trim();
      if (exp.isEmpty) return;

      double value = double.parse(exp);
      double res = 0;

      switch (func) {
        case 'sqrt':
          if (value < 0) throw Exception("Invalid input");
          res = math.sqrt(value);
          break;
        case 'sin':
          res = math.sin(value * math.pi / 180);
          break;
        case 'cos':
          res = math.cos(value * math.pi / 180);
          break;
        case 'tan':
          res = math.tan(value * math.pi / 180);
          break;
        case 'log':
          if (value <= 0) throw Exception("Invalid input");
          res = math.log(value) / math.log(10);
          break;
        case 'ln':
          if (value <= 0) throw Exception("Invalid input");
          res = math.log(value);
          break;
        case 'factorial':
          if (value < 0 || value != value.toInt()) {
            throw Exception("Only non-negative integers");
          }
          res = _factorial(value.toInt()).toDouble();
          break;
        case 'pow2':
          res = value * value;
          break;
        case 'pow3':
          res = value * value * value;
          break;
        case 'reciprocal':
          if (value == 0) throw Exception("Division by zero");
          res = 1 / value;
          break;
        case 'percent':
          res = value / 100;
          break;
        case 'abs':
          res = value.abs();
          break;
        default:
          throw Exception("Unknown function");
      }

      inputExp.value = _formatResult(res);
      result.value = "";
      showResult.value = false;

      String historyItem = "$func($value) = ${inputExp.value}";
      history.insert(0, historyItem);
      if (history.length > 50) history.removeLast();
      saveHistory();
    } catch (e) {
      result.value = "Error";
      showResult.value = true;
    }
  }

  String _formatResult(double value) {
    if (value.isNaN || value.isInfinite) return "Error";
    if (value == value.toInt()) return value.toInt().toString();

    String formatted = value.toStringAsFixed(10);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    if (formatted.endsWith('.'))
      formatted = formatted.substring(0, formatted.length - 1);
    return formatted.isEmpty ? "0" : formatted;
  }

  double _factorial(int n) {
    if (n < 0) throw Exception("Negative");
    if (n > 20) throw Exception("Too large");
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }

  List<String> _tokenize(String exp) {
    List<String> tokens = [];
    StringBuffer current = StringBuffer();
    final operators = '+-*/()';

    for (int i = 0; i < exp.length; i++) {
      final ch = exp[i];

      if (ch == ' ') continue;

      if (ch == '-' && (i == 0 || operators.contains(exp[i - 1]))) {
        current.write(ch);
        continue;
      }

      if (ch == '(' || ch == ')' || ch == ',') {
        if (current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
        }
        if (ch != ',') tokens.add(ch);
      } else if (operators.contains(ch) && ch != '-') {
        if (current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
        }
        tokens.add(ch);
      } else {
        current.write(ch);
      }
    }

    if (current.isNotEmpty) tokens.add(current.toString());

    return tokens;
  }

  List<String> _toRPN(List<String> tokens) {
    List<String> output = [];
    List<String> stack = [];

    Map<String, int> precedence = {'+': 1, '-': 1, '*': 2, '/': 2, 'pow': 3};

    for (String token in tokens) {
      if (_isNumber(token)) {
        output.add(token);
      } else if (token == 'pow') {
        stack.add(token);
      } else if (token == '(') {
        stack.add(token);
      } else if (token == ')') {
        while (stack.isNotEmpty && stack.last != '(') {
          output.add(stack.removeLast());
        }
        stack.removeLast();
      } else if (precedence.containsKey(token)) {
        while (stack.isNotEmpty &&
            stack.last != '(' &&
            precedence.containsKey(stack.last) &&
            precedence[stack.last]! >= precedence[token]!) {
          output.add(stack.removeLast());
        }
        stack.add(token);
      }
    }

    while (stack.isNotEmpty) {
      if (stack.last == '(') throw FormatException("Mismatched parentheses");
      output.add(stack.removeLast());
    }

    return output;
  }

  double _evalRPN(List<String> rpn) {
    List<double> stack = [];

    for (String token in rpn) {
      if (_isNumber(token)) {
        stack.add(double.parse(token));
      } else if (token == 'pow') {
        double exp = stack.removeLast();
        double base = stack.removeLast();
        stack.add(math.pow(base, exp).toDouble());
      } else {
        double b = stack.removeLast();
        double a = stack.removeLast();
        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) throw Exception("Division by zero");
            stack.add(a / b);
            break;
        }
      }
    }

    return stack.first;
  }

  bool _isNumber(String s) {
    return double.tryParse(s) != null;
  }
}
