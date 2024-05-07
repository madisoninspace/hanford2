import 'package:ansicolor/ansicolor.dart';
import 'package:bluesky/bluesky.dart' as bsky;

/// Logs in the user with the provided credentials and returns a [bsky.Bluesky] object.
///
/// The [user] parameter represents the user identifier.
/// The [pass] parameter represents the user password.
///
/// Returns a [Future] that completes with a [bsky.Bluesky] object representing the logged-in session.
Future<bsky.Bluesky> login(String user, String pass) async {
  final bsSession = await bsky.createSession(identifier: user, password: pass);
  return bsky.Bluesky.fromSession(bsSession.data);
}

/// Retrieves a list of posts from the Bluesky connection.
///
/// The [conn] parameter represents the Bluesky connection object.
/// The [filter] parameter specifies the type of feed filter to apply (default is [FeedFilter.postsAndAuthorThreads]).
/// The [limit] parameter sets the maximum number of posts to retrieve (default is 100).
///
/// Returns a [Future] that resolves to a list of [bsky.Post] objects.
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

/// Deletes the specified list of posts from the [conn] repository.
///
/// The [conn] parameter represents the connection to the Bluesky repository.
/// The [posts] parameter is a list of [bsky.Post] objects to be deleted.
///
/// This function iterates over the [posts] list and attempts to delete each post
/// by calling the `deleteRecord` method of the [conn.repo] object. If the deletion
/// is successful, it prints a message indicating the deleted post's URI and the
/// time it was indexed. If an error occurs during deletion, it prints a message
/// indicating the failed post's URI.
///
/// This function returns a [Future] that completes when all posts have been deleted.
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
