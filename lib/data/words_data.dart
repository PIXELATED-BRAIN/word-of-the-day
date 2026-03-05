import '../models/daily_word.dart';

final List<DailyWord> localWords = [
  // General / Biblical
  DailyWord(
    word: 'ሰላም',
    pronunciation: 'Selam',
    translation: 'Peace / Hello',
    example: 'ሰላም ነው (Selam new) - Is it peace? (How are you?)',
    category: 'መጽሐፍ ቅዱሳዊ',
  ),
  DailyWord(
    word: 'እግዚአብሔር',
    pronunciation: 'Egziabeher',
    translation: 'God',
    example: 'እግዚአብሔር ይመስገን (Egziabeher yimesgen) - Thanks be to God.',
    category: 'መጽሐፍ ቅዱሳዊ',
  ),
  DailyWord(
    word: 'ሃሌሉያ',
    pronunciation: 'Halleluja',
    translation: 'Hallelujah',
    example: 'ሃሌሉያ ለአምላክ ይሁን (Halleluja leamlak yihun) - Hallelujah be to God.',
    category: 'መጽሐፍ ቅዱሳዊ',
  ),
  
  // Sayings
  DailyWord(
    word: 'ካላወቁበት አገር አይሄዱበት',
    pronunciation: 'kalawuqubet ager ayihedubet',
    translation: 'Don\'t go to a country you don\'t know about.',
    example: 'Proverb about being prepared.',
    category: 'አባባሎች',
  ),
  DailyWord(
    word: 'ካለሽን በመስጠት ደስ ይበልሽ',
    pronunciation: 'Kaleshin bemestet des yibelsh',
    translation: 'Be happy with what you give from what you have.',
    example: 'Proverb about generosity.',
    category: 'አባባሎች',
  ),
  DailyWord(
    word: 'ከመናገር በፊት ማሰብ',
    pronunciation: 'Kemenager befit maseb',
    translation: 'Think before you speak.',
    example: 'Think before you speak.',
    category: 'አባባሎች',
  ),
  
  // Names
  DailyWord(
    word: 'አበባ',
    pronunciation: 'Abeba',
    translation: 'Flower',
    example: 'አበባ ጥሩ ስም ነው (Abeba tiru sim new) - Abeba is a nice name.',
    category: 'ስሞች',
  ),
  DailyWord(
    word: 'ታደሰ',
    pronunciation: 'Tadesse',
    translation: 'Renewed',
    example: 'ታደሰ ጎበዝ ተማሪ ነው (Tadesse gobez temari new) - Tadesse is a clever student.',
    category: 'ስሞች',
  ),
  DailyWord(
    word: 'መሰረት',
    pronunciation: 'Meseret',
    translation: 'Foundation',
    example: 'መሰረት ጥሩ ጓደኛ ናት (Meseret tiru guadenya nat) - Meseret is a good friend.',
    category: 'ስሞች',
  ),

  // Objects
  DailyWord(
    word: 'መጽሐፍ',
    pronunciation: 'Metsihaf',
    translation: 'Book',
    example: 'መጽሐፉን እያነበብኩ ነው (Metsihafun iyanebebku new) - I am reading the book.',
    category: 'ቁሳቁሶች',
  ),
  DailyWord(
    word: 'ወንበር',
    pronunciation: 'Wember',
    translation: 'Chair',
    example: 'በወንበሩ ላይ ተቀመጥ (Bewemberu lay tekemet) - Sit on the chair.',
    category: 'ቁሳቁሶች',
  ),
  DailyWord(
    word: 'ጠረጴዛ',
    pronunciation: 'Terepeza',
    translation: 'Table',
    example: 'ምግቡ በጠረጴዛው ላይ ነው (Migbu beterepezaw lay new) - The food is on the table.',
    category: 'ቁሳቁሶች',
  ),

  // Plants & Animals
  DailyWord(
    word: 'አንበሳ',
    pronunciation: 'Anbessa',
    translation: 'Lion',
    example: 'አንበሳ የጫካ ንጉሥ ነው (Anbessa yechaka nigus new) - The lion is the king of the forest.',
    category: 'ዕፅዋት እና እንስሳት',
  ),
  DailyWord(
    word: 'ዝሆን',
    pronunciation: 'Zihon',
    translation: 'Elephant',
    example: 'ዝሆን ትልቅ እንስሳ ነው (Zihon tilik ensisa new) - The elephant is a big animal.',
    category: 'ዕፅዋት እና እንስሳት',
  ),
  DailyWord(
    word: 'ዛፍ',
    pronunciation: 'Zaf',
    translation: 'Tree',
    example: 'ዛፉ ረጅም ነው (Zafu rejim new) - The tree is tall.',
    category: 'ዕፅዋት እና እንስሳት',
  ),

  // Pronunciation
  DailyWord(
    word: 'ምሳ',
    pronunciation: 'Misa',
    translation: 'Lunch',
    example: 'ምሳ በላህ? (Misa belah?) - Did you eat lunch?',
    category: 'አጠራር',
  ),
  DailyWord(
    word: 'ቁርስ',
    pronunciation: 'Kurs',
    translation: 'Breakfast',
    example: 'ቁርስ በላሽ? (Kurs belash?) - Did you eat breakfast?',
    category: 'አጠራር',
  ),
  DailyWord(
    word: 'ራት',
    pronunciation: 'Rat',
    translation: 'Dinner',
    example: 'ራት መቼ ይቀርባል? (Rat meche yikerbal?) - When will dinner be served?',
    category: 'አጠራር',
  ),

  // Insults (Soft ones for the app example)
  DailyWord(
    word: 'ደደብ',
    pronunciation: 'Dedeb',
    translation: 'Stupid / Dull',
    example: 'እንደዚህ አትሁን (Indezih atihun) - Don\'t be like this.',
    category: 'ስድቦች',
  ),
  DailyWord(
    word: 'ጅል',
    pronunciation: 'Jil',
    translation: 'Foolish',
    example: 'አትጅል (Atijil) - Don\'t be foolish.',
    category: 'ስድቦች',
  ),
];
