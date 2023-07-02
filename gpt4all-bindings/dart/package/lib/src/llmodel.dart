import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:gpt4all/src/llmodel_prompt_config.dart';
import 'package:gpt4all/src/llmodel_error.dart';
import 'package:gpt4all/src/llmodel_library.dart';
import 'package:gpt4all/src/llmodel_prompt_context.dart';
import 'package:gpt4all/src/llmodel_utils.dart';

class LLModel {
  bool _isLoaded = false;

  late final LLModelLibrary _library;
  late final ffi.Pointer _model;

  late final ffi.Pointer<ffi.Pointer<ffi.Float>> _logits;
  late final ffi.Pointer<ffi.Pointer<ffi.Int32>> _tokens;
  late final ffi.Pointer<llmodel_prompt_context> _promptContext;

  /// Define a [callback] function for prompts, which returns a bool
  /// indicating whether the model should keep processing based on a
  /// given [tokenId].
  static void setPromptCallback(bool Function(int tokenId) callback) =>
      LLModelLibrary.promptCallback = callback;

  /// Define a [callback] function for responses, which returns a bool
  /// indicating whether the model should keep processing based on a
  /// given [tokenId] and [response] string.
  ///
  /// A [tokenId] of -1 indicates the string is an error string.
  static void setResponseCallback(
      bool Function(int tokenId, String response) callback) =>
      LLModelLibrary.responseCallback = callback;

  /// Define a [callback] function for recalculation, which returns a bool
  /// indicating whether the model should keep processing based on whether
  /// the model [isRecalculating] the context.
  static void setRecalculateCallback(
      bool Function(bool isRecalculating) callback) =>
      LLModelLibrary.recalculateCallback = callback;

  /// Load the model (.bin) from the [modelPath] and (optionally) loads required
  /// libraries (.dll/.dylib/.so) from the [librarySearchPath] folder. The
  /// [LLModelPromptConfig] can be used to optimize the model invocation.
  ///
  /// This method must be called before any other interaction with the [LLModel].
  ///
  /// Make sure to call the [destroy] method once the work is performed.
  Future<void> load({
    required final String modelPath,
    String? librarySearchPath,
    LLModelPromptConfig? promptConfig,
  }) async {
    librarySearchPath ??= await LLModelUtils.copySourcesToTmpFolder();
    promptConfig ??= LLModelPromptConfig();

    final ffi.Pointer<LLModelError> error = calloc<LLModelError>();

    try {
      _logits = calloc<ffi.Pointer<ffi.Float>>();
      _tokens = calloc<ffi.Pointer<ffi.Int32>>();
      _promptContext = calloc<llmodel_prompt_context>();
      _promptContext.ref
        ..logits = _logits.value // TODO generationConfig.logits
        ..logits_size = 0 // TODO generationConfig.logits.length
        ..tokens = _tokens.value // TODO generationConfig.tokens
        ..tokens_size = 0 // TODO generationConfig.tokens.length
        ..n_past = promptConfig.nPast
        ..n_ctx = promptConfig.nCtx
        ..n_predict = promptConfig.nPredict
        ..top_k = promptConfig.topK
        ..top_p = promptConfig.topP
        ..temp = promptConfig.temp
        ..n_batch = promptConfig.nBatch
        ..repeat_penalty = promptConfig.repeatPenalty
        ..repeat_last_n = promptConfig.repeatLastN
        ..context_erase = promptConfig.contextErase;

      _library = LLModelLibrary(
        pathToLibrary: '$librarySearchPath/libllmodel${LLModelUtils
            .getFileSuffix()}',
      );

      _library.setImplementationSearchPath(
        path: librarySearchPath,
      );

      if (!File(modelPath).existsSync()) {
        throw Exception("Model file does not exist: $modelPath");
      }

      _model = _library.modelCreate2(
        modelPath: modelPath,
        buildVariant: "auto",
        error: error,
      );

      if (_model.address == ffi.nullptr.address) {
        final String errorMsg = error.ref.message.toDartString();
        throw Exception("Could not load gpt4all backend: $errorMsg");
      }

      _library.loadModel(
        model: _model,
        modelPath: modelPath,
      );

      if (_library.isModelLoaded(model: _model)) {
        _isLoaded = true;
      } else {
        throw Exception("The model could not be loaded");
      }
    } finally {
      calloc.free(error);
    }
  }

  /// Generate a response to the [prompt] using the model.
  Future<void> generate({
    required String prompt,
  }) async {
    _library.prompt(
      model: _model,
      prompt: prompt,
      promptContext: _promptContext,
    );
  }

  /// Destroy the model instance.
  ///
  /// Make sure to invoke this method once the model is no longer needed.
  void destroy() {
    if (_isLoaded) {
      _library.modelDestroy(
        model: _model,
      );
      _isLoaded = false;
    }
    calloc.free(_promptContext);
    calloc.free(_tokens);
    calloc.free(_logits);
  }
}