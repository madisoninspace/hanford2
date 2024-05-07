import 'package:ansicolor/ansicolor.dart';
import 'package:bluesky/bluesky.dart' as bsky;

Future<bsky.Bluesky> login(String user, String pass) async {
  final bsSession = await bsky.createSession(identifier: user, password: pass);
  return bsky.Bluesky.fromSession(bsSession.data);
}

Future<List<bsky.Post>> getPosts(bsky.Bluesky conn,
    {bsky.FeedFilter filter = bsky.FeedFilter.postsAndAuthorThreads,
    int limit = 100}) async {
  List<bsky.Post> postHolder = [];
  final posts =
      await conn.feed.getAuthorFeed(actor: conn.session!.did, limit: limit);

  for (var post in posts.data.feed) {
    postHolder.add(post.post);
  }

  return postHolder;
}

Future<void> delete(bsky.Bluesky conn, List<bsky.Post> posts) async {
  AnsiPen yellow = AnsiPen()..yellow();

  for (var post in posts) {
    try {
      conn.repo.deleteRecord(uri: post.uri);
      print(yellow('Deleted post: ${post.uri} at ${post.indexedAt}'));
    } catch (e) {
      print('Failed to delete post: ${post.uri}');
    }
  }
}
