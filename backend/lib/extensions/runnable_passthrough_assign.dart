import 'dart:async';

import 'package:langchain/langchain.dart';

import 'runnable_extensions.dart';

typedef AssignFunction<RunOutput extends Object> = FutureOr<RunOutput> Function(StringMap);

/// Simple passthrough/assign implementation (no stream support for now).
///
/// Merges the input dict with the output produced by the mapping argument.
class RunnablePassthroughAssign<RunOutput extends Object> extends Runnable<StringMap, RunnableOptions, StringMap> {
  const RunnablePassthroughAssign(this.mapping) : super(defaultOptions: const RunnableOptions());

  RunnablePassthroughAssign.single(String key, StringMapRunnable<RunOutput> runnable) : this({key: runnable});

  RunnablePassthroughAssign.func(String key, AssignFunction<RunOutput> func)
      : this({key: Runnable.fromFunction(invoke: (input, _) => func(input))});

  final Map<String, StringMapRunnable> mapping;

  @override
  Future<Map<String, dynamic>> invoke(
    StringMap input, {
    RunnableOptions? options,
  }) async {
    final output = {...input};

    await Future.forEach(mapping.entries, (entry) async {
      output[entry.key] = await entry.value.invoke(
        input,
        options: entry.value.getCompatibleOptions(options),
      );
    });

    return output;
  }
}
