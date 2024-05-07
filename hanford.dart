import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:bluesky/bluesky.dart' as bsky;

import 'bluesky.dart';

AnsiPen blue = AnsiPen()..blue();
AnsiPen green = AnsiPen()..green();
AnsiPen red = AnsiPen()..red();
AnsiPen yellow = AnsiPen()..yellow();

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
