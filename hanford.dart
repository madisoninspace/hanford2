import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:bluesky/bluesky.dart' as bsky;

import 'bluesky.dart';

AnsiPen blue = AnsiPen()..blue();
AnsiPen green = AnsiPen()..green();
AnsiPen red = AnsiPen()..red();
AnsiPen yellow = AnsiPen()..yellow();

/// Deletes posts based on the given parameters.
///
/// The [skip] parameter determines whether to skip the confirmation prompt and delete the posts directly.
/// The [bluesky] parameter is an instance of the [bsky.Bluesky] class.
/// The [posts] parameter is a list of [bsky.Post] objects to be deleted.
///
/// If [skip] is 'true', the posts will be deleted without any confirmation.
/// If [skip] is any other value, a confirmation prompt will be displayed before deleting the posts.
/// The user can confirm the deletion by entering 'y', 'Y', 'yes', 'Yes', or 'YES'.
/// If the user enters any other value, the deletion will be canceled.
///
/// This method is asynchronous and returns a [Future] that completes when the deletion is finished.
void deletePosts(
    String skip, bsky.Bluesky bluesky, List<bsky.Post> posts) async {
  AnsiPen red = AnsiPen()..red();

  if (skip == 'true') {
    await delete(bluesky, posts);
  } else {
    print(red(
        'Warning: This script will delete ${posts.length} posts. Do you want to continue? (y/n): '));
    final cont = stdin.readLineSync();
    if (cont == 'y' ||
        cont == 'Y' ||
        cont == 'yes' ||
        cont == 'Yes' ||
        cont == 'YES') {
      await delete(bluesky, posts);
    } else {
      print(red('Exiting...'));
    }
  }
}

/// Sets the environment variables for the Hanford application.
/// Prompts the user to provide their Hanford username and password,
/// and asks if they want to skip the warning message.
/// If the user chooses to skip the warning, the script proceeds to set the environment variables.
/// If the user chooses not to skip the warning, the script displays a warning message
/// and asks for confirmation before setting the environment variables.
/// The environment variables are stored in a .env file.
Future<void> setEnvironmentVariables() async {
  print('Please provide your Hanford username and password.');
  print('Username: ');
  final username = stdin.readLineSync();
  print('Password: ');
  final password = stdin.readLineSync();
  print('Skip warning? (y/n): ');
  final skip = stdin.readLineSync();
  if (skip == 'y') {
    print('Skipping warning...');
  } else {
    print(
        'Warning: This script will store your username and password in the environment variables.');
    print('Do you want to continue? (y/n): ');
    final cont = stdin.readLineSync();
    if (cont != 'y') {
      print('Exiting...');
      return;
    }
  }
  print('Setting environment variables...');
  final env = File('.env');
  await env.writeAsString(
      'HANFORD_USER=$username\nHANFORD_PASS=$password\nHANFORD_SKIP_WARNING=$skip\n');
  print('Environment variables set.');
}

/// Converts a string [filter] to a [bsky.FeedFilter] object.
///
/// The [filter] parameter represents the type of filter to be converted.
/// It can have the following values:
///   - 'postsNoReplies': Returns [bsky.FeedFilter.postsNoReplies].
///   - 'postsWithMedia': Returns [bsky.FeedFilter.postsWithMedia].
///   - Any other value: Returns [bsky.FeedFilter.postsAndAuthorThreads].
///
/// Returns a [bsky.FeedFilter] object based on the provided [filter] value.
bsky.FeedFilter convertToFeedFilter(String filter) {
  switch (filter) {
    case 'postsNoReplies':
      return bsky.FeedFilter.postsNoReplies;
    case 'postsWithMedia':
      return bsky.FeedFilter.postsWithMedia;
    default:
      return bsky.FeedFilter.postsAndAuthorThreads;
  }
}

/// This is the main function of the Hanford application.
/// It performs the following tasks:
/// 1. Checks for environment variables: HANFORD_USER, HANFORD_PASS, HANFORD_SKIP_WARNING.
/// 2. Reads the environment variables from the .env file if it exists.
/// 3. Sets the environment variables on the actual environment.
/// 4. Logs in to the bluesky system using the provided user and pass.
/// 5. Asks the user for the number of posts to fetch and the feed filter.
/// 6. Fetches the posts based on the provided filter and limit.
/// 7. Deletes the fetched posts if the user confirms.
void main() async {
  // Check for these environment variables
  // HANFORD_USER, HANFORD_PASS, HANFORD_SKIP_WARNING
  var user = Platform.environment['HANFORD_USER'];
  var pass = Platform.environment['HANFORD_PASS'];
  var skipWarning = Platform.environment['HANFORD_SKIP_WARNING'];

  // Read the environment variables from the .env file
  final envFile = File('.env');
  if (envFile.existsSync()) {
    var mutableEnv = Map<String, String>.from(Platform.environment);

    final envContents = await envFile.readAsString();
    final envLines = envContents.split('\n');
    for (final line in envLines) {
      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        mutableEnv[key] = value;
      }
    }

    // Set the environment variables on the actual environment
    if (mutableEnv.containsKey('HANFORD_USER')) {
      user = mutableEnv['HANFORD_USER'];
    }

    if (mutableEnv.containsKey('HANFORD_PASS')) {
      pass = mutableEnv['HANFORD_PASS'];
    }

    if (mutableEnv.containsKey('HANFORD_SKIP_WARNING')) {
      skipWarning = mutableEnv['HANFORD_SKIP_WARNING'];
    }
  }

  // Check if the variables are null
  if (user == null || pass == null) {
    await setEnvironmentVariables();
    // Set the user and pass variables
    user = Platform.environment['HANFORD_USER'];
    pass = Platform.environment['HANFORD_PASS'];
    skipWarning = Platform.environment['HANFORD_SKIP_WARNING'];
  }

  // Login to bluesky
  final bluesky = await login(user!, pass!);
  if (bluesky.session == null) {
    print(red('Login failed.'));
    return;
  } else {
    print(green('Login successful.'));
  }

  // Ask the user for the number of posts to fetch. Default is 100.
  print(blue('Enter the number of posts to fetch (default is 100): '));
  var limit = stdin.readLineSync();
  var limitInt = 0;

  if (limit == "") {
    limit = "100";
  }
  try {
    limitInt = int.parse(limit!);
  } catch (e) {
    print(red('Invalid limit.'));
    return;
  }

  // Ask the user for the feed filter. Default is postsAndAuthorThreads.
  print(blue('Enter the feed filter (default is postsAndAuthorThreads): '));
  print(blue('Options: postsNoReplies, postsWithMedia, postsAndAuthorThreads'));
  final filter = stdin.readLineSync();

  // Convert filter to FeedFilter enum
  final feedFilter = convertToFeedFilter(filter!);

  // Fetch the posts
  final posts = await getPosts(bluesky, filter: feedFilter, limit: limitInt);
  print(green('Fetched ${posts.length} posts.'));

  // Ask the user if they want to delete the posts
  deletePosts(skipWarning!, bluesky, posts);
}
