import 'dart:io';
import 'package:github/github.dart';

import 'private.dart';

final github = GitHub(auth: Authentication.withToken(Private.token));

final after = DateTime(2022);
final before = DateTime.now();

void main(List<String> arguments) async {
  print('Excluding orgs: ${Private.orgExclude}\n');

  final tags = [
    'author:${Private.author}',
    'is:public',
    'is:pr',
    ...Private.orgExclude.map((e) => '-user:$e'),
  ];

  final groupedPrs = <String, List<Issue>>{};
  await for (final pr in github.search.issues(tags.join(' '), pages: 9999)) {
    if (pr.createdAt!.isBefore(after) || pr.createdAt!.isAfter(before)) {
      print('Skipping: ${pr.createdAt}: ${pr.title}');
      continue;
    }
    groupedPrs.update(
      slugFromUrl(pr.url),
      (e) => e..add(pr),
      ifAbsent: () => [pr],
    );
  }

  print('');

  for (final entry in groupedPrs.entries) {
    final slug = entry.key;
    final prs = entry.value;

    print('$slug: ${prs.length} PRs');
    for (final pr in prs) {
      print('  - ${pr.createdAt}: ${pr.title} (${pr.htmlUrl})');
    }
    print('');
  }

  exit(0);
}

String slugFromUrl(String url) {
  final parts = Uri.parse(url).pathSegments;
  return '${parts[1]}/${parts[2]}';
}
