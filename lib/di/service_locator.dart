import 'package:get_it/get_it.dart';
import '../services/audio_player_service.dart';
import '../services/media_scanner_service.dart';
import '../services/playlist_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<AudioPlayerService>(() => AudioPlayerService());
  locator.registerLazySingleton<MediaScannerService>(() => MediaScannerService());
  locator.registerLazySingleton<PlaylistService>(() => PlaylistService());
}
