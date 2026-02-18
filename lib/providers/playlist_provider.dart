import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistService _service = PlaylistService();

  List<Playlist> _playlists = [];
  List<Song> _favorites = [];
  List<Song> _recentSongs = [];
  bool _isLoading = false;

  // Getters
  List<Playlist> get playlists => _playlists;
  List<Song> get favorites => _favorites;
  List<Song> get recentSongs => _recentSongs;
  bool get isLoading => _isLoading;

  PlaylistProvider() {
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    await loadAll();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      loadPlaylists(),
      loadFavorites(),
      loadRecentSongs(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  // 播放列表
  Future<void> loadPlaylists() async {
    _playlists = await _service.getAllPlaylists();
    notifyListeners();
  }

  Future<Playlist> createPlaylist(String name) async {
    final playlist = await _service.createPlaylist(name);
    await loadPlaylists();
    return playlist;
  }

  Future<void> deletePlaylist(String id) async {
    await _service.deletePlaylist(id);
    await loadPlaylists();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final playlist = await _service.getPlaylist(id);
    if (playlist != null) {
      await _service.updatePlaylist(playlist.copyWith(name: newName));
      await loadPlaylists();
    }
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    await _service.addSongToPlaylist(playlistId, song);
    await loadPlaylists();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _service.removeSongFromPlaylist(playlistId, songId);
    await loadPlaylists();
  }

  // 收藏
  Future<void> loadFavorites() async {
    _favorites = await _service.getFavorites();
    notifyListeners();
  }

  Future<bool> isFavorite(String songId) async {
    return await _service.isFavorite(songId);
  }

  Future<void> toggleFavorite(Song song) async {
    await _service.toggleFavorite(song);
    await loadFavorites();
  }

  Future<void> removeFromFavorites(String songId) async {
    await _service.removeFromFavorites(songId);
    await loadFavorites();
  }

  // 最近播放
  Future<void> loadRecentSongs() async {
    _recentSongs = await _service.getRecentSongs();
    notifyListeners();
  }

  Future<void> addToRecent(Song song) async {
    await _service.addToRecent(song);
    await loadRecentSongs();
  }

  Future<void> clearRecent() async {
    await _service.clearRecent();
    await loadRecentSongs();
  }
}
