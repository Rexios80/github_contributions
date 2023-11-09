import 'dart:io';
import 'package:github/github.dart';
import 'package:intl/intl.dart';

import 'private.dart';

final github = GitHub(auth: Authentication.withToken(Private.token));

final dateFormat = DateFormat('yyyy-MM-dd');

// Past 6 months
final after =
    dateFormat.format(DateTime.now().subtract(const Duration(days: 180)));
final before = dateFormat.format(DateTime.now());

final tags = [
  'author:${Private.author}',
  'is:public',
  'is:pr',
  'created:$after..$before',
  ...Private.repoExclude.map((e) => '-repo:$e'),
  ...Private.orgExclude.map((e) => '-user:$e'),
].join(' ');

void main(List<String> arguments) async {
  print('Excluding orgs: ${Private.orgExclude}');

  final groupedPrs = <String, List<Issue>>{};
  await for (final pr in github.search.issues(tags, pages: 9999)) {
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
