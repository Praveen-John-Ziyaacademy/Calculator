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
    List<dynamic>? saved = box.read("calc_history");

    if (saved != null) {
      history.assignAll(saved.map((e) => e.toString()).toList());
    }
  }

  void saveHistory() {
    box.write("calc_history", history.toList());
  }

  void addInput(String value) {
    showResult.value = false;

    const ops = '+-×÷';

    if (ops.contains(value)) {
      if (inputExp.value.isEmpty) {
        if (value == '-') inputExp.value = '-';
        return;
      }

      final last = inputExp.value[inputExp.value.length - 1];

      if (ops.contains(last)) {
        if (last == '-' && value == '-') return;

        inputExp.value =
            inputExp.value.substring(0, inputExp.value.length - 1) + value;
        return;
      }
    }

    if (value == '.') {
      int lastOp = inputExp.value.lastIndexOf(RegExp(r'[+\-×÷(]'));
      String lastNumber = lastOp == -1
          ? inputExp.value
          : inputExp.value.substring(lastOp + 1);
      if (lastNumber.contains('.')) {
        return;
      }
      if (lastNumber.isEmpty) {
        inputExp.value += '0';
      }
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
    }
  }

  void calculate() {
    try {
      String exp = inputExp.value.trim();
      if (exp.isEmpty) return;

      while (exp.isNotEmpty && RegExp(r'[+\-×÷*/]$').hasMatch(exp)) {
        exp = exp.substring(0, exp.length - 1);
      }

      if (exp.isEmpty) return;

      exp = exp.replaceAll('×', '*').replaceAll('÷', '/');

      final tokens = _tokenize(exp);
      final rpn = _toRPN(tokens);
      final total = _evalRPN(rpn);

      result.value = _formatResult(total);
      showResult.value = true;

      String historyItem = "${inputExp.value} = ${result.value}";
      history.insert(0, historyItem);
      if (history.length > 50) history.removeLast();

      saveHistory(); // 🔥 auto save
    } catch (e) {
      result.value = "Error";
      showResult.value = true;
    }
  }

  void applyFunction(String func) {
    try {
      String exp = inputExp.value
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .trim();
      if (exp.isEmpty) {
        return;
      }

      double value = double.parse(exp);
      double res = 0;

      switch (func) {
        case 'sqrt':
          if (value < 0) throw Exception("Negative square root");
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
          if (value <= 0) throw Exception("Invalid log input");
          res = math.log(value) / math.log(10);
          break;
        case 'ln':
          if (value <= 0) throw Exception("Invalid ln input");
          res = math.log(value);
          break;
        case 'factorial':
          if (value < 0 || value != value.toInt()) {
            throw Exception("Invalid factorial input");
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
      }

      inputExp.value = _formatResult(res);
      result.value = "";
      showResult.value = false;

      String historyItem = "$func($value) = ${inputExp.value}";
      history.insert(0, historyItem);
      if (history.length > 50) history.removeLast();

      saveHistory(); // 🔥 save
    } catch (e) {
      result.value = "Error";
      showResult.value = true;
    }
  }

  String _formatResult(double value) {
    if (value.isNaN || value.isInfinite) {
      return "Error";
    }

    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    String formatted = value.toStringAsFixed(10);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    return formatted;
  }

  double _factorial(int n) {
    if (n < 0) throw Exception("Negative factorial");
    if (n > 20) throw Exception("Factorial too large");
    if (n == 0 || n == 1) return 1;
    return n * _factorial(n - 1);
  }

  List<String> _tokenize(String exp) {
    List<String> tokens = [];
    StringBuffer current = StringBuffer();
    final operators = '+-*/';

    for (int i = 0; i < exp.length; i++) {
      final ch = exp[i];

      if (ch == '-') {
        if (i == 0 || operators.contains(exp[i - 1]) || exp[i - 1] == '(') {
          current.write(ch);
          continue;
        }
      }

      if (ch == '(' || ch == ')') {
        if (current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
        }
        tokens.add(ch);
      } else if (operators.contains(ch)) {
        if (current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
        }
        tokens.add(ch);
      } else if (ch == ' ') {
        if (current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
        }
      } else {
        current.write(ch);
      }
    }

    if (current.isNotEmpty) {
      tokens.add(current.toString());
    }

    return tokens;
  }

  List<String> _toRPN(List<String> tokens) {
    List<String> outputQueue = [];
    List<String> opStack = [];

    Map<String, int> precedence = {'+': 1, '-': 1, '*': 2, '/': 2};
    Map<String, bool> rightAssociative = {
      '+': false,
      '-': false,
      '*': false,
      '/': false,
    };

    for (final token in tokens) {
      if (_isNumber(token)) {
        outputQueue.add(token);
      } else if (token == '(') {
        opStack.add(token);
      } else if (token == ')') {
        while (opStack.isNotEmpty && opStack.last != '(') {
          outputQueue.add(opStack.removeLast());
        }
        if (opStack.isNotEmpty) {
          opStack.removeLast();
        }
      } else if (precedence.containsKey(token)) {
        while (opStack.isNotEmpty &&
            opStack.last != '(' &&
            precedence.containsKey(opStack.last) &&
            (precedence[opStack.last]! > precedence[token]! ||
                (precedence[opStack.last] == precedence[token] &&
                    !rightAssociative[token]!))) {
          outputQueue.add(opStack.removeLast());
        }
        opStack.add(token);
      }
    }

    while (opStack.isNotEmpty) {
      outputQueue.add(opStack.removeLast());
    }

    return outputQueue;
  }

  double _evalRPN(List<String> rpn) {
    List<double> stack = [];

    for (final token in rpn) {
      if (_isNumber(token)) {
        stack.add(double.parse(token));
      } else {
        if (stack.length < 2) {
          throw FormatException("Invalid expression");
        }
        double b = stack.removeLast();
        double a = stack.removeLast();
        double res;

        switch (token) {
          case '+':
            res = a + b;
            break;
          case '-':
            res = a - b;
            break;
          case '*':
            res = a * b;
            break;
          case '/':
            if (b == 0) throw Exception("Division by zero");
            res = a / b;
            break;
          default:
            throw FormatException("Unknown operator: $token");
        }

        stack.add(res);
      }
    }

    if (stack.length != 1) {
      throw FormatException("Invalid expression");
    }

    return stack.first;
  }

  bool _isNumber(String s) {
    return double.tryParse(s) != null;
  }
}
