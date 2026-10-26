import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';

/// Clean, lightweight localization contract adhering to KISS, SSOT, and Clean Architecture.
abstract class AppLocalizations {
  const AppLocalizations();

  // Bottom Navigation
  String get navHome;
  String get navMyPlants;
  String get navScan;
  String get navLearn;
  String get navSettings;

  // Settings Screen
  String get settingsHeaderTitle;
  String get settingsHeaderSubtitle;
  String get sectionBiometricWand;
  String get sectionGardenOps;
  String get sectionEdgeAi;
  String get sectionDataPrivacy;

  String get displayTheme;
  String get themeLight;
  String get themeDark;
  String get themeSystem;

  String get operatingScale;
  String get homeGarden;
  String get homeGardenDesc;
  String get farmScale;
  String get farmScaleDesc;

  String get language;
  String get english;
  String get filipino;

  String get temperatureMetric;
  String get temperatureMetricDesc;

  String get dailyInspection;
  String get dailyInspectionDesc;
  String get localNotificationsDesc;

  String get zeroTrackingTitle;
  String get zeroTrackingDesc;

  // Wand & Telemetry
  String get wandOnline;
  String get wandOffline;
  String get wandScanning;
  String get wandConnecting;
  String get wandError;
  String get noWandStreaming;
  String get pairConnectWand;
  String get pairNewWand;
  String get disconnect;
  String get wandDisconnected;

  String get moisture;
  String get temp;
  String get humidity;
  String get light;
  String get probeInSoil;
  String get probeOpenAir;

  String get guidedCalibrationTitle;
  String get guidedCalibrationDesc;
  String get soilCalibration;
  String get luxCalibration;

  // Telemetry status tags
  String get optimal;
  String get good;
  String get waterlogged;
  String get tooDry;
  String get tooHot;
  String get tooCold;
  String get highMoldRisk;
  String get dryAir;
}

/// English localization implementation.
class AppLocalizationsEn extends AppLocalizations {
  const AppLocalizationsEn();

  @override
  String get navHome => 'Home';
  @override
  String get navMyPlants => 'My Plants';
  @override
  String get navScan => 'Scan';
  @override
  String get navLearn => 'Learn';
  @override
  String get navSettings => 'Settings';

  @override
  String get settingsHeaderTitle => 'App & Hardware Settings';
  @override
  String get settingsHeaderSubtitle => 'Configured for standalone off-grid field agronomy';
  @override
  String get sectionBiometricWand => 'Biometric sensor wand';
  @override
  String get sectionGardenOps => 'Garden operations & display';
  @override
  String get sectionEdgeAi => 'Offline edge AI (ONNX bundled)';
  @override
  String get sectionDataPrivacy => 'Data, privacy & local storage';

  @override
  String get displayTheme => 'Display Theme';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeSystem => 'System';

  @override
  String get operatingScale => 'Operating Scale';
  @override
  String get homeGarden => 'Home Garden';
  @override
  String get homeGardenDesc => '(Pots & Balcony)';
  @override
  String get farmScale => 'Farm Scale';
  @override
  String get farmScaleDesc => '(Zones & Rows)';

  @override
  String get language => 'Language';
  @override
  String get english => 'English';
  @override
  String get filipino => 'Filipino';

  @override
  String get temperatureMetric => 'Temperature Metric';
  @override
  String get temperatureMetricDesc => 'Sensor wand probe display unit';

  @override
  String get dailyInspection => 'Daily Soil Inspection';
  @override
  String get dailyInspectionDesc => 'Morning wand check at 7:30 AM';
  @override
  String get localNotificationsDesc => '100% local hardware notifications. Never relies on cellular or internet.';

  @override
  String get zeroTrackingTitle => 'Zero External Tracking Guarantee';
  @override
  String get zeroTrackingDesc => 'All agricultural images and sensor records remain strictly on this device. You retain 100% data ownership.';

  @override
  String get wandOnline => 'FloraWand Online';
  @override
  String get wandOffline => 'FloraWand Offline';
  @override
  String get wandScanning => 'Scanning for nearby FloraWand...';
  @override
  String get wandConnecting => 'Establishing secure BLE link...';
  @override
  String get wandError => 'Connection Error';
  @override
  String get noWandStreaming => 'No hardware wand is actively streaming. Bring your FloraWand nearby and tap pair to sync real-time soil biometrics.';
  @override
  String get pairConnectWand => 'Pair & Connect FloraWand';
  @override
  String get pairNewWand => 'Pair New Wand';
  @override
  String get disconnect => 'Disconnect';
  @override
  String get wandDisconnected => 'Wand disconnected safely.';

  @override
  String get moisture => 'Moisture';
  @override
  String get temp => 'Temp';
  @override
  String get humidity => 'Humidity';
  @override
  String get light => 'Light';
  @override
  String get probeInSoil => 'Probe: In Soil';
  @override
  String get probeOpenAir => 'Probe: Open Air';

  @override
  String get guidedCalibrationTitle => 'Guided Probe Calibration';
  @override
  String get guidedCalibrationDesc => 'Recalibrate field probes seasonally: Zero-point in dry ambient air (0%), saturation probe in distilled water (100%), and zero-lux baseline in covered lens.';
  @override
  String get soilCalibration => 'Soil 0%/100%';
  @override
  String get luxCalibration => 'Lux Zero-Point';

  @override
  String get optimal => 'Optimal';
  @override
  String get good => 'Good';
  @override
  String get waterlogged => 'Waterlogged';
  @override
  String get tooDry => 'Too Dry';
  @override
  String get tooHot => 'Too Hot';
  @override
  String get tooCold => 'Too Cold';
  @override
  String get highMoldRisk => 'High Mold Risk';
  @override
  String get dryAir => 'Dry Air';
}

/// Filipino (Tagalog) localization implementation with authentic agronomy domain phrasing.
class AppLocalizationsFil extends AppLocalizations {
  const AppLocalizationsFil();

  @override
  String get navHome => 'Tahanan';
  @override
  String get navMyPlants => 'Aking Halaman';
  @override
  String get navScan => 'Suriin';
  @override
  String get navLearn => 'Matuto';
  @override
  String get navSettings => 'Mga Setting';

  @override
  String get settingsHeaderTitle => 'Mga Setting ng App at Hardware';
  @override
  String get settingsHeaderSubtitle => 'Naka-configure para sa off-grid na pagsasaka';
  @override
  String get sectionBiometricWand => 'Biometric sensor wand';
  @override
  String get sectionGardenOps => 'Operasyon sa hardin at display';
  @override
  String get sectionEdgeAi => 'Offline edge AI (naka-bundle ang ONNX)';
  @override
  String get sectionDataPrivacy => 'Datos, pribasiya at lokal na imbakan';

  @override
  String get displayTheme => 'Tema ng Display';
  @override
  String get themeLight => 'Maliwanag';
  @override
  String get themeDark => 'Madilim';
  @override
  String get themeSystem => 'Sistema';

  @override
  String get operatingScale => 'Sukat ng Pagtatanim';
  @override
  String get homeGarden => 'Hardin sa Bahay';
  @override
  String get homeGardenDesc => '(Mga Paso at Balkonahe)';
  @override
  String get farmScale => 'Sukat ng Sakahan';
  @override
  String get farmScaleDesc => '(Mga Sona at Hanay)';

  @override
  String get language => 'Wika';
  @override
  String get english => 'English';
  @override
  String get filipino => 'Filipino';

  @override
  String get temperatureMetric => 'Yunit ng Temperatura';
  @override
  String get temperatureMetricDesc => 'Yunit ng display ng sensor wand probe';

  @override
  String get dailyInspection => 'Araw-araw na Pagsusuri ng Lupa';
  @override
  String get dailyInspectionDesc => 'Pagsusuri sa umaga nang 7:30 AM';
  @override
  String get localNotificationsDesc => '100% lokal na abiso sa hardware. Hindi umaasa sa internet.';

  @override
  String get zeroTrackingTitle => 'Garantiyang Walang Panlabas na Pagsubaybay';
  @override
  String get zeroTrackingDesc => 'Lahat ng larawan at datos ng sensor ay nananatili sa aparatong ito. 100% sa iyo ang datos.';

  @override
  String get wandOnline => 'FloraWand Online';
  @override
  String get wandOffline => 'FloraWand Offline';
  @override
  String get wandScanning => 'Naghahanap ng FloraWand...';
  @override
  String get wandConnecting => 'Kumokonekta sa BLE link...';
  @override
  String get wandError => 'Error sa Koneksyon';
  @override
  String get noWandStreaming => 'Walang aktibong sensor wand. Ilapit ang iyong FloraWand at i-tap ang connect upang mai-sync ang mga datos ng lupa.';
  @override
  String get pairConnectWand => 'Ikonekta ang FloraWand';
  @override
  String get pairNewWand => 'Magpares ng Bagong Wand';
  @override
  String get disconnect => 'Idiskonekta';
  @override
  String get wandDisconnected => 'Ligtas na naidiskonekta ang wand.';

  @override
  String get moisture => 'Halumigmig';
  @override
  String get temp => 'Temperatura';
  @override
  String get humidity => 'Halumigmig ng Hangin';
  @override
  String get light => 'Liwanag';
  @override
  String get probeInSoil => 'Probe: Nasa Lupa';
  @override
  String get probeOpenAir => 'Probe: Nakalabas sa Hangin';

  @override
  String get guidedCalibrationTitle => 'Gabay sa Pag-calibrate ng Probe';
  @override
  String get guidedCalibrationDesc => 'I-calibrate ang mga probe ayon sa panahon: Zero-point sa tuyong hangin (0%), saturation sa distilled water (100%), at zero-lux sa natatakpang lente.';
  @override
  String get soilCalibration => 'Lupa 0%/100%';
  @override
  String get luxCalibration => 'Lux Zero-Point';

  @override
  String get optimal => 'Pinakamainam';
  @override
  String get good => 'Maayos';
  @override
  String get waterlogged => 'Labis ang Tubig';
  @override
  String get tooDry => 'Masyadong Tuyo';
  @override
  String get tooHot => 'Masyadong Mainit';
  @override
  String get tooCold => 'Masyadong Malamig';
  @override
  String get highMoldRisk => 'Mataas ang Panganib ng Amag';
  @override
  String get dryAir => 'Tuyong Hangin';
}

/// Reactive Riverpod provider exposing the active [AppLocalizations].
///
/// Reacts to [isEnglishLanguageProvider] with 0ms latency.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final isEnglish = ref.watch(isEnglishLanguageProvider);
  return isEnglish ? const AppLocalizationsEn() : const AppLocalizationsFil();
});
