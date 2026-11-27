// ignore_for_file: deprecated_member_use, prefer_interpolation_to_compose_strings
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'cloud_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final api = CloudApi(prefs);
  final appState = await AppState.load(prefs, api);
  runApp(SAAgriApp(state: appState, api: api));
}

class Listing {
  Listing(this.id, this.title, this.description, this.category, this.price, this.wilaya, this.phone,
      {this.userId = ''});
  final String id, title, description, category, price, wilaya, phone, userId;
  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'description': description, 'category': category,
    'price': price, 'wilaya': wilaya, 'phone': phone, 'user_id': userId,
  };
  factory Listing.fromMap(Map<String, dynamic> m) => Listing(
    (m['id'] ?? '').toString(), (m['title'] ?? '').toString(),
    (m['description'] ?? '').toString(), (m['category'] ?? 'other').toString(),
    (m['price'] ?? '').toString(), (m['wilaya'] ?? '').toString(),
    (m['phone'] ?? '').toString(),
    userId: (m['user_id'] ?? m['userId'] ?? '').toString(),
  );
}

class AppState extends ChangeNotifier {
  AppState(this.prefs, this.api);
  final SharedPreferences prefs;
  final CloudApi api;
  String language = 'ar';
  String wilaya = '';
  String currentUserId = '';
  bool dark = false;
  final List<Listing> listings = [];
  final List<String> posts = [];

  static Future<AppState> load(SharedPreferences prefs, CloudApi api) async {
    final s = AppState(prefs, api);
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

  Future<void> refreshCloud() async {
    final remoteListings = await api.fetchListings();
    final remotePosts = await api.fetchPosts();
    currentUserId = api.currentUser?['id']?.toString() ?? '';
    listings
      ..clear()
      ..addAll(remoteListings.map(Listing.fromMap));
    posts
      ..clear()
      ..addAll(remotePosts.map((p) => (p['content'] ?? '').toString()));
    notifyListeners();
  }

  Future<void> setLanguage(String v) async { language = v; await prefs.setString('language', v); notifyListeners(); }
  Future<void> setDark(bool v) async { dark = v; await prefs.setBool('dark', v); notifyListeners(); }
  Future<void> setWilaya(String v) async { wilaya = v; await prefs.setString('wilaya', v); notifyListeners(); }
  Future<void> addListing(Listing v) async {
    if (api.isSignedIn) {
      final saved = await api.createListing(v.toMap());
      listings.insert(0, Listing.fromMap(saved));
    } else {
      listings.insert(0, v);
      await prefs.setString('listings', jsonEncode(listings.map((e) => e.toMap()).toList()));
    }
    notifyListeners();
  }
  Future<void> deleteListing(String id) async {
    if (api.isSignedIn) {
      await api.deleteListing(id);
    }
    listings.removeWhere((e) => e.id == id);
    if (!api.isSignedIn) {
      await prefs.setString('listings', jsonEncode(listings.map((e) => e.toMap()).toList()));
    }
    notifyListeners();
  }
  Future<void> addPost(String v) async {
    if (api.isSignedIn) {
      final saved = await api.createPost(v);
      posts.insert(0, (saved['content'] ?? v).toString());
    } else {
      posts.insert(0, v);
      await prefs.setString('posts', jsonEncode(posts));
    }
    notifyListeners();
  }
}

const Map<String, Map<String, String>> words = {
'ar': {
'home':'الرئيسية','market':'السوق الزراعي','library':'المكتبة الزراعية','sources':'مصادر موثوقة','community':'المجتمع','messages':'الرسائل','suppliers':'دليل الموردين','settings':'الإعدادات','tagline':'منصتك الزراعية الجزائرية','welcome':'مرحبًا بك في SA AgriAI','welcomeSub':'منصة رقمية للفلاحين ومربي المواشي والمهنيين الزراعيين.','wilaya':'الولاية','notSet':'لم تُحدد بعد','listings':'إعلانات السوق','posts':'منشورات المجتمع','weather':'الطقس','weatherNA':'بيانات الطقس غير متاحة حاليًا','weatherNote':'لن نعرض بيانات أو تنبيهات وهمية. ستظهر المعلومات بعد ربط مصدر موثوق.','quick':'الوصول السريع','recent':'النشاط الأخير','noActivity':'لا يوجد نشاط بعد.','add':'إضافة إعلان','search':'ابحث في الإعلانات...','emptyMarket':'لا توجد إعلانات بعد','emptySub':'أضف أول إعلان على هذا الجهاز.','title':'العنوان','description':'الوصف','category':'التصنيف','price':'السعر بالدينار','phone':'رقم الهاتف','save':'حفظ','cancel':'إلغاء','required':'هذا الحقل مطلوب','seeds':'بذور وشتلات','fertilizers':'أسمدة','equipment':'معدات وآلات','livestock':'مواشٍ وحيوانات','feed':'أعلاف','services':'خدمات زراعية','other':'أخرى','local':'محفوظ على هذا الجهاز فقط','delete':'حذف','librarySub':'معلومات زراعية موثقة المصدر.','sourcesSub':'فهرس أولي لمراجع رسمية وتقنية جزائرية. كل مادة منشورة يجب أن ترتبط بمرجعها وتاريخ مراجعتها.','sourceAuthority':'الجهة الناشرة','sourceTopics':'مجالات الاستخدام','sourceOpen':'فتح المصدر الأصلي','sourceChecked':'آخر تحقق: 26 نوفمبر 2026','sourcePolicy':'سياسة توثيق المحتوى','sourcePolicyNote':'لا يُنشر مقال دون عنوان المرجع والجهة المؤلفة والرابط المباشر وسنة النشر أو تاريخ الوثيقة وتاريخ الاطلاع. يجب مطابقة التوصية مع المنطقة والمحصول أو الحيوان، وتسجيل اسم المراجع المختص. لا تُستنتج جرعات أو علاجات من عناوين الوثائق.','sourceIndexNote':'هذا فهرس مراجع، وليس دليلًا على مراجعة كل وثيقة أو صلاحيتها لكل حالة. افتح الوثيقة الأصلية وتحقق من تاريخها ونطاقها قبل الاقتباس.','crops':'المحاصيل والإنتاج النباتي','soil':'التربة والتسميد','irrigation':'الري والمياه','plant':'صحة النبات','animals':'تربية الحيوانات','feeding':'التغذية والأعلاف','breeding':'التكاثر والسلالات','machinery':'الآلات والصيانة','contentSoon':'سيُضاف المحتوى بعد توثيق المصادر ومراجعته من مختصين.','communitySub':'تبادل الخبرات مع المجتمع الزراعي.','writePost':'اكتب منشورًا للفلاحين والمربين...','publish':'نشر محلي','emptyPosts':'لا توجد منشورات بعد','messagesNA':'المراسلة غير مفعّلة في النسخة المحلية.','suppliersSub':'دليل موردي الأسمدة والمدخلات حسب المنطقة.','suppliersNA':'لا يوجد موردون موثوقون مضافون بعد.','suppliersNote':'لن نعرض موردين أو تقييمات غير متحقق منها.','settingsSub':'خصّص لغة التطبيق ومظهره ومنطقتك.','language':'لغة التطبيق','arabic':'العربية','french':'Français','english':'English','dark':'الوضع الداكن','saveWilaya':'حفظ الولاية','about':'حول التطبيق','aboutNote':'منصة زراعية رقمية للجزائر. النسخة الحالية تجريبية وتعمل محليًا.','backend':'حالة الربط','backendNote':'الخادم وتخزين الصور والمراسلة غير متصلة بعد؛ لا تُرسل بيانات إلى خادم.','contact':'التواصل','online':'متصل عبر الإنترنت','sharedMarket':'إعلانات مشتركة بين مستخدمي SA AgriAI','sharedContent':'محتوى مشترك مع المجتمع الزراعي','onlineBackend':'الحسابات وإعلانات السوق ومنشورات المجتمع محفوظة على خادم مشترك.','registerTitle':'إنشاء حساب جديد','loginTitle':'تسجيل الدخول','fullName':'الاسم الكامل','email':'البريد الإلكتروني','password':'كلمة المرور','confirmPassword':'تأكيد كلمة المرور','login':'دخول','register':'إنشاء الحساب','forgotPassword':'نسيت كلمة المرور؟','sendReset':'إرسال رابط الاسترجاع','resetPassword':'إعادة تعيين كلمة المرور','saveNewPassword':'حفظ كلمة المرور الجديدة','resetInstructions':'أدخل بريدك الإلكتروني لاستلام رابط آمن، أو أدخل كلمة مرور جديدة إذا فتحت رابط الاسترجاع.','resetEmailSent':'إذا كان البريد مسجلًا، فستصلك رسالة تحتوي على رابط استرجاع صالح لمدة 20 دقيقة.','passwordUpdated':'تم تغيير كلمة المرور. سجّل الدخول من جديد.','noAccount':'ليس لديك حساب؟ أنشئ حسابًا','hasAccount':'لديك حساب بالفعل؟ سجّل الدخول','backToLogin':'العودة إلى تسجيل الدخول','supportDeleted':'للحساب المحذوف بالخطأ أو فقدان الحساب، تواصل مع فريق الدعم. نسيان كلمة المرور يُعالج تلقائيًا عبر البريد.','contactSupport':'التواصل مع الدعم','continueOffline':'المتابعة دون اتصال (محليًا)','passwordRule':'كلمة المرور يجب أن تتكون من 10 أحرف على الأقل.','passwordsMismatch':'كلمتا المرور غير متطابقتين.','emailExists':'هذا البريد مسجل من قبل. سجّل الدخول بدلًا من ذلك.','invalidCredentials':'البريد الإلكتروني أو كلمة المرور غير صحيحة.','emailSetupMissing':'خدمة إرسال رسائل الاسترجاع لم تُربط بعد. أعد المحاولة لاحقًا.','emailSendFailed':'تعذر إرسال الرسالة حاليًا. حاول لاحقًا.','invalidReset':'رابط الاسترجاع غير صالح أو انتهت صلاحيته. اطلب رابطًا جديدًا.','rateLimited':'محاولات كثيرة. انتظر قليلًا ثم أعد المحاولة.','invalidEmail':'أدخل بريدًا إلكترونيًا صحيحًا.','authGenericError':'تعذر إكمال العملية. تحقق من الاتصال وحاول مجددًا.','serverUnavailable':'تعذر الاتصال بالخادم الآن. تحقق من الإنترنت أو جرّب الوضع المحلي.','logout':'تسجيل الخروج','saved':'تم الحفظ على هذا الجهاز','negotiable':'السعر عند التواصل','noResults':'لا توجد نتائج مطابقة','searchTopics':'ابحث في المكتبة...','confirmDelete':'هل تريد حذف هذا الإعلان؟','confirm':'تأكيد','version':'إصدار تجريبي 0.1.0'
},
'fr': {
'home':'Accueil','market':'Marché agricole','library':'Bibliothèque agricole','sources':'Sources fiables','community':'Communauté','messages':'Messages','suppliers':'Annuaire fournisseurs','settings':'Paramètres','tagline':'Votre plateforme agricole algérienne','welcome':'Bienvenue sur SA AgriAI','welcomeSub':'Une plateforme numérique pour les agriculteurs, éleveurs et professionnels.','wilaya':'Wilaya','notSet':'Non définie','listings':'Annonces du marché','posts':'Publications','weather':'Météo','weatherNA':'Données météo indisponibles','weatherNote':'Aucune donnée ni alerte fictive. Les informations apparaîtront après connexion à une source fiable.','quick':'Accès rapide','recent':'Activité récente','noActivity':'Aucune activité pour le moment.','add':'Ajouter une annonce','search':'Rechercher des annonces...','emptyMarket':'Aucune annonce','emptySub':'Ajoutez la première annonce sur cet appareil.','title':'Titre','description':'Description','category':'Catégorie','price':'Prix en DZD','phone':'Téléphone','save':'Enregistrer','cancel':'Annuler','required':'Champ obligatoire','seeds':'Semences et plants','fertilizers':'Engrais','equipment':'Équipements et machines','livestock':'Bétail et animaux','feed':'Aliments pour animaux','services':'Services agricoles','other':'Autre','local':'Enregistré sur cet appareil uniquement','delete':'Supprimer','librarySub':'Informations agricoles avec sources vérifiées.','sourcesSub':'Premier index de références agricoles officielles et techniques algériennes. Chaque publication doit citer sa source et sa date de révision.','sourceAuthority':'Organisme éditeur','sourceTopics':'Domaines','sourceOpen':'Ouvrir la source originale','sourceChecked':'Dernière vérification : 26 novembre 2026','sourcePolicy':'Politique de citation','sourcePolicyNote':'Aucun article ne doit être publié sans titre de la référence, organisme auteur, lien direct, année de publication ou date du document, date de consultation et nom du réviseur compétent. Adapter chaque recommandation à la région et à la culture ou l’espèce concernée. Ne jamais déduire des doses ou traitements du seul titre d’un document.','sourceIndexNote':'Cet index répertorie des références ; il ne signifie pas que chaque document a été réévalué ni qu’il s’applique à toute situation. Ouvrir le document original et vérifier sa date et son champ avant citation.','crops':'Cultures et production végétale','soil':'Sols et fertilisation','irrigation':'Irrigation et eau','plant':'Santé des plantes','animals':'Élevage','feeding':'Alimentation animale','breeding':'Reproduction et races','machinery':'Machines et maintenance','contentSoon':'Le contenu sera ajouté après vérification des sources par des spécialistes.','communitySub':'Échangez avec la communauté agricole.','writePost':'Écrire une publication...','publish':'Publier localement','emptyPosts':'Aucune publication','messagesNA':'La messagerie n’est pas activée dans cette version locale.','suppliersSub':'Annuaire des fournisseurs agricoles par région.','suppliersNA':'Aucun fournisseur vérifié pour le moment.','suppliersNote':'Aucun fournisseur ni avis non vérifié ne sera affiché.','settingsSub':'Personnalisez la langue, le thème et votre région.','language':'Langue de l’application','arabic':'العربية','french':'Français','english':'English','dark':'Mode sombre','saveWilaya':'Enregistrer la wilaya','about':'À propos','aboutNote':'Plateforme agricole numérique pour l’Algérie. Version initiale pour ordinateur.','backend':'État des connexions','backendNote':'Le serveur, le stockage des images et la messagerie ne sont pas encore connectés.','contact':'Contact','online':'En ligne','sharedMarket':'Annonces partagées avec les utilisateurs SA AgriAI','sharedContent':'Partagé avec la communauté agricole','onlineBackend':'Les comptes, les annonces et les publications utilisent un stockage cloud partagé.','registerTitle':'Créer un compte','loginTitle':'Connexion','fullName':'Nom complet','email':'Adresse e-mail','password':'Mot de passe','confirmPassword':'Confirmer le mot de passe','login':'Se connecter','register':'Créer le compte','forgotPassword':'Mot de passe oublié ?','sendReset':'Envoyer le lien de réinitialisation','resetPassword':'Réinitialiser le mot de passe','saveNewPassword':'Enregistrer le nouveau mot de passe','resetInstructions':'Saisissez votre e-mail pour recevoir un lien sécurisé, ou définissez un nouveau mot de passe après avoir ouvert le lien reçu.','resetEmailSent':'Si cette adresse est enregistrée, un lien valable 20 minutes vous sera envoyé.','passwordUpdated':'Mot de passe modifié. Veuillez vous reconnecter.','noAccount':'Pas de compte ? Créez-en un','hasAccount':'Vous avez déjà un compte ? Connectez-vous','backToLogin':'Retour à la connexion','supportDeleted':'Pour un compte supprimé par erreur ou un compte perdu, contactez le support. Un mot de passe oublié se récupère automatiquement par e-mail.','contactSupport':'Contacter le support','continueOffline':'Continuer hors ligne (localement)','passwordRule':'Le mot de passe doit contenir au moins 10 caractères.','passwordsMismatch':'Les mots de passe ne correspondent pas.','emailExists':'Cette adresse est déjà inscrite. Connectez-vous.','invalidCredentials':'Adresse e-mail ou mot de passe incorrect.','emailSetupMissing':'Le service d’envoi des e-mails de réinitialisation n’est pas encore configuré. Réessayez plus tard.','emailSendFailed':'Impossible d’envoyer l’e-mail pour le moment. Réessayez plus tard.','invalidReset':'Ce lien est invalide ou expiré. Demandez un nouveau lien.','rateLimited':'Trop de tentatives. Patientez puis réessayez.','invalidEmail':'Saisissez une adresse e-mail valide.','authGenericError':'Opération impossible. Vérifiez la connexion et réessayez.','serverUnavailable':'Le service en ligne est indisponible. Vérifiez votre connexion ou utilisez le mode local.','logout':'Déconnexion','saved':'Enregistré sur cet appareil','negotiable':'Prix à discuter','noResults':'Aucun résultat','searchTopics':'Rechercher dans la bibliothèque...','confirmDelete':'Supprimer cette annonce ?','confirm':'Confirmer','version':'Version de test 0.1.0'
},
'en': {
'home':'Home','market':'Agricultural market','library':'Knowledge center','sources':'Trusted sources','community':'Community','messages':'Messages','suppliers':'Supplier directory','settings':'Settings','tagline':'Your Algerian agriculture platform','welcome':'Welcome to SA AgriAI','welcomeSub':'A digital platform for farmers, livestock breeders, and agricultural professionals.','wilaya':'Wilaya','notSet':'Not selected','listings':'Market listings','posts':'Community posts','weather':'Weather','weatherNA':'Weather data is unavailable','weatherNote':'No fabricated data or alerts. Information will appear after connecting a trusted source.','quick':'Quick access','recent':'Recent activity','noActivity':'No activity yet.','add':'Add listing','search':'Search listings...','emptyMarket':'No listings yet','emptySub':'Create the first listing on this device.','title':'Title','description':'Description','category':'Category','price':'Price in DZD','phone':'Phone','save':'Save','cancel':'Cancel','required':'Required field','seeds':'Seeds and seedlings','fertilizers':'Fertilizers','equipment':'Equipment and machinery','livestock':'Livestock and animals','feed':'Animal feed','services':'Agricultural services','other':'Other','local':'Saved on this device only','delete':'Delete','librarySub':'Agricultural information with verified sources.','sourcesSub':'Initial index of official and technical Algerian agricultural references. Every published item must cite its source and review date.','sourceAuthority':'Publishing institution','sourceTopics':'Coverage','sourceOpen':'Open original source','sourceChecked':'Last checked: 26 November 2026','sourcePolicy':'Content citation policy','sourcePolicyNote':'Do not publish an article without the reference title, authoring institution, direct link, publication year or document date, access date, and named specialist reviewer. Match each recommendation to the relevant region and crop or animal. Never infer treatment doses or prescriptions from a document title.','sourceIndexNote':'This is a reference index, not proof that every document has been re-reviewed or applies to every situation. Open the original document and check its date and scope before citing it.','crops':'Crops and plant production','soil':'Soil and fertilization','irrigation':'Irrigation and water','plant':'Plant health','animals':'Animal husbandry','feeding':'Feeding and fodder','breeding':'Reproduction and breeds','machinery':'Machinery and maintenance','contentSoon':'Content will be added after source verification and specialist review.','communitySub':'Exchange experience with the agricultural community.','writePost':'Write a post...','publish':'Publish locally','emptyPosts':'No posts yet','messagesNA':'Messaging is not enabled in this local version.','suppliersSub':'Directory of agricultural suppliers by region.','suppliersNA':'No verified suppliers have been added.','suppliersNote':'Unverified suppliers and ratings will not be displayed.','settingsSub':'Customize the language, theme, and your region.','language':'Application language','arabic':'العربية','french':'Français','english':'English','dark':'Dark mode','saveWilaya':'Save wilaya','about':'About','aboutNote':'A digital agriculture platform for Algeria. Initial desktop version.','backend':'Connection status','backendNote':'The server, image storage, and messaging are not connected yet.','contact':'Contact','online':'Connected online','sharedMarket':'Listings shared with SA AgriAI users','sharedContent':'Shared with the agricultural community','onlineBackend':'Accounts, marketplace listings, and community posts use shared cloud storage.','registerTitle':'Create an account','loginTitle':'Sign in','fullName':'Full name','email':'Email address','password':'Password','confirmPassword':'Confirm password','login':'Sign in','register':'Create account','forgotPassword':'Forgot password?','sendReset':'Send reset link','resetPassword':'Reset password','saveNewPassword':'Save new password','resetInstructions':'Enter your email to receive a secure link, or choose a new password after opening your reset link.','resetEmailSent':'If this email is registered, a reset link valid for 20 minutes will be sent.','passwordUpdated':'Password changed. Please sign in again.','noAccount':'New here? Create an account','hasAccount':'Already have an account? Sign in','backToLogin':'Back to sign in','supportDeleted':'For an account deleted by mistake or a lost account, contact support. Forgotten passwords are recovered automatically by email.','contactSupport':'Contact support','continueOffline':'Continue offline (local mode)','passwordRule':'Password must contain at least 10 characters.','passwordsMismatch':'The passwords do not match.','emailExists':'This email is already registered. Please sign in.','invalidCredentials':'Email or password is incorrect.','emailSetupMissing':'The password-reset email service is not configured yet. Try again later.','emailSendFailed':'The reset email could not be sent. Please try again later.','invalidReset':'This reset link is invalid or expired. Request a new link.','rateLimited':'Too many attempts. Please wait and try again.','invalidEmail':'Enter a valid email address.','authGenericError':'The request could not be completed. Check your connection and try again.','serverUnavailable':'The online service is unavailable. Check your connection or use offline mode.','logout':'Sign out','saved':'Saved on this device','negotiable':'Price negotiable','noResults':'No matching results','searchTopics':'Search the library...','confirmDelete':'Delete this listing?','confirm':'Confirm','version':'Test version 0.1.0'
};

String tr(AppState s, String key) => words[s.language]?[key] ?? words['en']![key] ?? key;

class SAAgriApp extends StatelessWidget {
  const SAAgriApp({super.key, required this.state, required this.api});
  final AppState state;
  final CloudApi api;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => MaterialApp(
      title: 'SA AgriAI',
      debugShowCheckedModeBanner: false,
      themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)), scaffoldBackgroundColor: const Color(0xFFF3F7F2)),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), brightness: Brightness.dark)),
      home: Directionality(textDirection: state.language == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: AuthGate(state: state, api: api)),
    ),
  );
}


class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.state, required this.api});
  final AppState state;
  final CloudApi api;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loading = true;
  bool offlineMode = false;
  Map<String, dynamic>? user;
  String? startupError;

  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    try {
      final restored = await widget.api.restoreSession();
      if (restored != null) {
        await widget.state.refreshCloud();
      }
      if (!mounted) return;
      setState(() { user = restored; loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { startupError = 'NETWORK_UNAVAILABLE'; loading = false; });
    }
  }

  Future<void> authenticated(Map<String, dynamic> value) async {
    try {
      await widget.state.refreshCloud();
    } catch (_) {
      // The account is authenticated; content can be refreshed again from the pages.
    }
    if (mounted) setState(() { user = value; offlineMode = false; startupError = null; });
  }

  Future<void> logout() async {
    await widget.api.logout();
    widget.state.currentUserId = '';
    if (mounted) setState(() { user = null; offlineMode = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user != null || offlineMode) {
      return DesktopShell(state: widget.state, onLogout: offlineMode ? null : logout);
    }
    return AuthPage(
      state: widget.state,
      api: widget.api,
      allowOffline: !kIsWeb,
      startupError: startupError,
      onAuthenticated: authenticated,
      onOffline: () => setState(() { offlineMode = true; }),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.state,
    required this.api,
    required this.onAuthenticated,
    required this.onOffline,
    required this.allowOffline,
    this.startupError,
  });
  final AppState state;
  final CloudApi api;
  final Future<void> Function(Map<String, dynamic>) onAuthenticated;
  final VoidCallback onOffline;
  final bool allowOffline;
  final String? startupError;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  String mode = 'login';
  String resetToken = '';
  String? message;
  bool success = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    resetToken = Uri.base.queryParameters['reset'] ?? '';
    if (resetToken.isNotEmpty) mode = 'reset';
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  String get heading {
    switch (mode) {
      case 'register': return tr(widget.state, 'registerTitle');
      case 'forgot': return tr(widget.state, 'forgotPassword');
      case 'reset': return tr(widget.state, 'resetPassword');
      default: return tr(widget.state, 'loginTitle');
    }
  }

  String explainError(Object error) {
    final code = error is CloudApiException ? error.code : 'AUTH_GENERIC_ERROR';
    switch (code) {
      case 'EMAIL_ALREADY_REGISTERED': return tr(widget.state, 'emailExists');
      case 'WEAK_PASSWORD': return tr(widget.state, 'passwordRule');
      case 'EMAIL_SERVICE_NOT_CONFIGURED': return tr(widget.state, 'emailSetupMissing');
      case 'EMAIL_DELIVERY_FAILED': return tr(widget.state, 'emailSendFailed');
      case 'INVALID_RESET_LINK': return tr(widget.state, 'invalidReset');
      case 'RATE_LIMITED': return tr(widget.state, 'rateLimited');
      case 'INVALID_CREDENTIALS': return tr(widget.state, 'invalidCredentials');
      case 'INVALID_EMAIL': return tr(widget.state, 'invalidEmail');
      default: return tr(widget.state, 'authGenericError');
    }
  }

  Future<void> submit() async {
    if (busy || form.currentState?.validate() != true) return;
    if (mode == 'register' && password.text != confirmPassword.text) {
      setState(() { message = tr(widget.state, 'passwordsMismatch'); success = false; });
      return;
    }
    if (mode == 'reset' && password.text != confirmPassword.text) {
      setState(() { message = tr(widget.state, 'passwordsMismatch'); success = false; });
      return;
    }

    setState(() { busy = true; message = null; });
    try {
      if (mode == 'login') {
        final account = await widget.api.login(email: email.text.trim(), password: password.text);
        await widget.onAuthenticated(account);
      } else if (mode == 'register') {
        final account = await widget.api.register(
          displayName: name.text.trim(),
          email: email.text.trim(),
          password: password.text,
        );
        await widget.onAuthenticated(account);
      } else if (mode == 'forgot') {
        await widget.api.requestPasswordReset(email.text.trim());
        setState(() { success = true; message = tr(widget.state, 'resetEmailSent'); });
      } else if (mode == 'reset') {
        await widget.api.resetPassword(resetToken, password.text);
        setState(() {
          mode = 'login';
          resetToken = '';
          password.clear();
          confirmPassword.clear();
          success = true;
          message = tr(widget.state, 'passwordUpdated');
        });
      }
    } catch (error) {
      setState(() { success = false; message = explainError(error); });
    } finally {
      if (mounted) setState(() { busy = false; });
    }
  }

  Future<void> contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'saagriateam@gmail.com',
      queryParameters: {'subject': 'SA AgriAI - Account recovery'},
    );
    await launchUrl(uri);
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    bool secret = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: secret,
        keyboardType: keyboard,
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return tr(widget.state, 'required');
          if (secret && text.length < 10) return tr(widget.state, 'passwordRule');
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(secret ? Icons.lock_outline : Icons.person_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final showEmail = mode != 'reset';
    final showName = mode == 'register';
    final showPassword = mode == 'login' || mode == 'register' || mode == 'reset';
    final showConfirm = mode == 'register' || mode == 'reset';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco, size: 46, color: Color(0xFF2E7D32)),
                      const SizedBox(height: 10),
                      const Text('SA AgriAI', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(heading, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 22),
                      if (widget.startupError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(tr(state, 'serverUnavailable'),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center),
                        ),
                      if (mode == 'forgot' || mode == 'reset')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(tr(state, mode == 'forgot' ? 'resetInstructions' : 'resetInstructions'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ),
                      if (showName) field(controller: name, label: tr(state, 'fullName')),
                      if (showEmail) field(
                        controller: email,
                        label: tr(state, 'email'),
                        keyboard: TextInputType.emailAddress,
                      ),
                      if (showPassword) field(
                        controller: password,
                        label: tr(state, 'password'),
                        secret: true,
                      ),
                      if (showConfirm) field(
                        controller: confirmPassword,
                        label: tr(state, 'confirmPassword'),
                        secret: true,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 4),
                        Text(message!, textAlign: TextAlign.center,
                          style: TextStyle(
                            color: success ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          )),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        onPressed: busy ? null : submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: busy
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(mode == 'login' ? tr(state, 'login')
                                  : mode == 'register' ? tr(state, 'register')
                                  : mode == 'forgot' ? tr(state, 'sendReset')
                                  : tr(state, 'saveNewPassword')),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (mode == 'login')
                        TextButton(
                          onPressed: () => setState(() { mode = 'forgot'; message = null; success = false; }),
                          child: Text(tr(state, 'forgotPassword')),
                        ),
                      if (mode == 'login')
                        TextButton(
                          onPressed: () => setState(() { mode = 'register'; message = null; success = false; }),
                          child: Text(tr(state, 'noAccount')),
                        ),
                      if (mode == 'register')
                        TextButton(
                          onPressed: () => setState(() { mode = 'login'; message = null; success = false; }),
                          child: Text(tr(state, 'hasAccount')),
                        ),
                      if (mode == 'forgot' || mode == 'reset')
                        TextButton(
                          onPressed: () => setState(() { mode = 'login'; message = null; success = false; }),
                          child: Text(tr(state, 'backToLogin')),
                        ),
                      const Divider(height: 24),
                      Text(tr(state, 'supportDeleted'), textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      TextButton.icon(
                        onPressed: contactSupport,
                        icon: const Icon(Icons.email_outlined, size: 17),
                        label: Text(tr(state, 'contactSupport')),
                      ),
                      if (widget.allowOffline) ...[
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: widget.onOffline,
                          child: Text(tr(state, 'continueOffline')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum Section { home, market, library, sources, community, messages, suppliers, settings }

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, required this.state, this.onLogout});
  final AppState state;
  final VoidCallback? onLogout;
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
      case Section.sources: page = SourcesPage(state: state); break;
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
            Chip(avatar: Icon(state.api.isSignedIn ? Icons.cloud_done_outlined : Icons.computer, size: 15),
              label: Text(tr(state, state.api.isSignedIn ? 'online' : 'local'))),
            const SizedBox(width: 10),
            if (widget.onLogout != null)
              IconButton(tooltip: tr(state, 'logout'), onPressed: widget.onLogout, icon: const Icon(Icons.logout))
            else
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
      (Section.sources, 'sources', Icons.library_books_outlined),
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
      PageHeading(title: tr(state, 'market'), subtitle: tr(state, state.api.isSignedIn ? 'sharedMarket' : 'local'), action: FilledButton.icon(onPressed: add, icon: const Icon(Icons.add), label: Text(tr(state, 'add')))),
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
      Row(children: [Chip(label: Text(tr(state, item.category))), const Spacer(),
        if (!state.api.isSignedIn || item.userId == state.currentUserId)
          IconButton(tooltip: tr(state, 'delete'), onPressed: onDelete, icon: const Icon(Icons.delete_outline))]),
      Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 7),
      Text(item.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant)),
      const SizedBox(height: 13),
      Row(children: [const Icon(Icons.location_on_outlined, size: 15), const SizedBox(width: 4), Expanded(child: Text(item.wilaya, style: const TextStyle(fontSize: 12))), Text(item.price.isEmpty ? tr(state, 'negotiable') : item.price + ' DZD', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8),
      Text(tr(state, state.api.isSignedIn ? 'sharedContent' : 'local'), style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
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
        Row(children: [Expanded(child: Text(tr(state, state.api.isSignedIn ? 'sharedContent' : 'local'), style: const TextStyle(fontSize: 11))), FilledButton.icon(onPressed: publish, icon: const Icon(Icons.send, size: 17), label: Text(tr(state, 'publish')))]),
      ]))),
      const SizedBox(height: 15),
      if (state.posts.isEmpty) EmptyState(icon: Icons.forum_outlined, title: tr(state, 'emptyPosts'), subtitle: tr(state, 'local'))
      else ...state.posts.map((post) => Card(child: Padding(padding: const EdgeInsets.all(17), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const CircleAvatar(child: Icon(Icons.person_outline)), const SizedBox(width: 12), Expanded(child: Text(post))])))),
    ]));
  }
}


class _AgriculturalSource {
  const _AgriculturalSource({
    required this.id,
    required this.titleAr,
    required this.titleFr,
    required this.titleEn,
    required this.organisation,
    required this.scopeAr,
    required this.scopeFr,
    required this.scopeEn,
    required this.url,
    required this.kindAr,
    required this.kindFr,
    required this.kindEn,
  });

  final String id;
  final String titleAr, titleFr, titleEn;
  final String organisation;
  final String scopeAr, scopeFr, scopeEn;
  final String url;
  final String kindAr, kindFr, kindEn;

  String title(String language) =>
      language == 'ar' ? titleAr : language == 'fr' ? titleFr : titleEn;
  String scope(String language) =>
      language == 'ar' ? scopeAr : language == 'fr' ? scopeFr : scopeEn;
  String kind(String language) =>
      language == 'ar' ? kindAr : language == 'fr' ? kindFr : kindEn;
}

class SourcesPage extends StatelessWidget {
  const SourcesPage({super.key, required this.state});
  final AppState state;

  static const List<_AgriculturalSource> _sources = [
    _AgriculturalSource(
      id: 'INVA-DOC-001',
      titleAr: 'الوثائق الزراعية — المعهد الوطني للإرشاد الفلاحي',
      titleFr: 'Documents agricoles — INVA',
      titleEn: 'Agricultural documents — INVA',
      organisation: 'INVA · وزارة الفلاحة',
      scopeAr: 'تضم الصفحة وثائق إرشادية مفهرسة، منها تربية الماعز والنحل، التبن والسيلاج، طفيليات الإبل، وبعض أمراض الحبوب وتخزينها. يجب فتح الوثيقة الفردية وتسجيل بياناتها قبل الاقتباس.',
      scopeFr: 'La page répertorie des documents de vulgarisation sur l’élevage caprin et l’apiculture, le foin et l’ensilage, les parasites du dromadaire, certaines maladies des céréales et leur stockage. Vérifier chaque document avant citation.',
      scopeEn: 'The catalogue lists extension documents on goat keeping, beekeeping, hay and silage, camel parasites, some cereal diseases, and grain storage. Open and verify each individual document before citing it.',
      url: 'https://inva.dz/techniques-agricoles/',
      kindAr: 'فهرس رسمي لوثائق إرشادية',
      kindFr: 'Catalogue officiel de vulgarisation',
      kindEn: 'Official extension-document catalogue',
    ),
    _AgriculturalSource(
      id: 'INVA-GED-001',
      titleAr: 'المكتبة الرقمية GED — المعهد الوطني للإرشاد الفلاحي',
      titleFr: 'Bibliothèque numérique GED — INVA',
      titleEn: 'Digital library GED — INVA',
      organisation: 'INVA · وزارة الفلاحة',
      scopeAr: 'تتضمن عناوين منشورات حول أصناف البطاطا الجزائرية، الشعير الصحراوي التقليدي، أصناف الزيتون، أصناف الحبوب، والموارد الوراثية لنخيل التمر.',
      scopeFr: 'Répertorie notamment des fiches de variétés de pomme de terre algériennes, des orges sahariennes traditionnelles, des variétés d’olivier et de céréales, ainsi que les ressources génétiques du palmier dattier.',
      scopeEn: 'Lists publications on Algerian potato varieties, traditional Saharan barley, olive and cereal varieties, and date-palm genetic resources.',
      url: 'https://inva.dz/ged/',
      kindAr: 'مكتبة وثائق رسمية',
      kindFr: 'Bibliothèque documentaire officielle',
      kindEn: 'Official document library',
    ),
    _AgriculturalSource(
      id: 'INVA-AGRINFO-001',
      titleAr: 'بوابة Agri Info — معلومات وإرشاد فلاحي',
      titleFr: 'Portail Agri Info — information agricole',
      titleEn: 'Agri Info — agricultural information portal',
      organisation: 'INVA · وزارة الفلاحة',
      scopeAr: 'بوابة إرشاد تعرض تنبيهات زراعية ونصائح جوية زراعية وأدلة وفيديوهات ومعلومات حسب الولايات. التنبيهات مرتبطة بتاريخها ونطاقها ولا تُعامل كتنبيه حالي بعد انتهاء مدتها.',
      scopeFr: 'Portail de vulgarisation proposant des alertes agricoles, conseils agrométéorologiques, guides, vidéos et informations par wilaya. Une alerte expirée ne doit pas être présentée comme actuelle.',
      scopeEn: 'An extension portal with agricultural alerts, agrometeorological advice, guides, videos, and wilaya-related information. Expired alerts must never be presented as current.',
      url: 'https://agri-info.inva.dz/',
      kindAr: 'بوابة إرشاد حكومية',
      kindFr: 'Portail public de vulgarisation',
      kindEn: 'Public agricultural extension portal',
    ),
    _AgriculturalSource(
      id: 'ITGC-CEREALS-001',
      titleAr: 'الدليل التطبيقي لزراعة الحبوب الخريفية',
      titleFr: 'Guide pratique de la conduite des céréales d’automne',
      titleEn: 'Practical guide to autumn cereal production',
      organisation: 'ITGC · المعهد التقني للمحاصيل الكبرى',
      scopeAr: 'مرجع تقني للحبوب، يتناول المناطق الزراعية والمتطلبات البيئية والماء والتربة والحرارة ومراحل نمو النبات ومكونات المردود. يُراجع تاريخ الغلاف والطبعة قبل استخدام الأرقام.',
      scopeFr: 'Guide technique sur les céréales : zones de production, exigences agroécologiques, eau, sol, température, stades de développement et composantes du rendement. Vérifier l’édition avant d’utiliser des chiffres.',
      scopeEn: 'Technical cereal guide covering production zones, agroecological requirements, water, soil, temperature, plant development, and yield components. Check the edition before reusing figures.',
      url: 'https://www.itgc.dz/wp-content/uploads/2019/04/Guide-pratique-de-la-conduite-des-c%C3%A9r%C3%A9ales-dautomne.pdf',
      kindAr: 'دليل تقني PDF',
      kindFr: 'Guide technique PDF',
      kindEn: 'Technical PDF guide',
    ),
    _AgriculturalSource(
      id: 'ITGC-LENTIL-001',
      titleAr: 'دليل العدس — الإنتاج والتقنيات',
      titleFr: 'Guide technique de la lentille',
      titleEn: 'Lentil technical guide',
      organisation: 'ITGC · المعهد التقني للمحاصيل الكبرى',
      scopeAr: 'مرجع متخصص للبقوليات والعدس في الجزائر، يتناول متطلبات الإنتاج والإنشاء والتسميد والحماية والتخزين. يجب توثيق الطبعة وتاريخ الوثيقة من الغلاف.',
      scopeFr: 'Référence sur les légumineuses et la lentille en Algérie : installation de la culture, fertilisation, protection et stockage. Relever l’édition et la date sur la page de couverture.',
      scopeEn: 'A reference on legumes and lentil production in Algeria, including crop establishment, fertilization, protection, and storage. Record the edition and date from the cover.',
      url: 'https://www.itgc.dz/wp-content/uploads/2019/07/LA-LENTILLE.pdf',
      kindAr: 'دليل تقني PDF',
      kindFr: 'Guide technique PDF',
      kindEn: 'Technical PDF guide',
    ),
    _AgriculturalSource(
      id: 'INPV-NOTE-2025-01',
      titleAr: 'التنبيه التقني الشتوي للأشجار المثمرة والكروم',
      titleFr: 'Alerte technique hivernale — arbres fruitiers et vigne',
      titleEn: 'Winter technical alert — fruit trees and vines',
      organisation: 'INPV · المعهد الوطني لحماية النباتات',
      scopeAr: 'وثيقة دعم تقني مؤرخة في 2 يناير 2025، تذكر ممارسات وقائية ونظافة بستانية. مرجع تاريخي/تقني وليس تنبيهًا حاليًا. لا تُحوّل فقرة المبيدات إلى وصفة؛ يُرجع دائمًا إلى منتج مرخص وتوصية محلية حديثة.',
      scopeFr: 'Note d’appui technique datée du 2 janvier 2025 sur des mesures préventives et l’hygiène du verger. Référence datée, pas une alerte actuelle. Ne pas transformer le passage sur les pesticides en prescription ; vérifier l’homologation et les recommandations locales à jour.',
      scopeEn: 'A technical support note dated 2 January 2025 on preventive orchard practices. It is a dated reference, not a current alert. Do not turn its pesticide passage into a prescription; check current local guidance and product registration.',
      url: 'https://inpv.dz/assets/images/ALERTD-80.pdf',
      kindAr: 'وثيقة دعم تقني · 02/01/2025',
      kindFr: 'Note technique · 02/01/2025',
      kindEn: 'Technical note · 2 Jan 2025',
    ),
    _AgriculturalSource(
      id: 'INRAA-INSTITUTION-001',
      titleAr: 'المعهد الوطني الجزائري للبحث الزراعي INRAA',
      titleFr: 'Institut National de la Recherche Agronomique d’Algérie',
      titleEn: 'National Institute of Agronomic Research of Algeria',
      organisation: 'INRAA · مؤسسة بحث علمي وتكنولوجي',
      scopeAr: 'جهة بحث وطنية تغطي مجالات الفلاحة والغذاء والموارد المائية والتكنولوجيات الحيوية. صفحة المديرية العامة للبحث العلمي تؤكد التعريف المؤسسي ورابط الموقع الرسمي.',
      scopeFr: 'Institut national de recherche couvrant l’agriculture, l’alimentation, les ressources hydriques et les biotechnologies. La fiche de la DGRSDT confirme l’identification et le site institutionnel.',
      scopeEn: 'National research institute covering agriculture, food, water resources, and biotechnology. The DGRSDT institutional profile confirms the institute and its official website.',
      url: 'https://www.dgrsdt.dz/public/ar/epst/INRA',
      kindAr: 'صفحة تعريف مؤسسية رسمية',
      kindFr: 'Fiche institutionnelle officielle',
      kindEn: 'Official institutional profile',
    ),
    _AgriculturalSource(
      id: 'MADR-INSTITUTES-001',
      titleAr: 'دليل المؤسسات التقنية والبحث العلمي',
      titleFr: 'Annuaire des instituts techniques et de recherche',
      titleEn: 'Directory of technical and research institutes',
      organisation: 'وزارة الفلاحة والتنمية الريفية',
      scopeAr: 'دليل رسمي يذكر مؤسسات مرجعية منها INRAA وINMV وINPV وINVA وITELV وITGC وITAFV وINSID وITDAS وCNCC. يُستخدم للتحقق من أسماء المؤسسات واختصاصاتها، وليس بديلًا عن منشوراتها التقنية.',
      scopeFr: 'Annuaire officiel répertoriant notamment INRAA, INMV, INPV, INVA, ITELV, ITGC, ITAFV, INSID, ITDAS et CNCC. Il sert à vérifier les organismes, pas à remplacer leurs publications techniques.',
      scopeEn: 'Official directory listing institutions including INRAA, INMV, INPV, INVA, ITELV, ITGC, ITAFV, INSID, ITDAS, and CNCC. Use it to verify institutional identity, not as a substitute for technical publications.',
      url: 'https://madr.gov.dz/contact/%D8%AF%D9%84%D9%8A%D9%84-%D8%A7%D9%84%D9%87%D8%A7%D8%AA%D9%81/',
      kindAr: 'دليل رسمي للوزارة',
      kindFr: 'Annuaire officiel du ministère',
      kindEn: 'Official ministry directory',
    ),
    _AgriculturalSource(
      id: 'INVA-AGRAL-001',
      titleAr: 'شبكة AGRAL للتوثيق الزراعي الوطني',
      titleFr: 'Réseau AGRAL — documentation agricole nationale',
      titleEn: 'AGRAL — national agricultural documentation network',
      organisation: 'INVA · شبكة توثيق وطنية',
      scopeAr: 'تصف INVA الشبكة كنظام تعاوني وطني لجمع وتحليل وحفظ وتبادل المعلومات العلمية والتقنية الزراعية، بمشاركة مكتبات المعاهد التقنية ومراكز المعلومات.',
      scopeFr: 'L’INVA décrit AGRAL comme un système coopératif national de collecte, d’analyse, de conservation et de diffusion de l’information scientifique et technique agricole, avec les bibliothèques des instituts et centres participants.',
      scopeEn: 'INVA describes AGRAL as a national cooperative system for collecting, analysing, storing, and sharing agricultural scientific and technical information, with participating institute libraries and information centres.',
      url: 'https://inva.dz/reseau-agral/',
      kindAr: 'مرجع لنظام التوثيق الوطني',
      kindFr: 'Référence du système national documentaire',
      kindEn: 'National documentation-system reference',
    ),
  ];

  Future<void> _openSource(BuildContext context, _AgriculturalSource source) async {
    final uri = Uri.tryParse(source.url);
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(source.url)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = state.language;
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: tr(state, 'sources'),
            subtitle: tr(state, 'sourcesSub'),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fact_check_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 9),
                      Text(
                        tr(state, 'sourcePolicy'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    tr(state, 'sourcePolicyNote'),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.55,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    tr(state, 'sourceIndexNote'),
                    style: const TextStyle(fontSize: 11, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          ..._sources.map((source) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.menu_book_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  source.title(language),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  source.organisation,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Text(
                        source.scope(language),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(source.kind(language)),
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            tr(state, 'sourceChecked'),
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'ID: ${source.id}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        source.url,
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: OutlinedButton.icon(
                          onPressed: () => _openSource(context, source),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text(tr(state, 'sourceOpen')),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
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
        Text(tr(state, state.api.isSignedIn ? 'onlineBackend' : 'backendNote'), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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
