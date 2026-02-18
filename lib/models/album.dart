import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Album extends Equatable {
  final String id;
  final String title;
  final String artist;
  final int numberOfSongs;
  final String? artworkUri;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.numberOfSongs,
    this.artworkUri,
  });

  factory Album.fromAlbumModel(AlbumModel model) {
    return Album(
      id: model.id.toString(),
      title: model.album,
      artist: model.artist ?? '未知艺术家',
      numberOfSongs: model.numOfSongs,
      artworkUri: null,
    );
  }

  @override
  List<Object?> get props => [id, title, artist];
}
