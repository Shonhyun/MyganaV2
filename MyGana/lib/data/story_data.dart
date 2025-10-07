import 'package:nihongo_japanese_app/screens/story_screen.dart';

class StoryBeat {
  final String text;
  final String? speaker;
  final String background;
  final String? character;
  final CharacterPosition characterPosition;
  final Question? question;
  final String harukiExpression;

  StoryBeat({
    required this.text,
    this.speaker,
    required this.background,
    this.character,
    this.characterPosition = CharacterPosition.center,
    this.question,
    required this.harukiExpression,
  });
}

class Question {
  final String text;
  final List<String> options;
  final String correctAnswer;
  final String? customHint;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswer,
    this.customHint,
  });
}

// EASY MODE - Simplest questions with obvious answers
final List<StoryBeat> easyStoryBeats = [
  // Introduction
  StoryBeat(
    text:
        'Haruki is a high school student who suddenly gets transported to a mysterious academy where every person he meets tests his Kanji skills. If he passes all 10 trials, he can return home—stronger and wiser.',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),

  // Interaction 1: Sensei Aki
  StoryBeat(
    text:
        'Haruki wakes up in a classroom bathed in golden light. A kind-looking woman greets him.',
    background: 'Classroom (Inter1).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text: 'Welcome, Haruki. To move forward, you must understand the basics.',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What does this Kanji mean: 学 (がく)?',
      options: ['A. Tree', 'B. Study', 'C. Moon', 'D. Wind'],
      correctAnswer: 'B. Study',
      customHint: 'This Kanji is related to education and learning. Think about what you do in school.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 2: Yuto
  StoryBeat(
    text: 'Haruki meets a shy first-year named Yuto in the hallway.',
    background: 'Hallway (Inter2).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Yuto',
    text:
        'I always mix up the word for "student"... Can you help me figure it out?',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Sad).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text: '',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which word means "student"?',
      options: ['A. 先生', 'B. 学生', 'C. 水生', 'D. 車生'],
      correctAnswer: 'B. 学生',
      customHint: 'This word combines the Kanji for "study" (学) with "life" (生). Think about someone who studies.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 3: Hana
  StoryBeat(
    text: 'In the library, Haruki meets Hana surrounded by textbooks.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Hana',
    text:
        'I\'m writing a journal entry. Can you help me identify the word for "school"?',
    background: 'Library (Inter3).png',
    character: 'Hana (Delighted).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Library (Inter3).png',
    character: 'Hana (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'Which word means "school"?',
      options: ['A. 学校', 'B. 教室', 'C. 大学', 'D. 図書館'],
      correctAnswer: 'A. 学校',
      customHint: 'This word combines "study" (学) with "building" (校). It\'s where students go to learn.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 4: Kenta
  StoryBeat(
    text: 'Kenta jogs past Haruki on the school field.',
    background: 'Athletics Track (Inter4).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Kenta',
    text:
        'Every day I climb the hills near here. Do you know the Kanji for "mountain"?',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Choose the correct Kanji for "mountain":',
      options: ['A. 山', 'B. 川', 'C. 木', 'D. 田'],
      correctAnswer: 'A. 山',
      customHint: 'This Kanji looks like three peaks of a mountain. It\'s one of the simplest and most recognizable Kanji.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 5: Emi
  StoryBeat(
    text: 'Haruki sees Emi adjusting a sundial in the courtyard.',
    background: 'Courtyard (Inter5).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Emi',
    text: 'Time is precious. Do you know the Kanji that means "time"?',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Smug).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which Kanji means "time"?',
      options: ['A. 日', 'B. 年', 'C. 時', 'D. 分'],
      correctAnswer: 'C. 時',
      customHint: 'This Kanji combines "sun" (日) with "temple" (寺), representing the passage of time measured by the sun.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 6: Sota
  StoryBeat(
    text: 'Sota breathes fire on stage during a play rehearsal.',
    background: 'Stage (Inter6).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Sota',
    text: 'Fire is my favorite symbol. Can you pick the right Kanji for it?',
    background: 'Stage (Inter6).png',
    character: 'Sota (Laugh).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Stage (Inter6).png',
    character: 'Sota (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which one means "fire"?',
      options: ['A. 水', 'B. 火', 'C. 木', 'D. 石'],
      correctAnswer: 'B. 火',
      customHint: 'This Kanji represents flames dancing upward. It\'s one of the five basic elements.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 7: Nao
  StoryBeat(
    text: 'Nao dives into the pool with a splash.',
    background: 'Pool (Inter7).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Nao',
    text:
        'I love water. It flows like words in a sentence. Can you recognize it?',
    background: 'Pool (Inter7).png',
    character: 'Nao (Smile).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Pool (Inter7).png',
    character: 'Nao (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'What is the Kanji for "water"?',
      options: ['A. 火', 'B. 土', 'C. 水', 'D. 風'],
      correctAnswer: 'C. 水',
      customHint: 'This Kanji represents flowing water with streams. It\'s another of the five basic elements.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 8: Toshi
  StoryBeat(
    text: 'In the calligraphy room, Toshi shows Haruki a half-written scroll.',
    background: 'Arts Room (Inter8).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Toshi',
    text: 'Which word means "principal" of a school?',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Delighted).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which means "school principal"?',
      options: ['A. 学生', 'B. 校長', 'C. 先生', 'D. 学校'],
      correctAnswer: 'B. 校長',
      customHint: 'This word combines "school" (校) with "head/chief" (長). The principal is the head of the school.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 9: Mei
  StoryBeat(
    text: 'Mei greets Haruki with a bright smile in the study hall.',
    background: 'Student Council Room (Inter9).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text:
        'I want to be a university student one day. Do you know how to say that in Kanji?',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Smile2).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What is the correct phrase for "university student"?',
      options: ['A. 小学生', 'B. 大学生', 'C. 学生大', 'D. 高校生'],
      correctAnswer: 'B. 大学生',
      customHint: 'This combines "big" (大) with "student" (学生). University is considered "big school" in Japanese.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 10: Professor Hoshino
  StoryBeat(
    text: 'Haruki enters the final chamber, where an older professor awaits.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'To return to your world, you must master this final challenge. Form a complete and meaningful phrase.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Normal).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smirk).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which of the following means "Japanese language"?',
      options: ['A. 中国語', 'B. 英語', 'C. 日本語', 'D. 語日本'],
      correctAnswer: 'C. 日本語',
      customHint: 'This combines "Japan" (日本) with "language" (語). It\'s the language spoken in Japan.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Ending
  StoryBeat(
    text:
        'As Haruki answers the final question, the air around him shimmers with golden light. Professor Hoshino smiles and slowly closes the ancient book he had been holding.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'You\'ve done well, Haruki. You walked the path of the Kanji Seeker, not only memorizing characters—but understanding their meaning in life, through people, and through purpose.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'The ground beneath Haruki glows. One by one, all the people he met—Aki-sensei, Yuto, Hana, Kenta, Emi, Sota, Nao, Toshi, Mei—appear around him in a circle. They bow respectfully.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text:
        'Remember, Kanji is not just for tests. It\'s a mirror of culture, history, and identity.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Aki sensei (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'We\'ll always be part of your story, even when you go back.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Mei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'The characters begin to fade into glowing symbols, swirling around Haruki as the notebook reappears in his hands. A soft wind blows, carrying the sound of distant school bells.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'Haruki opens his eyes…\n\nHe\'s back in the real-world school library, sitting exactly where he first found the notebook. The mysterious title on the cover still reads "The Path of Characters," but now—there\'s a new inscription on the last page:\n\n"Those who seek meaning will always find it—in words, in people, in themselves."',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    text:
        'Haruki smiles, stands up, and looks out the window.\n\nFrom that day forward, he approaches his Kanji studies not as a chore—but as a journey.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'Congratulations! You\'ve completed your Kanji Journey with Haruki.\nBut remember—this is only the beginning of your own adventure in Japanese learning!',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
];

// NORMAL MODE - Original story with moderate difficulty
final List<StoryBeat> normalStoryBeats = [
  // Introduction
  StoryBeat(
    text:
        'Haruki is a high school student who suddenly gets transported to a mysterious academy where every person he meets tests his Kanji skills. If he passes all 10 trials, he can return home—stronger and wiser.',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),

  // Interaction 1: Sensei Aki
  StoryBeat(
    text:
        'Haruki wakes up in a classroom bathed in golden light. A kind-looking woman greets him.',
    background: 'Classroom (Inter1).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text: 'Welcome, Haruki. To move forward, you must understand the basics.',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What does this Kanji mean: 学 (がく)?',
      options: ['A. Tree', 'B. Study', 'C. Moon', 'D. Wind'],
      correctAnswer: 'B. Study',
      customHint: 'This Kanji represents the concept of learning and education. It\'s fundamental to understanding Japanese education.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 2: Yuto
  StoryBeat(
    text: 'Haruki meets a shy first-year named Yuto in the hallway.',
    background: 'Hallway (Inter2).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Yuto',
    text:
        'I always mix up the word for "student"... Can you help me figure it out?',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Sad).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text: '',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which Kanji completes this phrase: ___生 (student)?',
      options: ['A. 校', 'B. 学', 'C. 水', 'D. 本'],
      correctAnswer: 'B. 学',
      customHint: 'The Kanji for "study" (学) combined with "life" (生) creates the word for student. Think about what students do.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 3: Hana
  StoryBeat(
    text: 'In the library, Haruki meets Hana surrounded by textbooks.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Hana',
    text:
        'I\'m writing a journal entry. Can you help complete this sentence: わたしは ___校に行きます。 ("I go to school.")',
    background: 'Library (Inter3).png',
    character: 'Hana (Delighted).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Library (Inter3).png',
    character: 'Hana (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'Which word best completes the sentence?',
      options: ['A. 学', 'B. 校', 'C. 学校', 'D. 生'],
      correctAnswer: 'C. 学校',
      customHint: 'The complete word "school" (学校) combines "study" (学) and "building" (校). This is the standard term for school.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 4: Kenta
  StoryBeat(
    text: 'Kenta jogs past Haruki on the school field.',
    background: 'Athletics Track (Inter4).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Kenta',
    text:
        'Every day I climb the hills near here. Do you know the Kanji for "mountain"?',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Choose the correct Kanji for "mountain":',
      options: ['A. 山', 'B. 火', 'C. 木', 'D. 空'],
      correctAnswer: 'A. 山',
      customHint: 'This Kanji represents three mountain peaks. It\'s one of the most basic and recognizable Kanji characters.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 5: Emi
  StoryBeat(
    text: 'Haruki sees Emi adjusting a sundial in the courtyard.',
    background: 'Courtyard (Inter5).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Emi',
    text: 'Time is precious. Do you know the Kanji that means "time"?',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Smug).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which Kanji means "time"?',
      options: ['A. 日', 'B. 分', 'C. 時', 'D. 曜'],
      correctAnswer: 'C. 時',
      customHint: 'This Kanji combines "sun" (日) with "temple" (寺), representing time as measured by the sun\'s movement.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 6: Sota
  StoryBeat(
    text: 'Sota breathes fire on stage during a play rehearsal.',
    background: 'Stage (Inter6).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Sota',
    text: 'Fire is my favorite symbol. Can you pick the right Kanji for it?',
    background: 'Stage (Inter6).png',
    character: 'Sota (Laugh).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Stage (Inter6).png',
    character: 'Sota (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which one means "fire"?',
      options: ['A. 水', 'B. 火', 'C. 光', 'D. 石'],
      correctAnswer: 'B. 火',
      customHint: 'This Kanji represents flames rising upward. It\'s one of the five basic elements in Japanese philosophy.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 7: Nao
  StoryBeat(
    text: 'Nao dives into the pool with a splash.',
    background: 'Pool (Inter7).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Nao',
    text:
        'I love water. It flows like words in a sentence. Can you recognize it?',
    background: 'Pool (Inter7).png',
    character: 'Nao (Smile).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Pool (Inter7).png',
    character: 'Nao (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'What is the Kanji for "water"?',
      options: ['A. 雨', 'B. 氷', 'C. 水', 'D. 海'],
      correctAnswer: 'C. 水',
      customHint: 'This Kanji represents flowing water with streams. It\'s another of the five basic elements.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 8: Toshi
  StoryBeat(
    text: 'In the calligraphy room, Toshi shows Haruki a half-written scroll.',
    background: 'Arts Room (Inter8).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Toshi',
    text: 'I\'m writing "school principal". Which combination should I use?',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Delighted).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'Which Kanji pair means "school principal"?',
      options: ['A. 学生', 'B. 校長', 'C. 大学', 'D. 学本'],
      correctAnswer: 'B. 校長',
      customHint: 'This combines "school" (校) with "head/chief" (長). The principal is the head administrator of the school.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 9: Mei
  StoryBeat(
    text: 'Mei greets Haruki with a bright smile in the study hall.',
    background: 'Student Council Room (Inter9).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text:
        'I want to be a university student one day. Do you know how to say that in Kanji?',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Smile2).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What is the correct phrase for "university student"?',
      options: ['A. 高学校', 'B. 大学生', 'C. 学生大', 'D. 大高校生'],
      correctAnswer: 'B. 大学生',
      customHint: 'This combines "big" (大) with "student" (学生). University is considered "big school" compared to high school.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 10: Professor Hoshino
  StoryBeat(
    text: 'Haruki enters the final chamber, where an older professor awaits.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'To return to your world, you must master this final challenge. Form a complete and meaningful phrase.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Normal).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smirk).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'Which of the following means "Japanese language"?',
      options: ['A. 日語', 'B. 本日', 'C. 日本語', 'D. 語日'],
      correctAnswer: 'C. 日本語',
      customHint: 'This combines "Japan" (日本) with "language" (語). It\'s the official term for the Japanese language.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Ending (same as easy mode)
  StoryBeat(
    text:
        'As Haruki answers the final question, the air around him shimmers with golden light. Professor Hoshino smiles and slowly closes the ancient book he had been holding.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'You\'ve done well, Haruki. You walked the path of the Kanji Seeker, not only memorizing characters—but understanding their meaning in life, through people, and through purpose.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'The ground beneath Haruki glows. One by one, all the people he met—Aki-sensei, Yuto, Hana, Kenta, Emi, Sota, Nao, Toshi, Mei—appear around him in a circle. They bow respectfully.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text:
        'Remember, Kanji is not just for tests. It\'s a mirror of culture, history, and identity.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Aki sensei (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'We\'ll always be part of your story, even when you go back.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Mei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'The characters begin to fade into glowing symbols, swirling around Haruki as the notebook reappears in his hands. A soft wind blows, carrying the sound of distant school bells.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'Haruki opens his eyes…\n\nHe\'s back in the real-world school library, sitting exactly where he first found the notebook. The mysterious title on the cover still reads "The Path of Characters," but now—there\'s a new inscription on the last page:\n\n"Those who seek meaning will always find it—in words, in people, in themselves."',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    text:
        'Haruki smiles, stands up, and looks out the window.\n\nFrom that day forward, he approaches his Kanji studies not as a chore—but as a journey.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'Congratulations! You\'ve completed your Kanji Journey with Haruki.\nBut remember—this is only the beginning of your own adventure in Japanese learning!',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
];

// HARD MODE - More complex questions with challenging options
final List<StoryBeat> hardStoryBeats = [
  // Introduction
  StoryBeat(
    text:
        'Haruki is a high school student who suddenly gets transported to a mysterious academy where every person he meets tests his Kanji skills. If he passes all 10 trials, he can return home—stronger and wiser.',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),

  // Interaction 1: Sensei Aki
  StoryBeat(
    text:
        'Haruki wakes up in a classroom bathed in golden light. A kind-looking woman greets him.',
    background: 'Classroom (Inter1).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text: '学びの旅へようこそ、春樹さん。前に進むためには、基本を理解しなければなりません。',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Classroom (Inter1).png',
    character: 'Aki sensei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'In the phrase 「学びの旅」(manabi no tabi), what does 学び mean?',
      options: ['A. To travel', 'B. To teach', 'C. To learn', 'D. To write'],
      correctAnswer: 'C. To learn',
      customHint: '学び is the noun form of 学ぶ (to learn). In this context, it means "learning" or "study" as a journey.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 2: Yuto
  StoryBeat(
    text: 'Haruki meets a shy first-year named Yuto in the hallway.',
    background: 'Hallway (Inter2).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Yuto',
    text: '私は学生ですが、「学」と「生」の漢字の意味をいつも混同してしまいます。助けてくれますか？',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Sad).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text: '',
    background: 'Hallway (Inter2).png',
    character: 'Yuto (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'What is the correct meaning of the compound 学生 (gakusei)?',
      options: [
        'A. Someone who studies life',
        'B. A student',
        'C. A teacher',
        'D. School life'
      ],
      correctAnswer: 'B. A student',
      customHint: '学生 combines "study" (学) with "life" (生) to mean "student" - someone whose life is dedicated to studying.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 3: Hana
  StoryBeat(
    text: 'In the library, Haruki meets Hana surrounded by textbooks.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Hana',
    text: '日記を書いています。この文章を完成させるのを手伝ってくれますか？「私は毎日＿＿＿に行きます。」',
    background: 'Library (Inter3).png',
    character: 'Hana (Delighted).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Library (Inter3).png',
    character: 'Hana (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text:
          'Which would be most natural to complete "私は毎日＿＿＿に行きます。" (I go to ___ every day)?',
      options: ['A. 大学校', 'B. 学校', 'C. 公園校', 'D. 図校'],
      correctAnswer: 'B. 学校',
      customHint: '学校 is the standard compound word for "school" combining "study" (学) and "building" (校).',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 4: Kenta
  StoryBeat(
    text: 'Kenta jogs past Haruki on the school field.',
    background: 'Athletics Track (Inter4).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Kenta',
    text: '毎日、近くの山を登っています。山と川、どちらの漢字がより複雑だと思いますか？',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Athletics Track (Inter4).png',
    character: 'Kenta (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'In the compound 山川 (yamagawa), which meaning is correct?',
      options: [
        'A. Mountains and rivers',
        'B. A mountain river',
        'C. A person\'s name',
        'D. A mountain range'
      ],
      correctAnswer: 'A. Mountains and rivers',
      customHint: '山川 combines "mountain" (山) and "river" (川) to mean "mountains and rivers" - representing natural landscapes.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 5: Emi
  StoryBeat(
    text: 'Haruki sees Emi adjusting a sundial in the courtyard.',
    background: 'Courtyard (Inter5).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Emi',
    text: '時は貴重です。「時間」と「時計」の違いは何ですか？',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Smug).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Courtyard (Inter5).png',
    character: 'Emi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'What is the difference between 時間 (jikan) and 時計 (tokei)?',
      options: [
        'A. 時間 means clock and 時計 means time',
        'B. 時間 means time and 時計 means clock',
        'C. They are synonyms with no difference',
        'D. 時間 is used only for past time, 時計 for future time'
      ],
      correctAnswer: 'B. 時間 means time and 時計 means clock',
      customHint: '時間 combines "time" (時) with "interval" (間) to mean "time period". 時計 combines "time" (時) with "measure" (計) to mean "clock".',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 6: Sota
  StoryBeat(
    text: 'Sota breathes fire on stage during a play rehearsal.',
    background: 'Stage (Inter6).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Sota',
    text: '火は私のお気に入りのシンボルです。「火山」という言葉の意味は何ですか？',
    background: 'Stage (Inter6).png',
    character: 'Sota (Laugh).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Laugh).png',
  ),
  StoryBeat(
    text: '',
    background: 'Stage (Inter6).png',
    character: 'Sota (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What does the compound 火山 (kazan) mean?',
      options: [
        'A. Fire mountain (volcano)',
        'B. Forest fire',
        'C. Burning tree',
        'D. Campfire'
      ],
      correctAnswer: 'A. Fire mountain (volcano)',
      customHint: '火山 literally means "fire mountain" - combining "fire" (火) and "mountain" (山) to create the word for volcano.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 7: Nao
  StoryBeat(
    text: 'Nao dives into the pool with a splash.',
    background: 'Pool (Inter7).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Nao',
    text: '水が大好きです。文章の中の言葉のように流れます。この漢字「泳」の意味は何ですか？',
    background: 'Pool (Inter7).png',
    character: 'Nao (Smile).png',
    characterPosition: CharacterPosition.left,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Pool (Inter7).png',
    character: 'Nao (Normal).png',
    characterPosition: CharacterPosition.left,
    question: Question(
      text: 'What does the Kanji 泳 in 水泳 (suiei) mean?',
      options: ['A. To drink', 'B. To swim', 'C. To wash', 'D. To flow'],
      correctAnswer: 'B. To swim',
      customHint: '泳 means "to swim" and combines with 水 (water) to form 水泳 (swimming). The character represents movement through water.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 8: Toshi
  StoryBeat(
    text: 'In the calligraphy room, Toshi shows Haruki a half-written scroll.',
    background: 'Arts Room (Inter8).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Toshi',
    text: '「校長先生」と書いています。「長」の意味は何ですか？',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Delighted).png',
    characterPosition: CharacterPosition.right,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Arts Room (Inter8).png',
    character: 'Toshi (Normal).png',
    characterPosition: CharacterPosition.right,
    question: Question(
      text: 'In the phrase 校長先生 (kouchou sensei), what does 長 mean?',
      options: ['A. Old', 'B. Long', 'C. Head/Chief', 'D. Teacher'],
      correctAnswer: 'C. Head/Chief',
      customHint: '長 means "head" or "chief" in this context. 校長先生 means "principal teacher" - the head of the school.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 9: Mei
  StoryBeat(
    text: 'Mei greets Haruki with a bright smile in the study hall.',
    background: 'Student Council Room (Inter9).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'いつか大学生になりたいです。「大学院生」という言葉の意味は何ですか？',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Smile2).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile).png',
  ),
  StoryBeat(
    text: '',
    background: 'Student Council Room (Inter9).png',
    character: 'Mei (Normal).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text: 'What does 大学院生 (daigakuinsei) mean compared to 大学生 (daigakusei)?',
      options: [
        'A. High school student vs. university student',
        'B. University student vs. graduate student',
        'C. Elementary student vs. university student',
        'D. First-year student vs. senior student'
      ],
      correctAnswer: 'B. University student vs. graduate student',
      customHint: '大学生 means "university student" while 大学院生 means "graduate student" - someone studying at the graduate level.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Interaction 10: Professor Hoshino
  StoryBeat(
    text: 'Haruki enters the final chamber, where an older professor awaits.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text: 'あなたの世界に帰るためには、この最後の挑戦をマスターする必要があります。意味のある文章を作りなさい。',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Normal).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    text: '',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smirk).png',
    characterPosition: CharacterPosition.center,
    question: Question(
      text:
          'Which of these phrases correctly means "I am studying Japanese at university"?',
      options: [
        'A. 私は大学で日本語を勉強しています',
        'B. 私は日本語で大学を勉強しています',
        'C. 私は勉強で日本語を大学しています',
        'D. 私は大学を日本語で勉強しています'
      ],
      correctAnswer: 'A. 私は大学で日本語を勉強しています',
      customHint: 'The correct word order is: Subject (私) + Location (大学で) + Object (日本語を) + Verb (勉強しています). で indicates the location where the action takes place.',
    ),
    harukiExpression: 'Haruki (Normal).png',
  ),

  // Ending (same as other modes)
  StoryBeat(
    text:
        'As Haruki answers the final question, the air around him shimmers with golden light. Professor Hoshino smiles and slowly closes the ancient book he had been holding.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
  StoryBeat(
    speaker: 'Professor Hoshino',
    text:
        'You\'ve done well, Haruki. You walked the path of the Kanji Seeker, not only memorizing characters—but understanding their meaning in life, through people, and through purpose.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Prof Hoshino (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'The ground beneath Haruki glows. One by one, all the people he met—Aki-sensei, Yuto, Hana, Kenta, Emi, Sota, Nao, Toshi, Mei—appear around him in a circle. They bow respectfully.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    speaker: 'Aki-sensei',
    text:
        'Remember, Kanji is not just for tests. It\'s a mirror of culture, history, and identity.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Aki sensei (Smile).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Normal).png',
  ),
  StoryBeat(
    speaker: 'Mei',
    text: 'We\'ll always be part of your story, even when you go back.',
    background: 'Principal\'s Office (Inter10).png',
    character: 'Mei (Delighted).png',
    characterPosition: CharacterPosition.center,
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'The characters begin to fade into glowing symbols, swirling around Haruki as the notebook reappears in his hands. A soft wind blows, carrying the sound of distant school bells.',
    background: 'Principal\'s Office (Inter10).png',
    harukiExpression: 'Haruki (Sad).png',
  ),
  StoryBeat(
    text:
        'Haruki opens his eyes…\n\nHe\'s back in the real-world school library, sitting exactly where he first found the notebook. The mysterious title on the cover still reads "The Path of Characters," but now—there\'s a new inscription on the last page:\n\n"Those who seek meaning will always find it—in words, in people, in themselves."',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Surprised).png',
  ),
  StoryBeat(
    text:
        'Haruki smiles, stands up, and looks out the window.\n\nFrom that day forward, he approaches his Kanji studies not as a chore—but as a journey.',
    background: 'Library (Inter3).png',
    harukiExpression: 'Haruki (Smile2).png',
  ),
  StoryBeat(
    text:
        'Congratulations! You\'ve completed your Kanji Journey with Haruki.\nBut remember—this is only the beginning of your own adventure in Japanese learning!',
    background: 'Gate (Intro).png',
    harukiExpression: 'Haruki (Smile1).png',
  ),
];