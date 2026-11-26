// ignore_for_file: deprecated_member_use, prefer_interpolation_to_compose_strings
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final appState = await AppState.load(prefs);
  runApp(SAAgriApp(state: appState));
}

class Listing {
  Listing(this.id, this.title, this.description, this.category, this.price, this.wilaya, this.phone);
  final String id, title, description, category, price, wilaya, phone;
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'description': description, 'category': category, 'price': price, 'wilaya': wilaya, 'phone': phone};
  factory Listing.fromMap(Map<String, dynamic> m) => Listing(
    m['id'] ?? '', m['title'] ?? '', m['description'] ?? '', m['category'] ?? 'other',
    m['price'] ?? '', m['wilaya'] ?? '', m['phone'] ?? '',
  );
}

class AppState extends ChangeNotifier {
  AppState(this.prefs);
  final SharedPreferences prefs;
  String language = 'ar';
  String wilaya = '';
  bool dark = false;
  final List<Listing> listings = [];
  final List<String> posts = [];

  static Future<AppState> load(SharedPreferences prefs) async {
    final s = AppState(prefs);
    s.language = prefs.getString('language') ?? 'ar';
    if (!['ar', 'fr', 'en'].contains(s.language)) s.language = 'ar';
    s.wilaya = prefs.getString('wilaya') ?? '';
    s.dark = prefs.getBool('dark') ?? false;
    try {
      final data = prefs.getString('listings');
      if (data != null) {
        s.listings.addAll((jsonDecode(data) as List).map((e) => Listing.fromMap(Map<String, dynamic>.from(e))));
      }
    } catch (_) {}
    try {
      final data = prefs.getString('posts');
      if (data != null) s.posts.addAll((jsonDecode(data) as List).cast<String>());
    } catch (_) {}
    return s;
  }

  Future<void> setLanguage(String v) async { language = v; await prefs.setString('language', v); notifyListeners(); }
  Future<void> setDark(bool v) async { dark = v; await prefs.setBool('dark', v); notifyListeners(); }
  Future<void> setWilaya(String v) async { wilaya = v; await prefs.setString('wilaya', v); notifyListeners(); }
  Future<void> addListing(Listing v) async {
    listings.insert(0, v);
    await prefs.setString('listings', jsonEncode(listings.map((e) => e.toMap()).toList()));
    notifyListeners();
  }
  Future<void> deleteListing(String id) async {
    listings.removeWhere((e) => e.id == id);
    await prefs.setString('listings', jsonEncode(listings.map((e) => e.toMap()).toList()));
    notifyListeners();
  }
  Future<void> addPost(String v) async {
    posts.insert(0, v);
    await prefs.setString('posts', jsonEncode(posts));
    notifyListeners();
  }
}

const Map<String, Map<String, String>> words = {
'ar': {
'home':'الرئيسية','market':'السوق الزراعي','library':'المكتبة الزراعية','community':'المجتمع','messages':'الرسائل','suppliers':'دليل الموردين','settings':'الإعدادات','tagline':'منصتك الزراعية الجزائرية','welcome':'مرحبًا بك في SA AgriAI','welcomeSub':'منصة رقمية للفلاحين ومربي المواشي والمهنيين الزراعيين.','wilaya':'الولاية','notSet':'لم تُحدد بعد','listings':'إعلانات السوق','posts':'منشورات المجتمع','weather':'الطقس','weatherNA':'بيانات الطقس غير متاحة حاليًا','weatherNote':'لن نعرض بيانات أو تنبيهات وهمية. ستظهر المعلومات بعد ربط مصدر موثوق.','quick':'الوصول السريع','recent':'النشاط الأخير','noActivity':'لا يوجد نشاط بعد.','add':'إضافة إعلان','search':'ابحث في الإعلانات...','emptyMarket':'لا توجد إعلانات بعد','emptySub':'أضف أول إعلان على هذا الجهاز.','title':'العنوان','description':'الوصف','category':'التصنيف','price':'السعر بالدينار','phone':'رقم الهاتف','save':'حفظ','cancel':'إلغاء','required':'هذا الحقل مطلوب','seeds':'بذور وشتلات','fertilizers':'أسمدة','equipment':'معدات وآلات','livestock':'مواشٍ وحيوانات','feed':'أعلاف','services':'خدمات زراعية','other':'أخرى','local':'محفوظ على هذا الجهاز فقط','delete':'حذف','librarySub':'معلومات زراعية موثقة المصدر.','crops':'المحاصيل والإنتاج النباتي','soil':'التربة والتسميد','irrigation':'الري والمياه','plant':'صحة النبات','animals':'تربية الحيوانات','feeding':'التغذية والأعلاف','breeding':'التكاثر والسلالات','machinery':'الآلات والصيانة','contentSoon':'سيُضاف المحتوى بعد توثيق المصادر ومراجعته من مختصين.','communitySub':'تبادل الخبرات مع المجتمع الزراعي.','writePost':'اكتب منشورًا للفلاحين والمربين...','publish':'نشر محلي','emptyPosts':'لا توجد منشورات بعد','messagesNA':'المراسلة غير مفعّلة في النسخة المحلية.','suppliersSub':'دليل موردي الأسمدة والمدخلات حسب المنطقة.','suppliersNA':'لا يوجد موردون موثوقون مضافون بعد.','suppliersNote':'لن نعرض موردين أو تقييمات غير متحقق منها.','settingsSub':'خصّص لغة التطبيق ومظهره ومنطقتك.','language':'لغة التطبيق','arabic':'العربية','french':'Français','english':'English','dark':'الوضع الداكن','saveWilaya':'حفظ الولاية','about':'حول التطبيق','aboutNote':'منصة زراعية رقمية للجزائر. النسخة الحالية تجريبية وتعمل محليًا.','backend':'حالة الربط','backendNote':'الخادم وتخزين الصور والمراسلة غير متصلة بعد؛ لا تُرسل بيانات إلى خادم.','contact':'التواصل','saved':'تم الحفظ على هذا الجهاز','negotiable':'السعر عند التواصل','noResults':'لا توجد نتائج مطابقة','searchTopics':'ابحث في المكتبة...','confirmDelete':'هل تريد حذف هذا الإعلان؟','confirm':'تأكيد','version':'إصدار تجريبي 0.1.0'
},
'fr': {
'home':'Accueil','market':'Marché agricole','library':'Bibliothèque agricole','community':'Communauté','messages':'Messages','suppliers':'Annuaire fournisseurs','settings':'Paramètres','tagline':'Votre plateforme agricole algérienne','welcome':'Bienvenue sur SA AgriAI','welcomeSub':'Une plateforme numérique pour les agriculteurs, éleveurs et professionnels.','wilaya':'Wilaya','notSet':'Non définie','listings':'Annonces du marché','posts':'Publications','weather':'Météo','weatherNA':'Données météo indisponibles','weatherNote':'Aucune donnée ni alerte fictive. Les informations apparaîtront après connexion à une source fiable.','quick':'Accès rapide','recent':'Activité récente','noActivity':'Aucune activité pour le moment.','add':'Ajouter une annonce','search':'Rechercher des annonces...','emptyMarket':'Aucune annonce','emptySub':'Ajoutez la première annonce sur cet appareil.','title':'Titre','description':'Description','category':'Catégorie','price':'Prix en DZD','phone':'Téléphone','save':'Enregistrer','cancel':'Annuler','required':'Champ obligatoire','seeds':'Semences et plants','fertilizers':'Engrais','equipment':'Équipements et machines','livestock':'Bétail et animaux','feed':'Aliments pour animaux','services':'Services agricoles','other':'Autre','local':'Enregistré sur cet appareil uniquement','delete':'Supprimer','librarySub':'Informations agricoles avec sources vérifiées.','crops':'Cultures et production végétale','soil':'Sols et fertilisation','irrigation':'Irrigation et eau','plant':'Santé des plantes','animals':'Élevage','feeding':'Alimentation animale','breeding':'Reproduction et races','machinery':'Machines et maintenance','contentSoon':'Le contenu sera ajouté après vérification des sources par des spécialistes.','communitySub':'Échangez avec la communauté agricole.','writePost':'Écrire une publication...','publish':'Publier localement','emptyPosts':'Aucune publication','messagesNA':'La messagerie n’est pas activée dans cette version locale.','suppliersSub':'Annuaire des fournisseurs agricoles par région.','suppliersNA':'Aucun fournisseur vérifié pour le moment.','suppliersNote':'Aucun fournisseur ni avis non vérifié ne sera affiché.','settingsSub':'Personnalisez la langue, le thème et votre région.','language':'Langue de l’application','arabic':'العربية','french':'Français','english':'English','dark':'Mode sombre','saveWilaya':'Enregistrer la wilaya','about':'À propos','aboutNote':'Plateforme agricole numérique pour l’Algérie. Version initiale pour ordinateur.','backend':'État des connexions','backendNote':'Le serveur, le stockage des images et la messagerie ne sont pas encore connectés.','contact':'Contact','saved':'Enregistré sur cet appareil','negotiable':'Prix à discuter','noResults':'Aucun résultat','searchTopics':'Rechercher dans la bibliothèque...','confirmDelete':'Supprimer cette annonce ?','confirm':'Confirmer','version':'Version de test 0.1.0'
},
'en': {
'home':'Home','market':'Agricultural market','library':'Knowledge center','community':'Community','messages':'Messages','suppliers':'Supplier directory','settings':'Settings','tagline':'Your Algerian agriculture platform','welcome':'Welcome to SA AgriAI','welcomeSub':'A digital platform for farmers, livestock breeders, and agricultural professionals.','wilaya':'Wilaya','notSet':'Not selected','listings':'Market listings','posts':'Community posts','weather':'Weather','weatherNA':'Weather data is unavailable','weatherNote':'No fabricated data or alerts. Information will appear after connecting a trusted source.','quick':'Quick access','recent':'Recent activity','noActivity':'No activity yet.','add':'Add listing','search':'Search listings...','emptyMarket':'No listings yet','emptySub':'Create the first listing on this device.','title':'Title','description':'Description','category':'Category','price':'Price in DZD','phone':'Phone','save':'Save','cancel':'Cancel','required':'Required field','seeds':'Seeds and seedlings','fertilizers':'Fertilizers','equipment':'Equipment and machinery','livestock':'Livestock and animals','feed':'Animal feed','services':'Agricultural services','other':'Other','local':'Saved on this device only','delete':'Delete','librarySub':'Agricultural information with verified sources.','crops':'Crops and plant production','soil':'Soil and fertilization','irrigation':'Irrigation and water','plant':'Plant health','animals':'Animal husbandry','feeding':'Feeding and fodder','breeding':'Reproduction and breeds','machinery':'Machinery and maintenance','contentSoon':'Content will be added after source verification and specialist review.','communitySub':'Exchange experience with the agricultural community.','writePost':'Write a post...','publish':'Publish locally','emptyPosts':'No posts yet','messagesNA':'Messaging is not enabled in this local version.','suppliersSub':'Directory of agricultural suppliers by region.','suppliersNA':'No verified suppliers have been added.','suppliersNote':'Unverified suppliers and ratings will not be displayed.','settingsSub':'Customize the language, theme, and your region.','language':'Application language','arabic':'العربية','french':'Français','english':'English','dark':'Dark mode','saveWilaya':'Save wilaya','about':'About','aboutNote':'A digital agriculture platform for Algeria. Initial desktop version.','backend':'Connection status','backendNote':'The server, image storage, and messaging are not connected yet.','contact':'Contact','saved':'Saved on this device','negotiable':'Price negotiable','noResults':'No matching results','searchTopics':'Search the library...','confirmDelete':'Delete this listing?','confirm':'Confirm','version':'Test version 0.1.0'
}
};

String tr(AppState s, String key) => words[s.language]?[key] ?? words['en']![key] ?? key;

class SAAgriApp extends StatelessWidget {
  const SAAgriApp({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => MaterialApp(
      title: 'SA AgriAI',
      debugShowCheckedModeBanner: false,
      themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)), scaffoldBackgroundColor: const Color(0xFFF3F7F2)),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: Brightness.dark)),
      home: Directionality(textDirection: state.language == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: DesktopShell(state: state)),
    ),
  );
}

enum Section { home, market, library, community, messages, suppliers, settings }

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, required this.state});
  final AppState state;
  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  Section selected = Section.home;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 950;
    final state = widget.state;
    Widget page;
    switch (selected) {
      case Section.home: page = DashboardPage(state: state, go: (v) => setState(() => selected = v)); break;
      case Section.market: page = MarketPage(state: state); break;
      case Section.library: page = LibraryPage(state: state); break;
      case Section.community: page = CommunityPage(state: state); break;
      case Section.messages: page = InfoPage(state: state, section: 'messages'); break;
      case Section.suppliers: page = InfoPage(state: state, section: 'suppliers'); break;
      case Section.settings: page = SettingsPage(state: state); break;
    }
    return Scaffold(
      body: Row(children: [
        Sidebar(state: state, compact: compact, selected: selected, onSelect: (v) => setState(() => selected = v)),
        Expanded(child: Column(children: [
          Container(height: 66, padding: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))), child: Row(children: [
            const Icon(Icons.eco, color: Color(0xFF2E7D32)),
            const SizedBox(width: 9),
            const Text('SA AgriAI', style: TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Chip(avatar: const Icon(Icons.computer, size: 15), label: Text(tr(state, 'local'))),
            const SizedBox(width: 10),
            const CircleAvatar(radius: 17, child: Icon(Icons.person_outline, size: 18)),
          ])),
          Expanded(child: page),
        ])),
      ]),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.state, required this.compact, required this.selected, required this.onSelect});
  final AppState state;
  final bool compact;
  final Section selected;
  final ValueChanged<Section> onSelect;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <(Section, String, IconData)>[
      (Section.home, 'home', Icons.dashboard_outlined),
      (Section.market, 'market', Icons.storefront_outlined),
      (Section.library, 'library', Icons.menu_book_outlined),
      (Section.community, 'community', Icons.groups_outlined),
      (Section.messages, 'messages', Icons.chat_bubble_outline),
      (Section.suppliers, 'suppliers', Icons.agriculture_outlined),
      (Section.settings, 'settings', Icons.settings_outlined),
    ];
    return Container(width: compact ? 74 : 235, color: Theme.of(context).cardColor, child: Column(children: [
      Padding(padding: EdgeInsets.all(compact ? 12 : 20), child: Row(mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.eco, color: Colors.white)),
        if (!compact) ...[const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SA AgriAI', style: TextStyle(fontWeight: FontWeight.w900)), Text(tr(state, 'tagline'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant))]))],
      ])),
      const Divider(height: 1),
      const SizedBox(height: 10),
      Expanded(child: ListView(padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 12), children: items.map((item) {
        final active = selected == item.$1;
        return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Tooltip(message: compact ? tr(state, item.$2) : '', child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(item.$1),
          child: Container(padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 13, vertical: 13), decoration: BoxDecoration(color: active ? cs.primaryContainer : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
            Icon(item.$3, size: 21, color: active ? cs.primary : cs.onSurfaceVariant),
            if (!compact) ...[const SizedBox(width: 12), Expanded(child: Text(tr(state, item.$2), style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? cs.primary : cs.onSurface)))],
          ])),
        )));
      }).toList())),
      if (!compact) Padding(padding: const EdgeInsets.all(16), child: Align(alignment: AlignmentDirectional.centerStart, child: Text(tr(state, 'version'), style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)))),
    ]));
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.all(26), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1380), child: child)));
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, required this.subtitle, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ])),
    if (action != null) action!,
  ]));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.state, required this.go});
  final AppState state;
  final ValueChanged<Section> go;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PageFrame(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(title: tr(state, 'welcome'), subtitle: tr(state, 'welcomeSub')),
      Wrap(spacing: 13, runSpacing: 13, children: [
        MetricCard(title: tr(state, 'listings'), value: state.listings.length.toString(), icon: Icons.storefront_outlined, tint: const Color(0xFF2E7D32)),
        MetricCard(title: tr(state, 'posts'), value: state.posts.length.toString(), icon: Icons.groups_outlined, tint: const Color(0xFF8E44AD)),
      ]),
      const SizedBox(height: 18),
      LayoutBuilder(builder: (context, c) {
        final weather = Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.cloud_outlined, color: cs.primary), const SizedBox(width: 8), Text(tr(state, 'weather'), style: const TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 16),
          Text(tr(state, 'weatherNA'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          Text(tr(state, 'weatherNote'), style: TextStyle(fontSize: 12, height: 1.5, color: cs.onSurfaceVariant)),
        ])));
        final location = Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.location_on_outlined, color: cs.primary),
          const SizedBox(height: 12),
          Text(tr(state, 'wilaya'), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 5),
          Text(state.wilaya.isEmpty ? tr(state, 'notSet') : state.wilaya, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        ])));
        if (c.maxWidth > 730) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: weather), const SizedBox(width: 14), Expanded(flex: 2, child: location)]);
        return Column(children: [weather, const SizedBox(height: 12), location]);
      }),
      const SizedBox(height: 20),
      Text(tr(state, 'quick'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        QuickAction(label: tr(state, 'market'), icon: Icons.storefront_outlined, onTap: () => go(Section.market)),
        QuickAction(label: tr(state, 'library'), icon: Icons.menu_book_outlined, onTap: () => go(Section.library)),
        QuickAction(label: tr(state, 'community'), icon: Icons.groups_outlined, onTap: () => go(Section.community)),
        QuickAction(label: tr(state, 'suppliers'), icon: Icons.agriculture_outlined, onTap: () => go(Section.suppliers)),
      ]),
      const SizedBox(height: 20),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(Icons.history, color: cs.primary), const SizedBox(width: 10), Text(tr(state, 'recent')), const Spacer(), Text(tr(state, 'noActivity'), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))]))),
    ]));
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.title, required this.value, required this.icon, required this.tint});
  final String title, value;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => SizedBox(width: 270, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
    Container(width: 46, height: 46, decoration: BoxDecoration(color: tint.withOpacity(.12), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: tint)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant))])),
  ]))));
}

class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13), child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(13), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Theme.of(context).colorScheme.primary, size: 19), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))])));
}

class MarketPage extends StatefulWidget {
  const MarketPage({super.key, required this.state});
  final AppState state;
  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  String query = '';
  Future<void> add() async {
    final item = await showDialog<Listing>(context: context, builder: (_) => ListingDialog(state: widget.state));
    if (item != null) {
      await widget.state.addListing(item);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(widget.state, 'saved'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final filtered = state.listings.where((e) => (e.title + ' ' + e.description + ' ' + e.wilaya).toLowerCase().contains(query.toLowerCase())).toList();
    return PageFrame(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(title: tr(state, 'market'), subtitle: tr(state, 'local'), action: FilledButton.icon(onPressed: add, icon: const Icon(Icons.add), label: Text(tr(state, 'add')))),
      TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: tr(state, 'search'), prefixIcon: const Icon(Icons.search), filled: true, fillColor: Theme.of(context).cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none))),
      const SizedBox(height: 16),
      if (filtered.isEmpty)
        EmptyState(icon: Icons.storefront_outlined, title: query.isEmpty ? tr(state, 'emptyMarket') : tr(state, 'noResults'), subtitle: tr(state, 'emptySub'))
      else
        LayoutBuilder(builder: (context, c) {
          final columns = c.maxWidth > 1000 ? 3 : c.maxWidth > 650 ? 2 : 1;
          final width = (c.maxWidth - (columns - 1) * 13) / columns;
          return Wrap(spacing: 13, runSpacing: 13, children: filtered.map((item) => SizedBox(width: width, child: ListingCard(state: state, item: item, onDelete: () async {
            final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(content: Text(tr(state, 'confirmDelete')), actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: Text(tr(state, 'cancel'))),
              FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(tr(state, 'confirm'))),
            ]));
            if (ok == true) await state.deleteListing(item.id);
          }))).toList());
        }),
    ]));
  }
}

class ListingDialog extends StatefulWidget {
  const ListingDialog({super.key, required this.state});
  final AppState state;
  @override
  State<ListingDialog> createState() => _ListingDialogState();
}

class _ListingDialogState extends State<ListingDialog> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final price = TextEditingController();
  final wilaya = TextEditingController();
  final phone = TextEditingController();
  String category = 'seeds';
  @override
  void dispose() { title.dispose(); description.dispose(); price.dispose(); wilaya.dispose(); phone.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    const categories = ['seeds', 'fertilizers', 'equipment', 'livestock', 'feed', 'services', 'other'];
    return AlertDialog(
      title: Text(tr(state, 'add')),
      content: SizedBox(width: 440, child: Form(key: form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        FormFieldInput(controller: title, label: tr(state, 'title'), requiredField: true),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: category, decoration: InputDecoration(labelText: tr(state, 'category'), border: const OutlineInputBorder()), items: categories.map((v) => DropdownMenuItem(value: v, child: Text(tr(state, v)))).toList(), onChanged: (v) => setState(() => category = v ?? 'other')),
        const SizedBox(height: 10),
        FormFieldInput(controller: description, label: tr(state, 'description'), requiredField: true, maxLines: 3),
        const SizedBox(height: 10),
        FormFieldInput(controller: price, label: tr(state, 'price')),
        const SizedBox(height: 10),
        FormFieldInput(controller: wilaya, label: tr(state, 'wilaya'), requiredField: true),
        const SizedBox(height: 10),
        FormFieldInput(controller: phone, label: tr(state, 'phone')),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(state, 'cancel'))),
        FilledButton(onPressed: () {
          if (form.currentState?.validate() != true) return;
          Navigator.pop(context, Listing(DateTime.now().microsecondsSinceEpoch.toString(), title.text.trim(), description.text.trim(), category, price.text.trim(), wilaya.text.trim(), phone.text.trim()));
        }, child: Text(tr(state, 'save'))),
      ],
    );
  }
}

class FormFieldInput extends StatelessWidget {
  const FormFieldInput({super.key, required this.controller, required this.label, this.requiredField = false, this.maxLines = 1});
  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final int maxLines;
  @override
  Widget build(BuildContext context) => TextFormField(controller: controller, maxLines: maxLines, validator: requiredField ? (v) => v == null || v.trim().isEmpty ? ' ' : null : null, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));
}

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.state, required this.item, required this.onDelete});
  final AppState state;
  final Listing item;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Chip(label: Text(tr(state, item.category))), const Spacer(), IconButton(tooltip: tr(state, 'delete'), onPressed: onDelete, icon: const Icon(Icons.delete_outline))]),
      Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      Text(item.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 13),
      Row(children: [const Icon(Icons.location_on_outlined, size: 15), const SizedBox(width: 4), Expanded(child: Text(item.wilaya, style: const TextStyle(fontSize: 12))), Text(item.price.isEmpty ? tr(state, 'negotiable') : item.price + ' DZD', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8),
      Text(tr(state, 'local'), style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
    ])));
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.state});
  final AppState state;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final topics = <(String, IconData)>[
      ('crops', Icons.grass_outlined), ('soil', Icons.terrain_outlined), ('irrigation', Icons.water_drop_outlined), ('plant', Icons.energy_savings_leaf_outlined),
      ('animals', Icons.pets_outlined), ('feeding', Icons.restaurant_outlined), ('breeding', Icons.egg_alt_outlined), ('machinery', Icons.agriculture_outlined),
    ].where((v) => tr(state, v.$1).toLowerCase().contains(query.toLowerCase())).toList();
    return PageFrame(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(title: tr(state, 'library'), subtitle: tr(state, 'librarySub')),
      TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(hintText: tr(state, 'searchTopics'), prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth > 1000 ? 4 : c.maxWidth > 700 ? 3 : 2;
        final width = (c.maxWidth - (columns - 1) * 13) / columns;
        return Wrap(spacing: 13, runSpacing: 13, children: topics.map((topic) => SizedBox(width: width, child: Card(child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showDialog<void>(context: context, builder: (d) => AlertDialog(title: Text(tr(state, topic.$1)), content: Text(tr(state, 'contentSoon')), actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('OK'))])),
          child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(topic.$2, color: Theme.of(context).colorScheme.primary, size: 31),
            const SizedBox(height: 13),
            Text(tr(state, topic.$1), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(tr(state, 'contentSoon'), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
        )))).toList());
      }),
    ]));
  }
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, required this.state});
  final AppState state;
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final controller = TextEditingController();
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  Future<void> publish() async {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    await widget.state.addPost(value);
    controller.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(widget.state, 'saved'))));
  }
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return PageFrame(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(title: tr(state, 'community'), subtitle: tr(state, 'communitySub')),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: controller, minLines: 3, maxLines: 5, decoration: InputDecoration(hintText: tr(state, 'writePost'), border: InputBorder.none)),
        const Divider(),
        Row(children: [Expanded(child: Text(tr(state, 'local'), style: const TextStyle(fontSize: 11))), FilledButton.icon(onPressed: publish, icon: const Icon(Icons.send, size: 17), label: Text(tr(state, 'publish')))]),
      ]))),
      const SizedBox(height: 15),
      if (state.posts.isEmpty) EmptyState(icon: Icons.forum_outlined, title: tr(state, 'emptyPosts'), subtitle: tr(state, 'local'))
      else ...state.posts.map((post) => Card(child: Padding(padding: const EdgeInsets.all(17), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const CircleAvatar(child: Icon(Icons.person_outline)), const SizedBox(width: 12), Expanded(child: Text(post))])))),
    ]));
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.state, required this.section});
  final AppState state;
  final String section;
  @override
  Widget build(BuildContext context) {
    final isMessages = section == 'messages';
    return PageFrame(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(title: tr(state, isMessages ? 'messages' : 'suppliers'), subtitle: tr(state, isMessages ? 'messages' : 'suppliersSub')),
      EmptyState(icon: isMessages ? Icons.chat_bubble_outline : Icons.verified_user_outlined, title: tr(state, isMessages ? 'messagesNA' : 'suppliersNA'), subtitle: isMessages ? tr(state, 'backendNote') : tr(state, 'suppliersNote')),
    ]));
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.state});
  final AppState state;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController wilaya;
  @override
  void initState() { super.initState(); wilaya = TextEditingController(text: widget.state.wilaya); }
  @override
  void dispose() { wilaya.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cs = Theme.of(context).colorScheme;
    return PageFrame(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeading(title: tr(state, 'settings'), subtitle: tr(state, 'settingsSub')),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr(state, 'language'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 9, children: [
          ChoiceChip(label: Text(tr(state, 'arabic')), selected: state.language == 'ar', onSelected: (_) => state.setLanguage('ar')),
          ChoiceChip(label: Text(tr(state, 'french')), selected: state.language == 'fr', onSelected: (_) => state.setLanguage('fr')),
          ChoiceChip(label: Text(tr(state, 'english')), selected: state.language == 'en', onSelected: (_) => state.setLanguage('en')),
        ]),
        const Divider(height: 28),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(tr(state, 'dark')), value: state.dark, onChanged: state.setDark),
        const Divider(height: 28),
        Text(tr(state, 'wilaya'), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        Row(children: [Expanded(child: TextField(controller: wilaya, decoration: InputDecoration(hintText: tr(state, 'wilaya'), border: const OutlineInputBorder()))), const SizedBox(width: 9), FilledButton(onPressed: () => state.setWilaya(wilaya.text.trim()), child: Text(tr(state, 'saveWilaya')))]),
      ]))),
      const SizedBox(height: 15),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr(state, 'about'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(tr(state, 'aboutNote')),
        const Divider(height: 25),
        Text(tr(state, 'backend'), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(tr(state, 'backendNote'), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const Divider(height: 25),
        const SelectableText('saagriateam@gmail.com'),
        Text(tr(state, 'contact')),
      ]))),
    ]));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(child: SizedBox(width: double.infinity, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 35), child: Column(children: [
      Icon(icon, size: 38, color: cs.onSurfaceVariant),
      const SizedBox(height: 12),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      if (subtitle.isNotEmpty) ...[const SizedBox(height: 7), Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))],
    ]))));
  }
}
