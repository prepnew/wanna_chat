import 'package:langchain/langchain.dart';
import 'runnable_passthrough_assign.dart';

typedef StringMap = Map<String, dynamic>;
typedef StringMapRunnable<RunOutput extends Object> = Runnable<StringMap, RunnableOptions, Object>;

extension RunnableEx on Runnable {
  /// Merges the input dict with the provided mappings.
  static RunnablePassthroughAssign assign<RunOutput extends Object>(Map<String, StringMapRunnable> mappings) {
    return RunnablePassthroughAssign(mappings);
  }

  /// Merges the input dict with the provided key -> runnable mapping.
  static RunnablePassthroughAssign assignSingle<RunOutput extends Object>(
      String key, Runnable<Map<String, dynamic>, RunnableOptions, RunOutput> runnable) {
    return RunnablePassthroughAssign.single(key, runnable);
  }

  /// Merges the input dict with the provided key -> func (wrapped in a RunnableFunction) mapping.
  static RunnablePassthroughAssign assignFunc<RunOutput extends Object>(String key, AssignFunction<RunOutput> func) {
    return RunnablePassthroughAssign.func(key, func);
  }
}
