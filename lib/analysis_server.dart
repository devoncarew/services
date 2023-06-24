// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server_lib/analysis_server_lib.dart';
import 'package:path/path.dart' as p;

import 'model/model.dart' as model;
import 'sdk.dart';
import 'template.dart';
import 'utils.dart';

const String _warmupSrc = '''
void main() {
  // warm up source
}
''';

void log(String message) => print(message);

void severe(String message) => stdout.writeln(message);

class AnalysisServerWrapper {
  final FlutterSdk sdk;
  final Template template;

  final TaskScheduler scheduler = TaskScheduler();

  bool _isInitialized = false;

  /// Instance to handle communication with the server.
  late AnalysisServer analysisServer;

  AnalysisServerWrapper(this.sdk, this.template);

  late final mainPath = p.join(template.path, kMainDart);

  Future<void> init() async {
    if (_isInitialized) {
      throw StateError('AnalysisServerWrapper is already initialized');
    }
    _isInitialized = true;

    final serverArgs = <String>[
      '--client-id=DartPad',
    ];
    log('Starting server ($serverArgs)');

    analysisServer = await AnalysisServer.create(
      sdkPath: sdk.dartSdkPath,
      serverArgs: serverArgs,
    );

    try {
      analysisServer.server.onError.listen((ServerError error) {
        severe('server error: ${error.message}\n${error.stackTrace}');
      });
      await analysisServer.server.onConnected.first;
      await analysisServer.server.setSubscriptions(<String>['STATUS']);

      // listenForCompletions();

      await analysisServer.analysis.setAnalysisRoots([template.path], []);
      await analysisServer.analysis.setPriorityFiles([mainPath]);

      // Warmup.
      await _updateOverlay(_warmupSrc);
    } catch (err, st) {
      severe('Error starting analysis server (${sdk.dartSdkPath}): $err.\n$st');
      rethrow;
    }
  }

  Future<int> get onExit {
    // Return when the analysis server exits. We introduce a delay so that when
    // we terminate the analysis server we can exit normally.
    return analysisServer.processCompleter.future.then((int code) {
      return Future<int>.delayed(const Duration(seconds: 1), () {
        return code;
      });
    });
  }

  // Future<proto.CompleteResponse> complete(String src, int offset) async {
  //   return completeFiles({kMainDart: src}, Location(kMainDart, offset));
  // }

  // Future<proto.CompleteResponse> completeFiles(
  //     Map<String, String> sources, Location location) async {
  //   final results =
  //       await _completeImpl(sources, location.sourceName, location.offset);
  //   var suggestions = results.results;

  //   final source = sources[location.sourceName]!;
  //   final prefix = source.substring(results.replacementOffset, location.offset);
  //   suggestions = suggestions.where((suggestion) {
  //     return suggestion.completion
  //         .toLowerCase()
  //         .startsWith(prefix.toLowerCase());
  //   }).where((CompletionSuggestion suggestion) {
  //     // We do not want to enable arbitrary discovery of file system resources.

  //     // In order to avoid returning local file paths, we only allow returning
  //     // IMPORT kinds that are dart: or package: imports.
  //     if (suggestion.kind == 'IMPORT') {
  //       final completion = suggestion.completion;
  //       return completion.startsWith('dart:') ||
  //           completion.startsWith('package:');
  //     } else {
  //       return true;
  //     }
  //   }).toList();

  //   suggestions.sort((CompletionSuggestion x, CompletionSuggestion y) {
  //     if (x.relevance == y.relevance) {
  //       return x.completion.compareTo(y.completion);
  //     } else {
  //       return y.relevance.compareTo(x.relevance);
  //     }
  //   });

  //   return proto.CompleteResponse()
  //     ..replacementOffset = results.replacementOffset
  //     ..replacementLength = results.replacementLength
  //     ..completions
  //         .addAll(suggestions.map((CompletionSuggestion c) => proto.Completion()
  //           ..completion.addAll(c.toMap().map((key, value) {
  //             // TODO: Properly support Lists, Maps (this is a hack).
  //             if (value is Map || value is List) {
  //               value = json.encode(value);
  //             }
  //             return MapEntry(key.toString(), value.toString());
  //           }))));
  // }

  // Future<proto.FixesResponse> getFixes(String src, int offset) {
  //   return getFixesMulti({kMainDart: src}, Location(kMainDart, offset));
  // }

  // Future<proto.FixesResponse> getFixesMulti(
  //     Map<String, String> sources, Location location) async {
  //   final results =
  //       await _getFixesImpl(sources, location.sourceName, location.offset);
  //   final responseFixes = results.fixes.map((availableAnalysisErrorFixes) {
  //     return _convertAnalysisErrorFix(
  //         availableAnalysisErrorFixes, location.sourceName);
  //   });
  //   return proto.FixesResponse()..fixes.addAll(responseFixes);
  // }

  // Future<proto.AssistsResponse> getAssists(String src, int offset) async {
  //   return getAssistsMulti({kMainDart: src}, Location(kMainDart, offset));
  // }

  // Future<proto.AssistsResponse> getAssistsMulti(
  //     Map<String, String> sources, Location location) async {
  //   final sourceName = location.sourceName;
  //   final results = await _getAssistsImpl(sources, sourceName, location.offset);
  //   final fixes =
  //       _convertSourceChangesToCandidateFixes(results.assists, sourceName);
  //   return proto.AssistsResponse()..assists.addAll(fixes);
  // }

  Future<model.FormatResponse> format(model.FormatRequest request) async {
    try {
      var src = request.source;
      final editResult =
          await _formatImpl(request.source, request.selectionOffset ?? 0);
      final edits = editResult.edits;
      edits.sort((e1, e2) => -1 * e1.offset.compareTo(e2.offset));

      for (final edit in edits) {
        src = src.replaceRange(
          edit.offset,
          edit.offset + edit.length,
          edit.replacement,
        );
      }

      return model.FormatResponse(
        source: src,
        selectionOffset: editResult.selectionOffset,
      );
    } on RequestError catch (e) {
      throw model.ErrorResponse(message: e.message);
    } catch (e) {
      throw model.ErrorResponse(message: '$e');
    }
  }

  Future<FormatResult> _formatImpl(String src, int selectionOffset) async {
    return scheduler.execute(() async {
      await _updateOverlay(src);
      return await analysisServer.edit.format(mainPath, selectionOffset, 0);
    });
  }

  // Future<proto.AnalysisResults> analyze(String src) {
  //   return analyzeFiles({kMainDart: src});
  // }

  // Future<proto.AnalysisResults> analyzeFiles(Map<String, String> sources,
  //     {List<ImportDirective>? imports}) {
  //   _logger.fine('analyze: Scheduler queue: ${serverScheduler.queueCount}');

  //   return serverScheduler
  //       .schedule(ClosureTask<proto.AnalysisResults>(() async {
  //     sources = _getOverlayMapWithPaths(sources);
  //     await _loadSources(sources);
  //     final errors = <AnalysisError>[];

  //     // Loop over all files and collect errors (sources now has filenames
  //     // with full paths as keys after _getOverlayMapWithPaths() call).
  //     for (final sourcepath in sources.keys) {
  //       errors.addAll(
  //           (await analysisServer.analysis.getErrors(sourcepath)).errors);
  //     }
  //     await _unloadSources();

  //     // Convert the issues to protos.
  //     final issues = errors.map((error) {
  //       final issue = proto.AnalysisIssue()
  //         ..kind = error.severity.toLowerCase()
  //         ..code = error.code.toLowerCase()
  //         ..line = error.location.startLine
  //         ..column = error.location.startColumn
  //         ..message = utils.normalizeFilePaths(error.message)
  //         ..sourceName = path.basename(error.location.file)
  //         ..hasFixes = error.hasFix ?? false
  //         ..charStart = error.location.offset
  //         ..charLength = error.location.length
  //         ..diagnosticMessages.addAll(
  //           error.contextMessages?.map((m) => proto.DiagnosticMessage()
  //                 ..message = utils.normalizeFilePaths(m.message)
  //                 ..line = m.location.startLine
  //                 ..charStart = m.location.offset
  //                 ..charLength = m.location.length) ??
  //               [],
  //         );

  //       if (error.url != null) {
  //         issue.url = error.url!;
  //       }

  //       if (error.correction != null) {
  //         issue.correction = utils.normalizeFilePaths(error.correction!);
  //       }

  //       return issue;
  //     }).toList();

  //     issues.sort((a, b) {
  //       // Order issues by character position of the bug/warning.
  //       return a.charStart.compareTo(b.charStart);
  //     });

  //     // Ensure we have imports if they were not passed in.
  //     imports ??= getAllImportsForFiles(sources);

  //     // Calculate the package: imports (and defensively sanitize).
  //     final packageImports = {
  //       ...?imports?.filterSafePackages(),
  //     };

  //     return proto.AnalysisResults()
  //       ..issues.addAll(issues)
  //       ..packageImports.addAll(packageImports);
  //   }, timeoutDuration: _analysisServerTimeout));
  // }

  // Future<AssistsResult> _getAssistsImpl(
  //     Map<String, String> sources, String sourceName, int offset) {
  //   sources = _getOverlayMapWithPaths(sources);
  //   final path = _getPathFromName(sourceName);

  //   if (serverScheduler.queueCount > 0) {
  //     _logger.fine(
  //         'getRefactoringsImpl: Scheduler queue: ${serverScheduler.queueCount}');
  //   }

  //   return serverScheduler.schedule(ClosureTask<AssistsResult>(() async {
  //     await _loadSources(sources);
  //     final AssistsResult assists;
  //     try {
  //       assists =
  //           await analysisServer.edit.getAssists(path, offset, 1 /* length */);
  //     } finally {
  //       await _unloadSources();
  //     }
  //     return assists;
  //   }, timeoutDuration: _analysisServerTimeout));
  // }

  // /// Convert between the Analysis Server type and the API protocol types.
  // static proto.ProblemAndFixes _convertAnalysisErrorFix(
  //     AnalysisErrorFixes analysisFixes, String filename) {
  //   final problemMessage = analysisFixes.error.message;
  //   final problemOffset = analysisFixes.error.location.offset;
  //   final problemLength = analysisFixes.error.location.length;

  //   final possibleFixes = <proto.CandidateFix>[];

  //   for (final sourceChange in analysisFixes.fixes) {
  //     final edits = <proto.SourceEdit>[];

  //     // A fix that tries to modify other files is considered invalid.

  //     var invalidFix = false;
  //     for (final sourceFileEdit in sourceChange.edits) {
  //       // TODO(lukechurch): replace this with a more reliable test based on the
  //       // psuedo file name in Analysis Server
  //       if (!sourceFileEdit.file.endsWith('/$filename')) {
  //         invalidFix = true;
  //         break;
  //       }

  //       for (final sourceEdit in sourceFileEdit.edits) {
  //         edits.add(proto.SourceEdit()
  //           ..offset = sourceEdit.offset
  //           ..length = sourceEdit.length
  //           ..replacement = sourceEdit.replacement);
  //       }
  //     }
  //     if (!invalidFix) {
  //       final possibleFix = proto.CandidateFix()
  //         ..message = sourceChange.message
  //         ..edits.addAll(edits);
  //       possibleFixes.add(possibleFix);
  //     }
  //   }
  //   return proto.ProblemAndFixes()
  //     ..fixes.addAll(possibleFixes)
  //     ..problemMessage = problemMessage
  //     ..offset = problemOffset
  //     ..length = problemLength;
  // }

  // static List<proto.CandidateFix> _convertSourceChangesToCandidateFixes(
  //     List<SourceChange> sourceChanges, String filename) {
  //   final assists = <proto.CandidateFix>[];

  //   for (final sourceChange in sourceChanges) {
  //     for (final sourceFileEdit in sourceChange.edits) {
  //       if (!sourceFileEdit.file.endsWith('/$filename')) {
  //         break;
  //       }

  //       final sourceEdits = sourceFileEdit.edits.map((sourceEdit) {
  //         return proto.SourceEdit()
  //           ..offset = sourceEdit.offset
  //           ..length = sourceEdit.length
  //           ..replacement = sourceEdit.replacement;
  //       });

  //       final candidateFix = proto.CandidateFix();
  //       candidateFix.message = sourceChange.message;
  //       candidateFix.edits.addAll(sourceEdits);
  //       final selectionOffset = sourceChange.selection?.offset;
  //       if (selectionOffset != null) {
  //         candidateFix.selectionOffset = selectionOffset;
  //       }
  //       candidateFix.linkedEditGroups
  //           .addAll(_convertLinkedEditGroups(sourceChange.linkedEditGroups));
  //       assists.add(candidateFix);
  //     }
  //   }

  //   return assists;
  // }

  // /// Convert a list of the analysis server's [LinkedEditGroup]s into the API's
  // /// equivalent.
  // static Iterable<proto.LinkedEditGroup> _convertLinkedEditGroups(
  //     Iterable<LinkedEditGroup> groups) {
  //   return groups.map<proto.LinkedEditGroup>((g) {
  //     return proto.LinkedEditGroup()
  //       ..positions.addAll(g.positions.map((p) => p.offset).toList())
  //       ..length = g.length
  //       ..suggestions.addAll(g.suggestions
  //           .map((s) => proto.LinkedEditSuggestion()
  //             ..value = s.value
  //             ..kind = s.kind)
  //           .toList());
  //   });
  // }

  /// Cleanly shutdown the Analysis Server.
  Future<void> shutdown() {
    // TODO(jcollins-g): calling dispose() sometimes prevents
    // --pause-isolates-on-exit from working; fix.
    return analysisServer.server
        .shutdown()
        .timeout(const Duration(seconds: 1))
        // At runtime, it appears that [ServerDomain.shutdown] returns a
        // `Future<Map<dynamic, dynamic>>`.
        .catchError((_) => <dynamic, dynamic>{});
  }

  // /// Internal implementation of the completion mechanism.
  // Future<CompletionResults> _completeImpl(
  //     Map<String, String> sources, String sourceName, int offset) async {
  //   if (serverScheduler.queueCount > 0) {
  //     _logger
  //         .info('completeImpl: Scheduler queue: ${serverScheduler.queueCount}');
  //   }

  //   return serverScheduler.schedule(ClosureTask<CompletionResults>(() async {
  //     sources = _getOverlayMapWithPaths(sources);
  //     await _loadSources(sources);
  //     final id = await analysisServer.completion.getSuggestions(
  //       _getPathFromName(sourceName),
  //       offset,
  //     );
  //     final CompletionResults results;
  //     try {
  //       results = await getCompletionResults(id.id);
  //     } finally {
  //       await _unloadSources();
  //     }
  //     return results;
  //   }, timeoutDuration: _analysisServerTimeout));
  // }

  // Future<FixesResult> _getFixesImpl(
  //     Map<String, String> sources, String sourceName, int offset) async {
  //   sources = _getOverlayMapWithPaths(sources);
  //   final path = _getPathFromName(sourceName);

  //   if (serverScheduler.queueCount > 0) {
  //     _logger
  //         .fine('getFixesImpl: Scheduler queue: ${serverScheduler.queueCount}');
  //   }

  //   return serverScheduler.schedule(ClosureTask<FixesResult>(() async {
  //     await _loadSources(sources);
  //     final FixesResult fixes;
  //     try {
  //       fixes = await analysisServer.edit.getFixes(path, offset);
  //     } finally {
  //       await _unloadSources();
  //     }
  //     return fixes;
  //   }, timeoutDuration: _analysisServerTimeout));
  // }

  /// Loads [source] as a file system overlay to the analysis server.
  Future<void> _updateOverlay(String source) async {
    await _sendAddOverlays({mainPath: source});
  }

  /// Sends [overlays] to the analysis server.
  Future<void> _sendAddOverlays(Map<String, String> overlays) async {
    final contentOverlays = overlays.map((overlayPath, content) =>
        MapEntry(overlayPath, AddContentOverlay(content)));
    await analysisServer.analysis.updateContent(contentOverlays);
  }

  // final Map<String, Completer<CompletionResults>> _completionCompleters =
  //     <String, Completer<CompletionResults>>{};

  // void listenForCompletions() {
  //   analysisServer.completion.onResults.listen((CompletionResults result) {
  //     if (result.isLast) {
  //       final completer = _completionCompleters.remove(result.id);
  //       if (completer != null) {
  //         completer.complete(result);
  //       }
  //     }
  //   });
  // }

  // Future<CompletionResults> getCompletionResults(String id) {
  //   final completer = Completer<CompletionResults>();
  //   _completionCompleters[id] = completer;
  //   return completer.future;
  // }
}

class Location {
  final String sourceName;
  final int offset;

  const Location(this.sourceName, this.offset);
}
