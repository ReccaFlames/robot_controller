class RollAverage {

  static const int MAX_SAMPLE_SIZE = 3;
  List<double> list = <double>[];

  calculate(double newValue) {
    return _averageList(_roll(newValue));
  }

  List<double> _roll(double newValue) {
    if (list == null) {
      return list;
    }
    if (list.length == MAX_SAMPLE_SIZE) {
      list.removeAt(0);
    }
    list.add(newValue);
    return list;
  }

  double _averageList(List<double> tallyUp) {
    if (tallyUp == null) {
      return 0.0;
    }
    double total = tallyUp.reduce((a, b) => a + b);
    return total / tallyUp.length;
  }
}