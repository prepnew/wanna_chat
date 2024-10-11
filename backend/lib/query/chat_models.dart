import 'package:langchain/langchain.dart';

class ChatModels {
  final BaseChatModel fastLLM;
  final BaseChatModel qualityLLM;
  final ChatModelOptions Function(double? temperature) optionsForTemp;

  ChatModels({required this.fastLLM, required this.qualityLLM, required this.optionsForTemp});

  RunnableBinding<PromptValue, ChatModelOptions, ChatResult> fastLLMWithTemp(
      {double? temperature, List<ToolSpec>? tools, ChatToolChoice? toolChoice}) {
    return fastLLM.bind(optionsForTemp(temperature).copyWith(tools: tools, toolChoice: toolChoice));
  }

  RunnableBinding<PromptValue, ChatModelOptions, ChatResult> qualityLLMWithTemp(
      {double? temperature, List<ToolSpec>? tools, ChatToolChoice? toolChoice}) {
    return qualityLLM.bind(optionsForTemp(temperature).copyWith(tools: tools, toolChoice: toolChoice));
  }
}
