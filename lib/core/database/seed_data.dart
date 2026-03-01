import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

Future<void> insertSeedData(Database db) async {
  const uuid = Uuid();

  final categoryId = uuid.v4();
  final subjectId = uuid.v4();

  await db.transaction((txn) async {
    // 1. Insert Categories
    await txn.insert('categories', {
      'id': categoryId,
      'name': 'History',
      'accent_color': '#FF9800', // Orange color for History
      'icon_name': 'history',
    });

    final animeCatId = uuid.v4();
    await txn.insert('categories', {
      'id': animeCatId,
      'name': 'Anime',
      'accent_color': '#E91E63', // Pink
      'icon_name': 'movie_filter_rounded',
    });

    final moviesCatId = uuid.v4();
    await txn.insert('categories', {
      'id': moviesCatId,
      'name': 'Movies',
      'accent_color': '#9C27B0', // Purple
      'icon_name': 'theaters_rounded',
    });

    // 2. Insert Subjects
    await txn.insert('subjects', {
      'id': subjectId,
      'category_id': categoryId,
      'name': 'World History',
      'description':
          'Test your knowledge of major historical events and figures.'
    });

    final animeSubId = uuid.v4();
    await txn.insert('subjects', {
      'id': animeSubId,
      'category_id': animeCatId,
      'name': 'Shonen Classics',
      'description':
          'How well do you know the most popular action anime of all time?'
    });

    final moviesSubId = uuid.v4();
    await txn.insert('subjects', {
      'id': moviesSubId,
      'category_id': moviesCatId,
      'name': 'Sci-Fi Blockbusters',
      'description':
          'A trivia challenge on the biggest sci-fi and action theater hits.'
    });

    // 3. Insert Questions (History)
    final historyQuestions = [
      {
        'text': 'Who was the first President of the United States?',
        'options': [
          'George Washington',
          'Thomas Jefferson',
          'Abraham Lincoln',
          'John Adams'
        ],
        'answer': 0
      },
      {
        'text': 'In what year did World War II end?',
        'options': ['1943', '1945', '1950', '1939'],
        'answer': 1
      },
      {
        'text': 'Which empire was ruled by Julius Caesar?',
        'options': [
          'Ottoman Empire',
          'Roman Empire',
          'Mongol Empire',
          'British Empire'
        ],
        'answer': 1
      },
      {
        'text': 'Who discovered the sea route to India in 1498?',
        'options': [
          'Christopher Columbus',
          'Ferdinand Magellan',
          'Vasco da Gama',
          'Marco Polo'
        ],
        'answer': 2
      },
      {
        'text':
            'What was the name of the ship that brought the Pilgrims to America in 1620?',
        'options': ['Santa Maria', 'Mayflower', 'Endeavour', 'Victoria'],
        'answer': 1
      },
      {
        'text':
            'Who was the British Prime Minister during most of World War II?',
        'options': [
          'Neville Chamberlain',
          'Winston Churchill',
          'Clement Attlee',
          'Margaret Thatcher'
        ],
        'answer': 1
      },
      {
        'text': 'Which ancient civilization built the Machu Picchu?',
        'options': ['Aztecs', 'Mayans', 'Incas', 'Olmecs'],
        'answer': 2
      },
      {
        'text': 'Who painted the Mona Lisa?',
        'options': [
          'Michelangelo',
          'Vincent van Gogh',
          'Leonardo da Vinci',
          'Pablo Picasso'
        ],
        'answer': 2
      },
      {
        'text': 'In which year did the Titanic sink?',
        'options': ['1910', '1912', '1915', '1905'],
        'answer': 1
      },
      {
        'text':
            'Which country gifted the Statue of Liberty to the United States?',
        'options': ['Spain', 'France', 'United Kingdom', 'Italy'],
        'answer': 1
      },
      {
        'text': 'Who was the first person to walk on the moon?',
        'options': [
          'Yuri Gagarin',
          'Buzz Aldrin',
          'Neil Armstrong',
          'Michael Collins'
        ],
        'answer': 2
      },
      {
        'text': 'What was the longest war in U.S. history?',
        'options': [
          'Vietnam War',
          'Civil War',
          'World War II',
          'War in Afghanistan'
        ],
        'answer': 3
      },
      {
        'text': 'Who was known as the Maid of Orleans?',
        'options': [
          'Marie Antoinette',
          'Joan of Arc',
          'Catherine the Great',
          'Queen Elizabeth I'
        ],
        'answer': 1
      },
      {
        'text':
            'Which wall was torn down in 1989, symbolizing the end of the Cold War?',
        'options': [
          'Great Wall of China',
          'Berlin Wall',
          "Hadrian's Wall",
          'Western Wall'
        ],
        'answer': 1
      },
      {
        'text': 'Who invented the telephone?',
        'options': [
          'Thomas Edison',
          'Nikola Tesla',
          'Alexander Graham Bell',
          'Guglielmo Marconi'
        ],
        'answer': 2
      },
      {
        'text': 'Which revolution began in 1789?',
        'options': [
          'American Revolution',
          'Russian Revolution',
          'French Revolution',
          'Industrial Revolution'
        ],
        'answer': 2
      },
      {
        'text':
            'Who was the Egyptian queen that had a relationship with Julius Caesar and Mark Antony?',
        'options': ['Nefertiti', 'Hatshepsut', 'Cleopatra', 'Sobekneferu'],
        'answer': 2
      },
      {
        'text': 'What was the main cause of the American Civil War?',
        'options': [
          'Taxation without representation',
          'Slavery',
          'Religious freedom',
          'Border disputes'
        ],
        'answer': 1
      },
      {
        'text': 'Which explorer is America named after?',
        'options': [
          'Amerigo Vespucci',
          'Christopher Columbus',
          'Ferdinand Magellan',
          'Leif Erikson'
        ],
        'answer': 0
      },
      {
        'text': 'Who was the Soviet leader during the Cuban Missile Crisis?',
        'options': [
          'Joseph Stalin',
          'Vladimir Lenin',
          'Nikita Khrushchev',
          'Mikhail Gorbachev'
        ],
        'answer': 2
      }
    ];

    final animeQuestions = [
      {
        'text': 'In Naruto, what is the name of the Nine-Tailed Fox?',
        'options': ['Shukaku', 'Kurama', 'Gyuki', 'Matatabi'],
        'answer': 1
      },
      {
        'text': 'Who is the protagonist of My Hero Academia?',
        'options': [
          'Katsuki Bakugo',
          'Shoto Todoroki',
          'Izuku Midoriya',
          'Tenya Iida'
        ],
        'answer': 2
      },
      {
        'text': 'What is the highest bounty in One Piece among these?',
        'options': ['Monkey D. Luffy', 'Gol D. Roger', 'Whitebeard', 'Shanks'],
        'answer': 1
      },
      {
        'text': 'In Fullmetal Alchemist, what is the taboo among alchemists?',
        'options': [
          'Transmuting Gold',
          'Human Transmutation',
          'Creating Homunculi',
          'Using Philosopher\'s Stones'
        ],
        'answer': 1
      },
      {
        'text': 'What is the name of Goku\'s signature attack in Dragon Ball?',
        'options': [
          'Galick Gun',
          'Destructo Disc',
          'Kamehameha',
          'Special Beam Cannon'
        ],
        'answer': 2
      },
      {
        'text':
            'Which anime features spatial maneuvering gear to fight giants?',
        'options': [
          'Neon Genesis Evangelion',
          'Attack on Titan',
          'Sword Art Online',
          'Tokyo Ghoul'
        ],
        'answer': 1
      },
      {
        'text': 'What does Saitama from One Punch Man do for training?',
        'options': [
          '100 Push-ups, Sit-ups, Squats, 10km Run',
          'Weightlifting 500lbs',
          'Meditating under a waterfall',
          'Fighting monsters every day'
        ],
        'answer': 0
      },
      {
        'text': 'Who wrote the notebook in Death Note?',
        'options': ['Light Yagami', 'L', 'Ryuk', 'Misa Amane'],
        'answer': 2
      },
      {
        'text': 'In Hunter x Hunter, what is Gon searching for?',
        'options': [
          'The ultimate treasure',
          'His father',
          'Revenge',
          'A legendary sword'
        ],
        'answer': 1
      },
      {
        'text': 'Which JoJo part features Jotaro Kujo?',
        'options': [
          'Phantom Blood',
          'Battle Tendency',
          'Stardust Crusaders',
          'Golden Wind'
        ],
        'answer': 2
      },
      {
        'text':
            'In Demon Slayer, what breathing style does Tanjiro primarily use at first?',
        'options': [
          'Water Breathing',
          'Sun Breathing',
          'Thunder Breathing',
          'Beast Breathing'
        ],
        'answer': 0
      },
      {
        'text': 'What sport is the focus of Haikyuu!!?',
        'options': ['Basketball', 'Volleyball', 'Tennis', 'Baseball'],
        'answer': 1
      },
      {
        'text': 'In Bleach, what is Ichigo\'s sword form called?',
        'options': ['Bankai', 'Shikai', 'Zanpakuto', 'Resurreccion'],
        'answer': 2
      },
      {
        'text': 'Who is the main antagonist of the Cell Saga in Dragon Ball Z?',
        'options': ['Frieza', 'Buu', 'Cell', 'Raditz'],
        'answer': 2
      },
      {
        'text': 'What is the guild\'s name in Fairy Tail?',
        'options': ['Blue Pegasus', 'Sabertooth', 'Fairy Tail', 'Lamia Scale'],
        'answer': 2
      },
      {
        'text': 'In Tokyo Ghoul, what do ghouls eat?',
        'options': ['Normal Food', 'Human Flesh', 'Animal Meat', 'Blood only'],
        'answer': 1
      },
      {
        'text': 'Which anime revolves around the Elric brothers?',
        'options': [
          'Black Clover',
          'Fullmetal Alchemist',
          'Soul Eater',
          'D.Gray-man'
        ],
        'answer': 1
      },
      {
        'text':
            'What is the name of the virtual reality game in Sword Art Online?',
        'options': [
          'Alfheim Online',
          'Gun Gale Online',
          'Sword Art Online',
          'Underworld'
        ],
        'answer': 2
      },
      {
        'text': 'Who is the "Flame Alchemist" in Fullmetal Alchemist?',
        'options': [
          'Edward Elric',
          'Alphonse Elric',
          'Roy Mustang',
          'Alex Louis Armstrong'
        ],
        'answer': 2
      },
      {
        'text': 'In My Hero Academia, what is All Might\'s quirk called?',
        'options': [
          'One For All',
          'All For One',
          'Explosion',
          'Half-Cold Half-Hot'
        ],
        'answer': 0
      },
    ];

    final moviesQuestions = [
      {
        'text': 'Who directed Inception?',
        'options': [
          'Steven Spielberg',
          'Christopher Nolan',
          'Martin Scorsese',
          'Quentin Tarantino'
        ],
        'answer': 1
      },
      {
        'text': 'Which movie features the quote "I\'ll be back"?',
        'options': ['Die Hard', 'The Terminator', 'Rambo', 'Predator'],
        'answer': 1
      },
      {
        'text': 'What is the highest-grossing film of all time (as of 2024)?',
        'options': [
          'Avengers: Endgame',
          'Avatar',
          'Titanic',
          'Star Wars: The Force Awakens'
        ],
        'answer': 1
      },
      {
        'text': 'Who plays Iron Man in the Marvel Cinematic Universe?',
        'options': [
          'Chris Evans',
          'Chris Hemsworth',
          'Robert Downey Jr.',
          'Mark Ruffalo'
        ],
        'answer': 2
      },
      {
        'text': 'In The Matrix, what color pill does Neo take?',
        'options': ['Blue', 'Red', 'Green', 'Yellow'],
        'answer': 1
      },
      {
        'text': 'What year was the original Jurassic Park released?',
        'options': ['1990', '1993', '1995', '1997'],
        'answer': 1
      },
      {
        'text':
            'Which film won the first Academy Award for Best Animated Feature?',
        'options': ['Toy Story', 'Shrek', 'Finding Nemo', 'Spirited Away'],
        'answer': 1
      },
      {
        'text': 'Who composed the score for Star Wars?',
        'options': [
          'Hans Zimmer',
          'John Williams',
          'Danny Elfman',
          'Ennio Morricone'
        ],
        'answer': 1
      },
      {
        'text':
            'What is the name of the hobbit played by Elijah Wood in The Lord of the Rings?',
        'options': [
          'Samwise Gamgee',
          'Peregrin Took',
          'Meriadoc Brandybuck',
          'Frodo Baggins'
        ],
        'answer': 3
      },
      {
        'text':
            'Which movie is based on a Stephen King novella called "Rita Hayworth and Shawshank Redemption"?',
        'options': [
          'The Green Mile',
          'The Shining',
          'The Shawshank Redemption',
          'Stand by Me'
        ],
        'answer': 2
      },
      {
        'text': 'Who directed The Godfather?',
        'options': [
          'Francis Ford Coppola',
          'Martin Scorsese',
          'Brian De Palma',
          'Sergio Leone'
        ],
        'answer': 0
      },
      {
        'text':
            'In what movie does Tom Hanks talk to a volleyball named Wilson?',
        'options': [
          'Forrest Gump',
          'Cast Away',
          'Apollo 13',
          'Saving Private Ryan'
        ],
        'answer': 1
      },
      {
        'text':
            'What is the name of the fictional continent in Game of Thrones?',
        'options': ['Middle-earth', 'Narnia', 'Westeros', 'Fantastica'],
        'answer': 2
      },
      {
        'text': 'Which actor played the Joker in The Dark Knight?',
        'options': [
          'Jack Nicholson',
          'Jared Leto',
          'Joaquin Phoenix',
          'Heath Ledger'
        ],
        'answer': 3
      },
      {
        'text': 'What is the first rule of Fight Club?',
        'options': [
          'Always fight to the death',
          'You do not talk about Fight Club',
          'No shirts, no shoes',
          'Bring your own soap'
        ],
        'answer': 1
      },
      {
        'text': 'What sci-fi film features a computer named HAL 9000?',
        'options': [
          'Blade Runner',
          'Alien',
          '2001: A Space Odyssey',
          'The Terminator'
        ],
        'answer': 2
      },
      {
        'text': 'Who played Jack Dawson in Titanic?',
        'options': [
          'Brad Pitt',
          'Tom Cruise',
          'Leonardo DiCaprio',
          'Johnny Depp'
        ],
        'answer': 2
      },
      {
        'text': 'Which movie features the song "My Heart Will Go On"?',
        'options': ['The Bodyguard', 'Titanic', 'Ghost', 'Pretty Woman'],
        'answer': 1
      },
      {
        'text': 'What is the name of the kingdom where Frozen takes place?',
        'options': ['Arendelle', 'Corona', 'Kumandra', 'Atlantica'],
        'answer': 0
      },
      {
        'text': 'Who directed Pulp Fiction?',
        'options': [
          'Martin Scorsese',
          'Quentin Tarantino',
          'David Fincher',
          'Spike Lee'
        ],
        'answer': 1
      },
    ];

    void insertSet(List<Map<String, Object>> qList, String sId) async {
      for (var q in qList) {
        await txn.insert('questions', {
          'id': uuid.v4(),
          'subject_id': sId,
          'text': q['text'],
          'options': jsonEncode(q['options']),
          'correct_index': q['answer'],
        });
      }
    }

    insertSet(historyQuestions, subjectId);
    insertSet(animeQuestions, animeSubId);
    insertSet(moviesQuestions, moviesSubId);
  });
}
