import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedAppLanguages = <(String, String)>[
  ('es', 'Español'),
  ('en', 'English'),
  ('it', 'Italiano'),
  ('fr', 'Français'),
  ('de', 'Deutsch'),
  ('pt', 'Português'),
  ('ru', 'Русский'),
  ('ja', '日本語'),
];

const _translationKeys = <String>[
  'nav_dex',
  'nav_tools',
  'nav_collection',
  'nav_explore',
  'tools_title',
  'tools_intro',
  'strategy',
  'collection_data',
  'team_title',
  'team_desc',
  'compare_title',
  'compare_desc',
  'type_title',
  'type_desc',
  'nature_title',
  'nature_desc',
  'item_title',
  'item_desc',
  'offline_text',
  'collection_title',
  'caught',
  'shinies',
  'hunt',
  'explore_title',
  'regions',
  'trainers',
  'language',
];

const _translations = <String, List<String>>{
  'es': [
    'Pokédex',
    'Herramientas',
    'Colección',
    'Explorar',
    'Centro de herramientas',
    'Prepara tu siguiente aventura',
    'ESTRATEGIA',
    'COLECCIÓN Y DATOS',
    'Teambuilder',
    'Arma seis integrantes y analiza coberturas.',
    'Comparador',
    'Contrasta estadísticas y habilidades.',
    'Dex de tipos',
    'Debilidades, resistencias e inmunidades.',
    'Dex de naturalezas',
    'Estadísticas que suben, bajan y sabores.',
    'Dex de objetos',
    'Busca por nombre y categoría.',
    'Tus equipos, capturas y contador shiny se guardan en el dispositivo. Los datos consultados se conservan en caché para abrirlos sin conexión.',
    'Mi aventura',
    'Capturados',
    'Shinies',
    'Caza shiny',
    'Mundo Pokémon',
    'Regiones y rutas',
    'Entrenadores',
    'Idioma',
  ],
  'en': [
    'Pokédex',
    'Tools',
    'Collection',
    'Explore',
    'Tool center',
    'Plan your next adventure',
    'STRATEGY',
    'COLLECTION & DATA',
    'Team builder',
    'Build a six Pokémon team and analyze coverage.',
    'Comparator',
    'Compare stats and abilities.',
    'Type Dex',
    'Weaknesses, resistances and immunities.',
    'Nature Dex',
    'Stats raised, lowered and flavor preferences.',
    'Item Dex',
    'Search by name and category.',
    'Your teams, catches and shiny counter are saved on this device. Viewed data is cached for offline access.',
    'My journey',
    'Caught',
    'Shinies',
    'Shiny hunt',
    'Pokémon world',
    'Regions & routes',
    'Trainers',
    'Language',
  ],
  'it': [
    'Pokédex',
    'Strumenti',
    'Collezione',
    'Esplora',
    'Centro strumenti',
    'Prepara la prossima avventura',
    'STRATEGIA',
    'COLLEZIONE E DATI',
    'Team builder',
    'Crea una squadra di sei Pokémon e analizza la copertura.',
    'Comparatore',
    'Confronta statistiche e abilità.',
    'Dex dei tipi',
    'Debolezze, resistenze e immunità.',
    'Dex delle nature',
    'Statistiche e preferenze di gusto.',
    'Dex degli strumenti',
    'Cerca per nome e categoria.',
    'Squadre, catture e contatore shiny sono salvati sul dispositivo. I dati consultati restano nella cache offline.',
    'La mia avventura',
    'Catturati',
    'Shiny',
    'Caccia shiny',
    'Mondo Pokémon',
    'Regioni e percorsi',
    'Allenatori',
    'Lingua',
  ],
  'fr': [
    'Pokédex',
    'Outils',
    'Collection',
    'Explorer',
    'Centre des outils',
    'Prépare ta prochaine aventure',
    'STRATÉGIE',
    'COLLECTION ET DONNÉES',
    'Team builder',
    'Crée une équipe de six Pokémon et analyse sa couverture.',
    'Comparateur',
    'Compare les statistiques et les talents.',
    'Dex des types',
    'Faiblesses, résistances et immunités.',
    'Dex des natures',
    'Statistiques et préférences de saveur.',
    'Dex des objets',
    'Recherche par nom et catégorie.',
    'Équipes, captures et compteur shiny sont enregistrés sur l’appareil. Les données consultées sont gardées en cache hors ligne.',
    'Mon aventure',
    'Capturés',
    'Shinies',
    'Chasse shiny',
    'Monde Pokémon',
    'Régions et routes',
    'Dresseurs',
    'Langue',
  ],
  'de': [
    'Pokédex',
    'Werkzeuge',
    'Sammlung',
    'Erkunden',
    'Werkzeugzentrum',
    'Bereite dein nächstes Abenteuer vor',
    'STRATEGIE',
    'SAMMLUNG UND DATEN',
    'Teambuilder',
    'Stelle ein Team aus sechs Pokémon zusammen und prüfe die Typenabdeckung.',
    'Vergleich',
    'Vergleiche Werte und Fähigkeiten.',
    'Typen-Dex',
    'Schwächen, Resistenzen und Immunitäten.',
    'Wesen-Dex',
    'Werte und Geschmackspräferenzen.',
    'Item-Dex',
    'Suche nach Name und Kategorie.',
    'Teams, Fänge und Shiny-Zähler werden auf diesem Gerät gespeichert. Angesehene Daten bleiben offline im Cache.',
    'Mein Abenteuer',
    'Gefangen',
    'Shinies',
    'Shiny-Jagd',
    'Pokémon-Welt',
    'Regionen und Routen',
    'Trainer',
    'Sprache',
  ],
  'pt': [
    'Pokédex',
    'Ferramentas',
    'Coleção',
    'Explorar',
    'Central de ferramentas',
    'Prepare sua próxima aventura',
    'ESTRATÉGIA',
    'COLEÇÃO E DADOS',
    'Teambuilder',
    'Monte uma equipe de seis Pokémon e analise a cobertura.',
    'Comparador',
    'Compare atributos e habilidades.',
    'Dex de tipos',
    'Fraquezas, resistências e imunidades.',
    'Dex de naturezas',
    'Atributos e preferências de sabor.',
    'Dex de itens',
    'Pesquise por nome e categoria.',
    'Equipes, capturas e contador shiny ficam salvos no dispositivo. Dados consultados são armazenados em cache offline.',
    'Minha aventura',
    'Capturados',
    'Shinies',
    'Caça shiny',
    'Mundo Pokémon',
    'Regiões e rotas',
    'Treinadores',
    'Idioma',
  ],
  'ru': [
    'Покедекс',
    'Инструменты',
    'Коллекция',
    'Мир',
    'Центр инструментов',
    'Готовься к следующему приключению',
    'СТРАТЕГИЯ',
    'КОЛЛЕКЦИЯ И ДАННЫЕ',
    'Конструктор команды',
    'Собери команду из шести покемонов и проверь покрытие типов.',
    'Сравнение',
    'Сравни характеристики и способности.',
    'Типы',
    'Слабости, сопротивления и иммунитеты.',
    'Характеры',
    'Повышаемые и понижаемые характеристики, вкусы.',
    'Предметы',
    'Поиск по названию и категории.',
    'Команды, поимки и счетчик shiny сохраняются на устройстве. Просмотренные данные доступны из кеша офлайн.',
    'Моё приключение',
    'Пойманы',
    'Шайни',
    'Охота на шайни',
    'Мир Pokémon',
    'Регионы и маршруты',
    'Тренеры',
    'Язык',
  ],
  'ja': [
    'ポケモン図鑑',
    'ツール',
    'コレクション',
    '探索',
    'ツールセンター',
    '次の冒険の準備をしよう',
    '戦略',
    'コレクションとデータ',
    'チームビルダー',
    '6匹のチームを作り、タイプ相性を分析します。',
    '比較',
    '能力値と特性を比べます。',
    'タイプ図鑑',
    '弱点、耐性、無効を確認します。',
    '性格図鑑',
    '能力値の変化と好みを確認します。',
    '道具図鑑',
    '名前やカテゴリで検索します。',
    'チーム、捕獲記録、色違いカウンターは端末に保存されます。閲覧済みデータはオフラインキャッシュに残ります。',
    '冒険の記録',
    '捕まえたポケモン',
    '色違い',
    '色違い厳選',
    'ポケモンの世界',
    '地方とルート',
    'トレーナー',
    '言語',
  ],
};

const _toolsSubtitles = <String, String>{
  'es': 'Construye equipos, estudia tipos y compara estadísticas.',
  'en': 'Build teams, study type matchups and compare stats.',
  'it': 'Crea squadre, studia i tipi e confronta le statistiche.',
  'fr': 'Crée des équipes, étudie les types et compare les statistiques.',
  'de': 'Stelle Teams zusammen, lerne Typen kennen und vergleiche Werte.',
  'pt': 'Monte equipes, estude tipos e compare atributos.',
  'ru': 'Собирай команды, изучай типы и сравнивай характеристики.',
  'ja': 'チームを作り、タイプ相性や能力値を比べましょう。',
};

const _loadedLabels = <String, String>{
  'es': 'Pokémon cargados',
  'en': 'Pokémon loaded',
  'it': 'Pokémon caricati',
  'fr': 'Pokémon chargés',
  'de': 'Pokémon geladen',
  'pt': 'Pokémon carregados',
  'ru': 'покемонов загружено',
  'ja': '匹を読み込み済み',
};

class AppLanguageController extends ChangeNotifier {
  AppLanguageController._();
  static final instance = AppLanguageController._();
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String _code = 'es';
  String get code => _code;

  Future<void> load() async {
    final saved = await _preferences.getString('app_language_code');
    if (saved != null && _translations.containsKey(saved)) {
      _code = saved;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (!_translations.containsKey(code)) return;
    _code = code;
    notifyListeners();
    await _preferences.setString('app_language_code', code);
  }

  String text(String key) {
    if (key == 'tools_subtitle') return _toolsSubtitles[_code]!;
    if (key == 'loaded') return _loadedLabels[_code]!;
    final index = _translationKeys.indexOf(key);
    if (index < 0) return key;
    return _translations[_code]![index];
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  const AppLanguageScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppLanguageController of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppLanguageScope>()
          ?.notifier ??
      AppLanguageController.instance;
}

String appText(BuildContext context, String key) =>
    AppLanguageScope.of(context).text(key);
