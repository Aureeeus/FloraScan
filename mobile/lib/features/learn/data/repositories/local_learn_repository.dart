import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/agronomy_article_model.dart';
import '../../domain/entities/atlas_condition_model.dart';
import '../../domain/entities/glossary_term_model.dart';
import '../../domain/entities/lesson_definition.dart';
import '../../domain/entities/lesson_progress.dart';
import '../../domain/repositories/learn_repository.dart';

/// Production implementation of [LearnRepository] backed by local pathology knowledge base assets and SQLite persistence.
class LocalLearnRepository implements LearnRepository {
  LocalLearnRepository({this.appDatabase});

  final AppDatabase? appDatabase;
  List<AgronomyArticle>? _cachedArticles;

  final Map<String, LessonProgress> _progressMemory = {
    'lesson_1': const LessonProgress(lessonId: 'lesson_1', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_2': const LessonProgress(lessonId: 'lesson_2', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_3': const LessonProgress(lessonId: 'lesson_3', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_4': const LessonProgress(lessonId: 'lesson_4', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_5': const LessonProgress(lessonId: 'lesson_5', isCompleted: false, lastStep: 0, totalSteps: 4),
    'lesson_6': const LessonProgress(lessonId: 'lesson_6', isCompleted: false, lastStep: 0, totalSteps: 4),
  };

  static const List<LessonDefinition> _kLessons = [
    LessonDefinition(
      id: 'lesson_1',
      number: 1,
      title: 'Charging & Pairing Wand',
      subtitle: 'Fast BLE auto-pair in garden yard',
      duration: '30s',
      icon: Icons.bluetooth_connected,
      steps: [
        LessonStepData(
          stepNumber: 1,
          title: 'Fast BLE Auto-Pairing',
          goodTip: 'Hold probe 2s near phone. Connects instantly.',
          poorTip: 'Don\'t open phone Bluetooth menu. App auto-pairs.',
        ),
        LessonStepData(
          stepNumber: 2,
          title: 'USB-C Charging & Status LED',
          goodTip: 'Charge wand until LED turns solid green. Lasts 3 weeks.',
          poorTip: 'Don\'t test moist soil while probe is plugged into power.',
        ),
        LessonStepData(
          stepNumber: 3,
          title: 'Capacitive Air Baseline',
          goodTip: 'Keep prongs dry and in open air during 2s boot calibration.',
          poorTip: 'Don\'t touch sensing prongs with wet fingers during power-up.',
        ),
        LessonStepData(
          stepNumber: 4,
          title: 'Connection Status Verification',
          goodTip: 'Confirm Wand connection status shows connected in top header.',
          poorTip: 'Don\'t probe plants if the wand is disconnected or out of Bluetooth range.',
        ),
      ],
    ),
    LessonDefinition(
      id: 'lesson_2',
      number: 2,
      title: 'Using Wand in Soil',
      subtitle: '5cm depth, ideal moisture & saucer triage',
      duration: '45s',
      icon: Icons.water_drop,
      steps: [
        LessonStepData(
          stepNumber: 1,
          title: 'The 5 cm Soil Rule & Triage',
          goodTip: 'Insert prongs 5cm deep midway between stem & pot rim.',
          poorTip: 'Don\'t touch bare surface soil or hit pot edge.',
        ),
        LessonStepData(
          stepNumber: 2,
          title: 'Reading Soil Moisture',
          goodTip: 'Keep Nightshade root-zone soil consistently moist (25% to 35%).',
          poorTip: 'Don\'t let soil dry below 15% (drought) or exceed 40% (waterlogged).',
        ),
        LessonStepData(
          stepNumber: 3,
          title: 'Saucer Drainage Triage',
          goodTip: 'Empty runoff saucer 20 mins after deep watering to aerate roots.',
          poorTip: 'Never leave container pots sitting in stagnant drainage water.',
        ),
        LessonStepData(
          stepNumber: 4,
          title: 'Wiping & Maintaining Prongs',
          goodTip: 'Wipe stainless sensor prongs with a clean dry cloth after readings.',
          poorTip: 'Don\'t use metal wire pads or harsh abrasives on probe tips.',
        ),
      ],
    ),
    LessonDefinition(
      id: 'lesson_3',
      number: 3,
      title: 'How to Take a Good Leaf Photo',
      subtitle: 'Avoid glare & blurry focus in direct afternoon sunlight.',
      duration: '45s',
      icon: Icons.photo_camera,
      steps: [
        LessonStepData(
          stepNumber: 1,
          title: 'Compare Sharp vs Blurry',
          goodTip: 'Sharp focus on leaf veins under daylight.',
          poorTip: 'Direct sun flare washes out diagnostic color.',
        ),
        LessonStepData(
          stepNumber: 2,
          title: 'Shading from Midday Sun',
          goodTip: 'Cast a gentle body shadow over leaf to eliminate harsh reflection.',
          poorTip: 'Don\'t photograph leaves with blinding white sun specular spots.',
        ),
        LessonStepData(
          stepNumber: 3,
          title: 'Framing Single Leaf Symptoms',
          goodTip: 'Frame 1 to 2 affected leaves filling 70% of optical reticle.',
          poorTip: 'Don\'t take distant photos of the entire bush from 2 meters away.',
        ),
        LessonStepData(
          stepNumber: 4,
          title: 'Checking Under-Canopy Spots',
          goodTip: 'Gently turn leaf over to inspect underside for fungal spores.',
          poorTip: 'Don\'t tear or snap delicate branches while photographing.',
        ),
      ],
    ),
    LessonDefinition(
      id: 'lesson_4',
      number: 4,
      title: 'Reading Your Result',
      subtitle: 'Sensor tiebreaker: hypoxia vs blight',
      duration: '60s',
      icon: Icons.speed,
      steps: [
        LessonStepData(
          stepNumber: 1,
          title: 'Sensor Tiebreakers & Hypoxia',
          goodTip: 'Check moisture >40% before assuming leaf disease.',
          poorTip: 'Don\'t spray fungicide on overwatered roots.',
        ),
        LessonStepData(
          stepNumber: 2,
          title: 'Confidence Scores & Ambiguity',
          goodTip: 'Scout 2nd leaf if diagnosis confidence is in caution zone (<80%).',
          poorTip: 'Don\'t apply harsh interventions on low-confidence single spots.',
        ),
        LessonStepData(
          stepNumber: 3,
          title: 'Environmental Log-Odds Context',
          goodTip: 'Remember warm humid air speeds up blight; dry air slows it.',
          poorTip: 'Don\'t ignore high humidity (>75% RH) when scheduling watering.',
        ),
        LessonStepData(
          stepNumber: 4,
          title: 'Logging to Plant History',
          goodTip: 'Save scan to plant profile to track symptom progress over 14 days.',
          poorTip: 'Don\'t diagnose without recording the specific plot or pot number.',
        ),
      ],
    ),
    LessonDefinition(
      id: 'lesson_5',
      number: 5,
      title: 'Water & Sun for 3 Crops',
      subtitle: 'Tomato, Chili & Eggplant moisture & sunlight',
      duration: '60s',
      icon: Icons.wb_sunny,
      steps: [
        LessonStepData(
          stepNumber: 1,
          title: 'Crop Light & Moisture Profiles',
          goodTip: 'Keep tomatoes in steady, moist soil; Chili loves warmth.',
          poorTip: 'Don\'t keep nightshade root zones waterlogged.',
        ),
        LessonStepData(
          stepNumber: 2,
          title: 'Tomato Calcium & Water Swings',
          goodTip: 'Consistent watering prevents blossom end rot calcium deficiency.',
          poorTip: 'Don\'t cycle pots between desert-dry and swamp-saturated.',
        ),
        LessonStepData(
          stepNumber: 3,
          title: 'Chili Aeration & Sunlight',
          goodTip: 'Give chilies 6+ hours of full sun; allow top 2cm soil to dry.',
          poorTip: 'Don\'t let chili roots stay chilled in soggy cool compost.',
        ),
        LessonStepData(
          stepNumber: 4,
          title: 'Eggplant Mulching & Feeding',
          goodTip: 'Mulch eggplants 3cm deep to retain steady moisture and warmth.',
          poorTip: 'Don\'t splash muddy soil onto lower eggplant foliage.',
        ),
      ],
    ),
    LessonDefinition(
      id: 'lesson_6',
      number: 6,
      title: 'Safe Garden Treatments',
      subtitle: 'Neem at dusk, bicarb at morning & mulch',
      duration: '45s',
      icon: Icons.sanitizer,
      steps: [
        LessonStepData(
          stepNumber: 1,
          title: 'Safe Home Remedies & Pruning',
          goodTip: 'Apply neem oil at dusk; baking soda in early morning.',
          poorTip: 'Never spray oils at peak midday direct sunlight.',
        ),
        LessonStepData(
          stepNumber: 2,
          title: 'Canopy Airflow Pruning',
          goodTip: 'Prune lowest 15cm foliage to stop soil-borne fungal spores.',
          poorTip: 'Don\'t prune more than 25% of healthy foliage in a single week.',
        ),
        LessonStepData(
          stepNumber: 3,
          title: 'Morning Bicarbonate Spraying',
          goodTip: 'Spray potassium or sodium bicarb at 7 AM so leaves dry fast.',
          poorTip: 'Don\'t spray fungicides at night when leaves stay wet for hours.',
        ),
        LessonStepData(
          stepNumber: 4,
          title: 'Sanitizing Cutting Shears',
          goodTip: 'Wipe pruners with 70% alcohol between trimming different plants.',
          poorTip: 'Don\'t reuse shears on healthy crops after pruning diseased leaves.',
        ),
      ],
    ),
  ];

  static const List<AtlasCondition> _kAtlasConditions = [
    // ---------------------------------------------------------
    // TOMATO PATHOLOGIES (AI Trained Classes - 5 Diseases)
    // ---------------------------------------------------------
    AtlasCondition(
      title: 'Tomato Early Blight',
      pathogen: 'Alternaria solani',
      crop: 'Tomato',
      severityTag: 'HIGH SEVERITY',
      tagBg: AppColors.tertiaryFixed,
      tagColor: AppColors.onTertiaryFixed,
      description: 'Concentric dark rings with yellow halos on mature lower leaves from rain splash. Prune lowest 15cm foliage and apply mulch.',
      recipeLabel: 'Neem (dusk) / 15cm prune',
      symptoms: [
        'Concentric target-like rings with chlorotic yellow halo',
        'Defoliation starting on mature lower canopy foliage',
      ],
      organicTreatment: 'Apply copper octanoate or neem spray at dusk; prune lowest 15cm foliage.',
      chemicalTreatment: 'Rotate preventative chlorothalonil or azoxystrobin fungicides per label intervals.',
      preventativeAction: 'Mulch bare soil with straw to prevent fungal spore splash; avoid overhead sprinkling.',
    ),
    AtlasCondition(
      title: 'Tomato Late Blight',
      pathogen: 'Phytophthora infestans',
      crop: 'Tomato',
      severityTag: 'URGENT OUTBREAK',
      tagBg: AppColors.errorContainer,
      tagColor: AppColors.onErrorContainer,
      description: 'Rapidly expanding water-soaked purplish lesions with white fungal fuzz on leaf undersides in humid mornings.',
      recipeLabel: 'Copper sulfate / Rogue infected',
      symptoms: [
        'Large irregular water-soaked dark olive to purplish lesions',
        'White downy mold sporulation visible on leaf undersides in humid mornings',
      ],
      organicTreatment: 'Immediate foliar copper sulfate application; destroy heavily infected crops.',
      chemicalTreatment: 'Apply systemic cymoxanil, mandipropamid, or metalaxyl upon first regional alert.',
      preventativeAction: 'Scout aggressively during cool, foggy weather; destroy volunteer tomato cull piles.',
    ),
    AtlasCondition(
      title: 'Tomato Septoria Leaf Spot',
      pathogen: 'Septoria lycopersici',
      crop: 'Tomato',
      severityTag: 'MODERATE',
      tagBg: AppColors.secondaryFixed,
      tagColor: AppColors.onSecondaryFixed,
      description: 'Numerous small circular spots with dark brown margins, gray centers, and tiny black pycnidia fruiting bodies.',
      recipeLabel: 'Bacillus subtilis / Strip base',
      symptoms: [
        'Numerous small circular spots with dark brown margins and gray centers',
        'Tiny black pycnidia specks visible within lesion centers',
      ],
      organicTreatment: 'Bio-fungicidal Bacillus subtilis spray; strip bottom 12 inches of foliage.',
      chemicalTreatment: 'Apply chlorothalonil or mancozeb at 7 to 10 day intervals.',
      preventativeAction: 'Avoid overhead watering; disinfect stakes and tomato cages between seasons.',
    ),
    AtlasCondition(
      title: 'Tomato Yellow Leaf Curl',
      pathogen: 'TYLCV Virus',
      crop: 'Tomato',
      severityTag: 'HIGH SEVERITY',
      tagBg: AppColors.tertiaryFixed,
      tagColor: AppColors.onTertiaryFixed,
      description: 'Severe upward leaf cupping, puckering, yellow margins, and stunted terminal growth transmitted by whiteflies.',
      recipeLabel: 'Yellow sticky traps / Insect soap',
      symptoms: [
        'Severe upward leaf curling and cupping with interveinal yellowing',
        'Severe plant stunting and flower abortion leading to minimal fruit set',
      ],
      organicTreatment: 'No viral cure; rogue infected plants; spray insecticidal soap or neem against whiteflies.',
      chemicalTreatment: 'Systemic neonicotinoids or cyantraniliprole targeting Bemisia tabaci vector.',
      preventativeAction: 'Use insect-proof netting (50-mesh) on nurseries; use TYLCV-resistant hybrids.',
    ),
    AtlasCondition(
      title: 'Tomato Leaf Mold',
      pathogen: 'Passalora fulva (Cladosporium)',
      crop: 'Tomato',
      severityTag: 'MODERATE',
      tagBg: AppColors.secondaryFixed,
      tagColor: AppColors.onSecondaryFixed,
      description: 'Pale green to yellow spots on upper leaf surface with olive-green to brown velvety fungal growth on matching undersides.',
      recipeLabel: 'Potassium bicarb / Prune inner',
      symptoms: [
        'Pale green to yellow spots on upper leaf surface',
        'Olive-green to brown velvety fungal growth on matching lower leaf surface',
      ],
      organicTreatment: 'Foliar sulfur dust or potassium bicarbonate spray; prune inner canopy for airflow.',
      chemicalTreatment: 'Apply preventative thiophanate-methyl or azoxystrobin fungicides.',
      preventativeAction: 'Maintain relative humidity below 85% in greenhouse or polytunnel enclosures.',
    ),

    // ---------------------------------------------------------
    // CHILI PATHOLOGIES (AI Trained Classes - 6 Diseases)
    // ---------------------------------------------------------
    AtlasCondition(
      title: 'Chili Anthracnose',
      pathogen: 'Colletotrichum capsici',
      crop: 'Chili',
      severityTag: 'HIGH SEVERITY',
      tagBg: AppColors.tertiaryFixed,
      tagColor: AppColors.onTertiaryFixed,
      description: 'Circular sunken lesions with spore rings aggravated by wet foliage. Apply bicarb in early morning.',
      recipeLabel: 'Bicarb (morning) / Airflow',
      symptoms: [
        'Sunken circular necrotic lesions with concentric acervuli rings',
        'Black fungal microsclerotia and premature leaf senescence',
      ],
      organicTreatment: 'Neem oil foliar application; wettable sulfur in early morning hours.',
      chemicalTreatment: 'Mancozeb or pyraclostrobin application during early canopy and fruit development.',
      preventativeAction: 'Use certified pathogen-free seeds; practice 3-year Solanaceae crop rotation.',
    ),
    AtlasCondition(
      title: 'Chili Bacterial Spot',
      pathogen: 'Xanthomonas campestris pv. vesicatoria',
      crop: 'Chili',
      severityTag: 'MODERATE',
      tagBg: AppColors.secondaryFixed,
      tagColor: AppColors.onSecondaryFixed,
      description: 'Small dark water-soaked spots enlarging into circular brown lesions with yellow chlorotic borders.',
      recipeLabel: 'Copper hydroxide + Bacillus',
      symptoms: [
        'Small dark water-soaked spots enlarging into circular brown lesions',
        'Lesions blistered or scab-like with yellow chlorotic borders',
      ],
      organicTreatment: 'Copper bactericide (copper hydroxide) combined with biological Bacillus subtilis.',
      chemicalTreatment: 'Streptomycin sulfate tank-mix where locally registered for agricultural use.',
      preventativeAction: 'Sanitize seed with hot-water treatment (50°C for 25 min); avoid handling wet plants.',
    ),
    AtlasCondition(
      title: 'Chili Frogeye Leaf Spot',
      pathogen: 'Cercospora capsici',
      crop: 'Chili',
      severityTag: 'MODERATE',
      tagBg: AppColors.secondaryFixed,
      tagColor: AppColors.onSecondaryFixed,
      description: 'Circular lesions with light gray centers and prominent dark brown borders; premature defoliation in warm humidity.',
      recipeLabel: 'Copper octanoate / Clean debris',
      symptoms: [
        'Circular lesions with light gray centers and prominent dark brown borders',
        'Premature defoliation starting from the lower canopy during humid periods',
      ],
      organicTreatment: 'Apply copper octanoate; remove fallen infected debris to lower inoculum.',
      chemicalTreatment: 'Apply chlorothalonil or carbendazim preventative sprays at 10-day intervals.',
      preventativeAction: 'Maintain adequate spacing; mulch beds with rice straw or plastic film.',
    ),
    AtlasCondition(
      title: 'Chili Leaf Curl Virus',
      pathogen: 'ChiLCV Virus',
      crop: 'Chili',
      severityTag: 'HIGH SEVERITY',
      tagBg: AppColors.tertiaryFixed,
      tagColor: AppColors.onTertiaryFixed,
      description: 'Severe upward leaf puckering, vein thickening, and bushiness caused by whitefly vector transmission.',
      recipeLabel: 'Silver mulch / Repel vectors',
      symptoms: [
        'Upward curling, puckering, and crinkling of leaf blades',
        'Severe vein thickening, bushiness, and stunted terminal growth',
      ],
      organicTreatment: 'Rogue out symptomatic plants; spray mineral oil or neem to repel whiteflies and thrips.',
      chemicalTreatment: 'Imidacloprid or diafenthiuron applied to suppress vector whitefly populations.',
      preventativeAction: 'Install silver reflective mulches; cultivate maize or sorghum border trap crops.',
    ),
    AtlasCondition(
      title: 'Chili Nutrient Deficiency Chlorosis',
      pathogen: 'Abiotic (Fe / N / Mg deficit)',
      crop: 'Chili',
      severityTag: 'MODERATE',
      tagBg: AppColors.secondaryFixed,
      tagColor: AppColors.onSecondaryFixed,
      description: 'Interveinal chlorosis on young foliage or generalized pale yellowing without fungal or bacterial lesion borders.',
      recipeLabel: 'Chelated iron / Balanced NPK',
      symptoms: [
        'Interveinal chlorosis on young foliage (Fe) or generalized pale yellowing on older leaves (N)',
        'Stunted vegetative expansion without distinct fungal or bacterial lesion borders',
      ],
      organicTreatment: 'Apply chelated iron or balanced foliar seaweed and fish amino acid extract.',
      chemicalTreatment: 'Foliar application of 19-19-19 water-soluble NPK fertilizer with micronutrients.',
      preventativeAction: 'Conduct routine soil pH testing; maintain soil pH between 6.0 and 6.8.',
    ),
    AtlasCondition(
      title: 'Chili White Spot Disease',
      pathogen: 'Pseudocercospora capsicicola',
      crop: 'Chili',
      severityTag: 'MODERATE',
      tagBg: AppColors.secondaryFixed,
      tagColor: AppColors.onSecondaryFixed,
      description: 'Small bleached chalk-white spots across leaf lamina prone to tearing and shot-hole perforations under wind.',
      recipeLabel: 'Copper spray / Canopy airflow',
      symptoms: [
        'Small bleached chalk-white or off-white spots across leaf surface',
        'Thinning leaf tissue susceptible to shot-hole tearing under wind',
      ],
      organicTreatment: 'Protective copper fungicide spray; improve plant nutrition and vigor.',
      chemicalTreatment: 'Difenoconazole or tebuconazole spray at early disease detection.',
      preventativeAction: 'Avoid overhead water splash; ensure good air movement through pruning.',
    ),

    // ---------------------------------------------------------
    // EGGPLANT PATHOLOGIES (AI Trained Classes - 6 Diseases)
    // ---------------------------------------------------------
    AtlasCondition(
      title: 'Eggplant Insect Pest Infestation',
      pathogen: 'Epitrix spp. / Leucinodes orbonalis',
      crop: 'Eggplant',
      severityTag: 'MODERATE',
      tagBg: AppColors.secondaryFixed,
      tagColor: AppColors.onSecondaryFixed,
      description: 'Shot-hole perforations across foliage from flea beetles and wilting terminal shoots from shoot borers.',
      recipeLabel: 'Neem oil (0.5%) / Sticky traps',
      symptoms: [
        'Shot-hole perforations across foliage from flea beetles',
        'Chewed leaf margins and wilting terminal shoots from shoot borers',
      ],
      organicTreatment: 'Apply neem oil (0.5%) spray or pyrethrin-based botanical extract in early morning.',
      chemicalTreatment: 'Rotate targeted insecticides (e.g., chlorantraniliprole or spinosad per label instructions).',
      preventativeAction: 'Deploy yellow sticky traps and pheromone traps across the field perimeter.',
    ),
    AtlasCondition(
      title: 'Eggplant Cercospora Leaf Spot',
      pathogen: 'Cercospora melongenae',
      crop: 'Eggplant',
      severityTag: 'MODERATE',
      tagBg: AppColors.secondaryFixed,
      tagColor: AppColors.onSecondaryFixed,
      description: 'Circular to irregular chlorotic spots turning gray-brown with concentric margins on mature lower foliage.',
      recipeLabel: 'Copper spray / Canopy spacing',
      symptoms: [
        'Circular to irregular chlorotic spots turning gray-brown',
        'Concentric rings with darker margins on mature lower leaves',
      ],
      organicTreatment: 'Copper hydroxide or copper octanoate protective spray; remove lower infected foliage.',
      chemicalTreatment: 'Apply preventative mancozeb or difenoconazole at first lesion onset.',
      preventativeAction: 'Promote wide row spacing for canopy airflow; avoid overhead sprinkler irrigation.',
    ),
    AtlasCondition(
      title: 'Eggplant Mosaic Virus',
      pathogen: 'Tobacco / Cucumber Mosaic Virus',
      crop: 'Eggplant',
      severityTag: 'HIGH SEVERITY',
      tagBg: AppColors.tertiaryFixed,
      tagColor: AppColors.onTertiaryFixed,
      description: 'Interveinal mosaic mottling with alternating light and dark green patches, leaf puckering, and stunting.',
      recipeLabel: 'Rogue plants / Sanitize tools',
      symptoms: [
        'Interveinal mosaic mottling with alternating light and dark green patches',
        'Leaf puckering, distortion, and stunted canopy growth',
      ],
      organicTreatment: 'No curative treatment exists; rogue out and destroy severely infected plants immediately.',
      chemicalTreatment: 'Control vector aphid and thrip populations using systemic insecticide.',
      preventativeAction: 'Disinfect tools with 10% trisodium phosphate; sanitize hands between plants.',
    ),
    AtlasCondition(
      title: 'Eggplant Little Leaf Disease',
      pathogen: 'Phytoplasma (Hishimonus phycitis vector)',
      crop: 'Eggplant',
      severityTag: 'HIGH SEVERITY',
      tagBg: AppColors.tertiaryFixed,
      tagColor: AppColors.onTertiaryFixed,
      description: 'Severe leaf miniaturization, shortened internodes, and excessive bushy shoots with floral phyllody.',
      recipeLabel: 'Uproot & burn / Vector control',
      symptoms: [
        'Severe leaf miniaturization and shortened internodes',
        'Excessive bushy shoots with phyllody (floral parts transformed into leaves)',
      ],
      organicTreatment: 'Uproot and burn diseased plants; spray botanical neem repellent against leafhoppers.',
      chemicalTreatment: 'Apply imidacloprid or dimethoate to suppress vector leafhopper populations.',
      preventativeAction: 'Eradicate alternate weed hosts around the plot perimeter before planting.',
    ),
    AtlasCondition(
      title: 'Eggplant White Mold',
      pathogen: 'Sclerotinia sclerotiorum',
      crop: 'Eggplant',
      severityTag: 'URGENT OUTBREAK',
      tagBg: AppColors.errorContainer,
      tagColor: AppColors.onErrorContainer,
      description: 'Cottony white mycelial fungal growth on leaves and stem base, forming black sclerotia bodies.',
      recipeLabel: 'Trichoderma / Improve drainage',
      symptoms: [
        'Cottony white mycelial fungal growth on leaves and stem base',
        'Black irregular sclerotia bodies embedded within collapsing tissue',
      ],
      organicTreatment: 'Soil drench with antagonistic Trichoderma harzianum; prune infected branches.',
      chemicalTreatment: 'Apply preventative boscalid, cyprodinil, or iprodione during high humidity.',
      preventativeAction: 'Practice 3-year non-host crop rotation; improve soil drainage and reduce plant density.',
    ),
    AtlasCondition(
      title: 'Eggplant Bacterial Wilt',
      pathogen: 'Ralstonia solanacearum',
      crop: 'Eggplant',
      severityTag: 'URGENT OUTBREAK',
      tagBg: AppColors.errorContainer,
      tagColor: AppColors.onErrorContainer,
      description: 'Rapid daytime wilting without prominent initial leaf yellowing, followed by vascular browning and collapse.',
      recipeLabel: 'Rogue plant / Bio-fumigation',
      symptoms: [
        'Rapid daytime wilting without prominent initial leaf yellowing',
        'Vascular browning and milky bacterial ooze when stem is placed in clear water',
      ],
      organicTreatment: 'Incorporate bio-fumigant mustard cover crops; rogue out wilted specimens immediately.',
      chemicalTreatment: 'No effective chemical curative; copper bactericides provide limited soil suppression.',
      preventativeAction: 'Graft commercial varieties onto resistant rootstocks; maintain raised beds.',
    ),
  ];

  static const List<GlossaryTerm> _kGlossaryTerms = [
    GlossaryTerm(
      term: 'Abiotic Stress',
      meaning: 'Non-living stressors such as drought, heatwaves, or soil waterlogging vs living pathogens.',
      category: 'Physiology',
    ),
    GlossaryTerm(
      term: 'Blight (Alternaria)',
      meaning: 'Fungal infection causing circular brown rings with yellow chlorotic halos on lower foliage.',
      category: 'Pathology',
    ),
    GlossaryTerm(
      term: 'Chlorosis',
      meaning: 'Yellowing of leaf tissue from root hypoxia, nutrient starvation, or fungal infection.',
      category: 'Symptoms',
    ),
    GlossaryTerm(
      term: 'Offline Diagnostics',
      meaning: 'On-device disease identification that functions in the field without cellular internet.',
      category: 'Technology',
    ),
    GlossaryTerm(
      term: 'Overwatering Triage',
      meaning: 'Empty drip saucer immediately; if soil remains soggy, amend potting mix with 20–30% perlite.',
      category: 'Management',
    ),
    GlossaryTerm(
      term: 'Solanaceae (Nightshades)',
      meaning: 'Plant family including sweet plum tomato, red habanero chili, and black beauty eggplant.',
      category: 'Botany',
    ),
    GlossaryTerm(
      term: 'Spray Timing',
      meaning: 'Apply neem oil at dusk to protect pollinators and prevent sun scorch; apply bicarb in early morning.',
      category: 'Management',
    ),
    GlossaryTerm(
      term: 'Soil Moisture Percentage',
      meaning: 'Percentage of water held in root-zone soil, measured 5cm deep by the FloraWand (25–35% is ideal).',
      category: 'Telemetry',
    ),
    GlossaryTerm(
      term: 'Canopy Airflow',
      meaning: 'Strategic pruning of basal foliage (15cm) to lower humidity and stop fungal spores splashing from soil.',
      category: 'Cultural',
    ),
    GlossaryTerm(
      term: 'Bio-fungicide',
      meaning: 'Beneficial bacterial strains (such as Bacillus subtilis) that suppress pathogenic foliar fungi organically.',
      category: 'Treatments',
    ),
  ];

  Future<List<AgronomyArticle>> _loadArticles() async {
    if (_cachedArticles != null) {
      return _cachedArticles!;
    }

    try {
      final jsonStr = await rootBundle.loadString('assets/models/pathology_registry.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final classes = data['classes'] as List<dynamic>? ?? [];

      final articles = <AgronomyArticle>[];
      for (final item in classes) {
        if (item is Map<String, dynamic>) {
          final id = item['id'] as String? ?? '';
          final crop = item['crop'] as String? ?? 'General';
          final name = item['displayName'] as String? ?? 'Plant Pathology Guide';
          final pathogen = item['scientificPathogen'] as String? ?? '';
          final symptoms = (item['symptoms'] as List<dynamic>?)?.join('; ') ?? '';
          final organic = item['organicTreatment'] as String? ?? '';
          final chemical = item['chemicalTreatment'] as String? ?? '';
          final prevent = item['preventativeAction'] as String? ?? '';

          articles.add(
            AgronomyArticle(
              id: id,
              title: '$crop: $name ($pathogen)',
              targetCrop: crop,
              category: AgronomyCategory.pathology,
              readTimeMinutes: 4,
              summary: symptoms.isNotEmpty ? symptoms : 'Comprehensive scouting and management protocol.',
              content: 'Pathogen: $pathogen.\n\nKey Symptoms: $symptoms\n\nOrganic Action: $organic\n\nChemical Protocol: $chemical\n\nPrevention: $prevent',
            ),
          );
        }
      }
      _cachedArticles = articles;
    } catch (_) {
      _cachedArticles = const [
        AgronomyArticle(
          id: 'art_01',
          title: 'Managing Early Blight (Alternaria solani) in Solanaceae',
          targetCrop: 'Tomato & Eggplant',
          category: AgronomyCategory.pathology,
          readTimeMinutes: 4,
          summary: 'Mitigate lower canopy humidity and employ bio-fungicides effectively.',
          content: 'Early blight develops rapidly when foliage remains damp for extended periods.',
        ),
      ];
    }

    return _cachedArticles!;
  }

  @override
  Future<List<AgronomyArticle>> fetchAllArticles() async {
    return _loadArticles();
  }

  @override
  Future<List<AgronomyArticle>> fetchArticlesByCrop(String crop) async {
    final all = await _loadArticles();
    return all.where((a) => a.targetCrop.toLowerCase().contains(crop.toLowerCase())).toList();
  }

  @override
  Future<List<LessonDefinition>> fetchLessons() async {
    return _kLessons;
  }

  @override
  Future<List<AtlasCondition>> fetchAtlasConditions() async {
    return _kAtlasConditions;
  }

  @override
  Future<List<GlossaryTerm>> fetchGlossaryTerms() async {
    return _kGlossaryTerms;
  }

  @override
  Future<Map<String, LessonProgress>> fetchAllProgress() async {
    final appDb = appDatabase;
    if (appDb != null) {
      try {
        final db = await appDb.database;
        final rows = await db.query('lesson_progress');
        if (rows.isNotEmpty) {
          final result = <String, LessonProgress>{};
          for (final row in rows) {
            final progress = LessonProgress.fromMap(row);
            result[progress.lessonId] = progress;
            _progressMemory[progress.lessonId] = progress;
          }
          return result;
        } else {
          // If table exists but is empty, seed with initial defaults
          for (final entry in _progressMemory.entries) {
            await db.insert(
              'lesson_progress',
              entry.value.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      } catch (_) {
        // Fallback to in-memory state on error or if table uninitialized
      }
    }
    return Map<String, LessonProgress>.from(_progressMemory);
  }

  @override
  Future<void> saveProgress(LessonProgress progress) async {
    _progressMemory[progress.lessonId] = progress;
    final appDb = appDatabase;
    if (appDb != null) {
      try {
        final db = await appDb.database;
        await db.insert(
          'lesson_progress',
          progress.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {
        // Retain in-memory fallback
      }
    }
  }

  @override
  Future<void> resetAllProgress() async {
    for (final key in _progressMemory.keys) {
      _progressMemory[key] = LessonProgress(lessonId: key, isCompleted: false, lastStep: 0, totalSteps: 4);
    }
    final appDb = appDatabase;
    if (appDb != null) {
      try {
        final db = await appDb.database;
        await db.delete('lesson_progress');
        for (final p in _progressMemory.values) {
          await db.insert('lesson_progress', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      } catch (_) {
        // Retain in-memory fallback
      }
    }
  }
}
