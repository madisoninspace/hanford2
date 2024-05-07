![logo](./assets/logo.png)

## Description
Hanford is a program written in Dart to mass delete posts from Bluesky.

## Usage
Hanford will ask for a username and password, then ask for confirmation to delete up to 100 posts at a time. Creating an app specific password is recommended.

These questions can be skipped by creating a `.env` file.

## .env sample
```
HANFORD_USER=<username>
HANFORD_PASS=<pass>
HANFORD_SKIP_WARNING=<y/n>
```

## License
This project is licensed under the MIT license.
