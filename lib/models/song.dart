import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumId;
  final int duration;
  final String uri;
  final String? artworkUri;
  final int? trackNumber;
  final String fileExtension;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumId,
    required this.duration,
    required this.uri,
    this.artworkUri,
    this.trackNumber,
    required this.fileExtension,
  });

  factory Song.fromSongModel(SongModel model) {
    return Song(
      id: model.id.toString(),
      title: model.displayNameWOExt.isNotEmpty 
          ? model.displayNameWOExt 
          : model.title,
      artist: model.artist ?? '未知艺术家',
      album: model.album ?? '未知专辑',
      albumId: model.albumId?.toString(),
      duration: model.duration ?? 0,
      uri: model.uri ?? '',
      artworkUri: null,
      trackNumber: model.track,
      fileExtension: model.fileExtension,
    );
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumId,
    int? duration,
    String? uri,
    String? artworkUri,
    int? trackNumber,
    String? fileExtension,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      duration: duration ?? this.duration,
      uri: uri ?? this.uri,
      artworkUri: artworkUri ?? this.artworkUri,
      trackNumber: trackNumber ?? this.trackNumber,
      fileExtension: fileExtension ?? this.fileExtension,
    );
  }

  String get durationText {
    final minutes = duration ~/ 60000;
    final seconds = (duration % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id, title, artist, album, uri];
}
