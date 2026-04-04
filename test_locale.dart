import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  try {
    await initializeDateFormatting('am', null);
    final date = DateTime.now();
    final formatted = DateFormat('EEEE, MMM d', 'am').format(date);
    print('Formatted date in Amharic: $formatted');
  } catch (e) {
    print('Error: $e');
  }
}
