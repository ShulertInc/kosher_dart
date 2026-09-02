// GENERATED from kosher-rust by tool/parity/gen_limudim.mjs. Do not edit by hand.

/// The first and last daf of each masechta of the Bavli, in the order [Daf] numbers
/// them, for the schedules that run over whole dafim.
const List<List<int>> dafRangePerMasechta = [
  [2, 64],
  [2, 157],
  [2, 105],
  [2, 121],
  [2, 22],
  [2, 88],
  [2, 56],
  [2, 40],
  [2, 35],
  [2, 31],
  [2, 32],
  [2, 29],
  [2, 27],
  [2, 122],
  [2, 112],
  [2, 91],
  [2, 66],
  [2, 49],
  [2, 90],
  [2, 82],
  [2, 119],
  [2, 119],
  [2, 176],
  [2, 113],
  [2, 24],
  [2, 49],
  [2, 76],
  [2, 14],
  [2, 120],
  [2, 110],
  [2, 142],
  [2, 61],
  [2, 34],
  [2, 34],
  [2, 28],
  [2, 22],
  [23, 25],
  [26, 33],
  [34, 37],
  [2, 73],
];

/// The first and last amud of each masechta of the Bavli, as page and side, for the
/// schedules that run over amudim. A side of 0 is amud aleph and 1 is amud beis.
const List<List<int>> amudRangePerMasechta = [
  [2, 0, 64, 0],
  [2, 0, 157, 1],
  [2, 0, 105, 0],
  [2, 0, 121, 1],
  [2, 0, 22, 1],
  [2, 0, 88, 0],
  [2, 0, 56, 1],
  [2, 0, 40, 1],
  [2, 0, 35, 1],
  [2, 0, 31, 0],
  [2, 0, 32, 0],
  [2, 0, 29, 0],
  [2, 0, 27, 0],
  [2, 0, 122, 1],
  [2, 0, 112, 1],
  [2, 0, 91, 1],
  [2, 0, 66, 1],
  [2, 0, 49, 1],
  [2, 0, 90, 1],
  [2, 0, 82, 1],
  [2, 0, 119, 1],
  [2, 0, 119, 0],
  [2, 0, 176, 1],
  [2, 0, 113, 1],
  [2, 0, 24, 1],
  [2, 0, 49, 1],
  [2, 0, 76, 1],
  [2, 0, 14, 0],
  [2, 0, 120, 1],
  [2, 0, 110, 0],
  [2, 0, 142, 0],
  [2, 0, 61, 0],
  [2, 0, 34, 0],
  [2, 0, 34, 0],
  [2, 0, 28, 1],
  [2, 0, 22, 0],
  [22, 1, 25, 0],
  [25, 1, 33, 1],
  [34, 0, 37, 1],
  [2, 0, 73, 0],
];

/// The masechtos of the Mishna, in the order Mishna Yomis learns them.
const List<String> mishnaMasechtosTransliterated = [
    "Berachos", "Peah", "Demai", "Kilayim",
    "Sheviis", "Terumos", "Maasros", "Maaser Sheni",
    "Chalah", "Orlah", "Bikurim", "Shabbos",
    "Eruvin", "Pesachim", "Shekalim", "Yoma",
    "Sukkah", "Beitzah", "Rosh Hashanah", "Taanis",
    "Megillah", "Moed Katan", "Chagigah", "Yevamos",
    "Kesubos", "Nedarim", "Nazir", "Sotah",
    "Gitin", "Kiddushin", "Bava Kamma", "Bava Metzia",
    "Bava Basra", "Sanhedrin", "Makkos", "Shevuos",
    "Eduyos", "Avodah Zarah", "Avos", "Horiyos",
    "Zevachim", "Menachos", "Chullin", "Bechoros",
    "Arachin", "Temurah", "Kerisos", "Meilah",
    "Tamid", "Midos", "Kinnim", "Keilim",
    "Ohalos", "Negaim", "Parah", "Taharos",
    "Mikvaos", "Niddah", "Machshirin", "Zavim",
    "Tevul Yom", "Yadayim", "Uktzin",
];

/// The number of mishnayos in each chapter of each masechta, indexed as
/// [mishnaMasechtosTransliterated].
const List<List<int>> mishnayosPerChapter = [
  // Berachos
  [5, 8, 6, 7, 5, 8, 5, 8, 5],
  // Peah
  [6, 8, 8, 11, 8, 11, 8, 9],
  // Demai
  [4, 5, 6, 7, 11, 12, 8],
  // Kilayim
  [9, 11, 7, 9, 8, 9, 8, 6, 10],
  // Sheviis
  [8, 10, 10, 10, 9, 6, 7, 11, 9, 9],
  // Terumos
  [10, 6, 9, 13, 9, 6, 7, 12, 7, 12, 10],
  // Maasros
  [8, 8, 10, 6, 8],
  // Maaser Sheni
  [7, 10, 13, 12, 15],
  // Chalah
  [9, 8, 10, 11],
  // Orlah
  [9, 17, 9],
  // Bikurim
  [11, 11, 12, 5],
  // Shabbos
  [11, 7, 6, 2, 4, 10, 4, 7, 7, 6, 6, 6, 7, 4, 3, 8, 8, 3, 6, 5, 3, 6, 5, 5],
  // Eruvin
  [10, 6, 9, 11, 9, 10, 11, 11, 4, 15],
  // Pesachim
  [7, 8, 8, 9, 10, 6, 13, 8, 11, 9],
  // Shekalim
  [7, 5, 4, 9, 6, 6, 7, 8],
  // Yoma
  [8, 7, 11, 6, 7, 8, 5, 9],
  // Sukkah
  [11, 9, 15, 10, 8],
  // Beitzah
  [10, 10, 8, 7, 7],
  // Rosh Hashanah
  [9, 9, 8, 9],
  // Taanis
  [7, 10, 9, 8],
  // Megillah
  [11, 6, 6, 10],
  // Moed Katan
  [10, 5, 9],
  // Chagigah
  [8, 7, 8],
  // Yevamos
  [4, 10, 10, 13, 6, 6, 6, 6, 6, 9, 7, 6, 13, 9, 10, 7],
  // Kesubos
  [10, 10, 9, 12, 9, 7, 10, 8, 9, 6, 6, 4, 11],
  // Nedarim
  [4, 5, 11, 8, 6, 10, 9, 7, 10, 8, 12],
  // Nazir
  [7, 10, 7, 7, 7, 11, 4, 2, 5],
  // Sotah
  [9, 6, 8, 5, 5, 4, 8, 7, 15],
  // Gitin
  [6, 7, 8, 9, 9, 7, 9, 10, 10],
  // Kiddushin
  [10, 10, 13, 14],
  // Bava Kamma
  [4, 6, 11, 9, 7, 6, 7, 7, 12, 10],
  // Bava Metzia
  [8, 11, 12, 12, 11, 8, 11, 9, 13, 6],
  // Bava Basra
  [6, 14, 8, 9, 11, 8, 4, 8, 10, 8],
  // Sanhedrin
  [6, 5, 8, 5, 5, 6, 11, 7, 6, 6, 6],
  // Makkos
  [10, 8, 16],
  // Shevuos
  [7, 5, 11, 13, 5, 7, 8, 6],
  // Eduyos
  [14, 10, 12, 12, 7, 3, 9, 7],
  // Avodah Zarah
  [9, 7, 10, 12, 12],
  // Avos
  [18, 16, 18, 22, 23, 11],
  // Horiyos
  [5, 7, 8],
  // Zevachim
  [4, 5, 6, 6, 8, 7, 6, 12, 7, 8, 8, 6, 8, 10],
  // Menachos
  [4, 5, 7, 5, 9, 7, 6, 7, 9, 9, 9, 5, 11],
  // Chullin
  [7, 10, 7, 7, 5, 7, 6, 6, 8, 4, 2, 5],
  // Bechoros
  [7, 9, 4, 10, 6, 12, 7, 10, 8],
  // Arachin
  [4, 6, 5, 4, 6, 5, 5, 7, 8],
  // Temurah
  [6, 3, 5, 4, 6, 5, 6],
  // Kerisos
  [7, 6, 10, 3, 8, 9],
  // Meilah
  [4, 9, 8, 6, 5, 6],
  // Tamid
  [4, 5, 9, 3, 6, 3, 4],
  // Midos
  [9, 6, 8, 7, 4],
  // Kinnim
  [4, 5, 6],
  // Keilim
  [9, 8, 8, 4, 11, 4, 6, 11, 8, 8, 9, 8, 8, 8, 6, 8, 17, 9, 10, 7, 3, 10, 5, 17, 9, 9, 12, 10, 8, 4],
  // Ohalos
  [8, 7, 7, 3, 7, 7, 6, 6, 16, 7, 9, 8, 6, 7, 10, 5, 5, 10],
  // Negaim
  [6, 5, 8, 11, 5, 8, 5, 10, 3, 10, 12, 7, 12, 13],
  // Parah
  [4, 5, 11, 4, 9, 5, 12, 11, 9, 6, 9, 11],
  // Taharos
  [9, 8, 8, 13, 9, 10, 9, 9, 9, 8],
  // Mikvaos
  [8, 10, 4, 5, 6, 11, 7, 5, 7, 8],
  // Niddah
  [7, 7, 7, 7, 9, 14, 5, 4, 11, 8],
  // Machshirin
  [6, 11, 8, 10, 11, 8],
  // Zavim
  [6, 4, 3, 7, 12],
  // Tevul Yom
  [5, 8, 6, 7],
  // Yadayim
  [5, 4, 5, 8],
  // Uktzin
  [6, 10, 12],
];
