import 'package:equatable/equatable.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Artist extends Equatable {
  final String id;
  final String name;
  final int numberOfAlbums;
  final int numberOfTracks;

  const Artist({
    required this.id,
    required this.name,
    required this.numberOfAlbums,
    required this.numberOfTracks,
  });

  factory Artist.fromArtistModel(ArtistModel model) {
    return Artist(
      id: model.id.toString(),
      name: model.artist,
      numberOfAlbums: model.numberOfAlbums ?? 0,
      numberOfTracks: model.numberOfTracks ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
