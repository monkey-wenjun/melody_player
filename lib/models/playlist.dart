import 'package:equatable/equatable.dart';
import 'song.dart';

class Playlist extends Equatable {
  final String id;
  final String name;
  final List<Song> songs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  int get songCount => songs.length;

  int get totalDuration {
    return songs.fold(0, (sum, song) => sum + song.duration);
  }

  Playlist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, songs];
}
