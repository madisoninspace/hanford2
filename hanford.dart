import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:bluesky/bluesky.dart' as bsky;

import 'bluesky.dart';

AnsiPen green = AnsiPen()..green();
AnsiPen red = AnsiPen()..red();
AnsiPen yellow = AnsiPen()..yellow();

void deletePosts(
    String skip, bsky.Bluesky bluesky, List<bsky.Post> posts) async {
  AnsiPen red = AnsiPen()..red();

  if (skip == 'true') {
    await delete(bluesky, posts);
  } else {
    print(
        'Warning: This script will delete ${posts.length} posts. Do you want to continue? (y/n): ');
    final cont = stdin.readLineSync();
    if (cont == 'y') {
      await delete(bluesky, posts);
    } else {
      print(red('Exiting...'));
    }
  }
}

void main() async {
  // Check for these environment variables
  // HANFORD_USER, HANFORD_PASS, HANFORD_SKIP_WARNING
  var user = Platform.environment['HANFORD_USER'];
  var pass = Platform.environment['HANFORD_PASS'];
  var skipWarning = Platform.environment['HANFORD_SKIP_WARNING'];

  // Read the environment variables from the .env file
  if (user == null || pass == null) {
    try {
      final env = File('.env');
      final lines = await env.readAsLines();
      for (var line in lines) {
        if (line.startsWith('HANFORD_USER')) {
          user = line.split('=')[1];
        } else if (line.startsWith('HANFORD_PASS')) {
          pass = line.split('=')[1];
        } else if (line.startsWith('HANFORD_SKIP_WARNING')) {
          skipWarning = line.split('=')[1];
        }
      }
    } catch (e) {
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

      // Set the user and pass variables
      user = username;
      pass = password;
      skipWarning = skip;
    }
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
  print('Enter the number of posts to fetch (default is 100): ');
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
  print('Enter the feed filter (default is postsAndAuthorThreads): ');
  print(
      'Options: postsAndAuthorThreads, postsNoReplies, postsWithMedia, postsNoReplies');
  final filter = stdin.readLineSync();

  // Convert filter to FeedFilter enum
  bsky.FeedFilter feedFilter;
  if (filter == 'postsAndAuthorThreads') {
    feedFilter = bsky.FeedFilter.postsAndAuthorThreads;
  } else if (filter == 'postsNoReplies') {
    feedFilter = bsky.FeedFilter.postsNoReplies;
  } else if (filter == 'postsWithMedia') {
    feedFilter = bsky.FeedFilter.postsWithMedia;
  } else if (filter == 'postsNoReplies') {
    feedFilter = bsky.FeedFilter.postsNoReplies;
  } else {
    feedFilter = bsky.FeedFilter.postsAndAuthorThreads;
  }

  // Fetch the posts
  final posts = await getPosts(bluesky, filter: feedFilter, limit: limitInt);
  print('Fetched ${posts.length} posts.');

  // Ask the user if they want to delete the posts
  deletePosts(skipWarning!, bluesky, posts);
}
