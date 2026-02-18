import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  static const String _playlistsKey = 'playlists';
  static const String _favoritesKey = 'favorites';
  static const String _recentKey = 'recent_songs';
  static const String _playCountsKey = 'play_counts';
  
  final _uuid = const Uuid();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 播放列表 CRUD
  Future<List<Playlist>> getAllPlaylists() async {
    final jsonString = _prefs?.getString(_playlistsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _playlistFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Playlist?> getPlaylist(String id) async {
    final playlists = await getAllPlaylists();
    try {
      return playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Playlist> createPlaylist(String name) async {
    final playlists = await getAllPlaylists();
    final newPlaylist = Playlist(
      id: _uuid.v4(),
      name: name,
      songs: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    playlists.add(newPlaylist);
    await _savePlaylists(playlists);
    return newPlaylist;
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final playlists = await getAllPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index >= 0) {
      playlists[index] = playlist.copyWith(updatedAt: DateTime.now());
      await _savePlaylists(playlists);
    }
  }

  Future<void> deletePlaylist(String id) async {
    final playlists = await getAllPlaylists();
    playlists.removeWhere((p) => p.id == id);
    await _savePlaylists(playlists);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlists = await getAllPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final playlist = playlists[index];
      if (!playlist.songs.any((s) => s.id == song.id)) {
        playlist.songs.add(song);
        playlists[index] = playlist.copyWith(updatedAt: DateTime.now());
        await _savePlaylists(playlists);
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlists = await getAllPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final playlist = playlists[index];
      playlist.songs.removeWhere((s) => s.id == songId);
      playlists[index] = playlist.copyWith(updatedAt: DateTime.now());
      await _savePlaylists(playlists);
    }
  }

  Future<void> reorderPlaylistSongs(String playlistId, int oldIndex, int newIndex) async {
    final playlists = await getAllPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      final playlist = playlists[index];
      final song = playlist.songs.removeAt(oldIndex);
      playlist.songs.insert(newIndex < oldIndex ? newIndex : newIndex - 1, song);
      playlists[index] = playlist.copyWith(updatedAt: DateTime.now());
      await _savePlaylists(playlists);
    }
  }

  // 收藏功能
  Future<List<Song>> getFavorites() async {
    final jsonString = _prefs?.getString(_favoritesKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _songFromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> isFavorite(String songId) async {
    final favorites = await getFavorites();
    return favorites.any((s) => s.id == songId);
  }

  Future<void> toggleFavorite(Song song) async {
    final favorites = await getFavorites();
    final index = favorites.indexWhere((s) => s.id == song.id);
    
    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add(song);
    }
    
    await _saveFavorites(favorites);
  }

  Future<void> removeFromFavorites(String songId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((s) => s.id == songId);
    await _saveFavorites(favorites);
  }

  // 最近播放
  Future<List<Song>> getRecentSongs({int limit = 50}) async {
    final jsonString = _prefs?.getString(_recentKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final songs = jsonList.map((json) => _songFromJson(json)).toList();
      return songs.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addToRecent(Song song) async {
    final recent = await getRecentSongs(limit: 100);
    recent.removeWhere((s) => s.id == song.id);
    recent.insert(0, song);
    
    final trimmed = recent.take(100).toList();
    await _saveRecent(trimmed);
  }

  Future<void> clearRecent() async {
    await _prefs?.remove(_recentKey);
  }

  // 播放次数统计
  Future<Map<String, int>> getPlayCounts() async {
    final jsonString = _prefs?.getString(_playCountsKey);
    if (jsonString == null) return {};

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return jsonMap.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  Future<void> incrementPlayCount(String songId) async {
    final counts = await getPlayCounts();
    counts[songId] = (counts[songId] ?? 0) + 1;
    await _savePlayCounts(counts);
  }

  Future<List<Song>> getMostPlayedSongs(List<Song> allSongs, {int limit = 50}) async {
    final counts = await getPlayCounts();
    
    // 按播放次数排序
    final sortedIds = counts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // 构建歌曲列表
    final result = <Song>[];
    for (final entry in sortedIds.take(limit)) {
      final song = allSongs.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => null as Song,
      );
      if (song != null) {
        result.add(song);
      }
    }
    
    return result;
  }

  Future<void> clearPlayCounts() async {
    await _prefs?.remove(_playCountsKey);
  }

  Future<void> _savePlayCounts(Map<String, int> counts) async {
    await _prefs?.setString(_playCountsKey, jsonEncode(counts));
  }

  // 私有方法
  Future<void> _savePlaylists(List<Playlist> playlists) async {
    final jsonList = playlists.map((p) => _playlistToJson(p)).toList();
    await _prefs?.setString(_playlistsKey, jsonEncode(jsonList));
  }

  Future<void> _saveFavorites(List<Song> songs) async {
    final jsonList = songs.map((s) => _songToJson(s)).toList();
    await _prefs?.setString(_favoritesKey, jsonEncode(jsonList));
  }

  Future<void> _saveRecent(List<Song> songs) async {
    final jsonList = songs.map((s) => _songToJson(s)).toList();
    await _prefs?.setString(_recentKey, jsonEncode(jsonList));
  }

  // JSON 序列化
  Map<String, dynamic> _playlistToJson(Playlist playlist) {
    return {
      'id': playlist.id,
      'name': playlist.name,
      'songs': playlist.songs.map((s) => _songToJson(s)).toList(),
      'createdAt': playlist.createdAt.toIso8601String(),
      'updatedAt': playlist.updatedAt.toIso8601String(),
    };
  }

  Playlist _playlistFromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      songs: (json['songs'] as List).map((s) => _songFromJson(s)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> _songToJson(Song song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'albumId': song.albumId,
      'duration': song.duration,
      'uri': song.uri,
      'artworkUri': song.artworkUri,
      'trackNumber': song.trackNumber,
      'fileExtension': song.fileExtension,
    };
  }

  Song _songFromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      albumId: json['albumId'],
      duration: json['duration'],
      uri: json['uri'],
      artworkUri: json['artworkUri'],
      trackNumber: json['trackNumber'],
      fileExtension: json['fileExtension'] ?? '',
    );
  }
}
