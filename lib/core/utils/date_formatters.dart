import 'package:intl/intl.dart';

class DateFormatters {
  const DateFormatters._();

  static final shortDate = DateFormat.yMMMd();
  static final dateTime = DateFormat.yMMMd().add_jm();
}
