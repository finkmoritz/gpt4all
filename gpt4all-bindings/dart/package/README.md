# GPT4All Dart Binding

Dart bindings for the GPT4All C/C++ libraries and models.

**Target platforms:**
- Windows
- macOS
- Linux

## Getting started

1. Download model

Visit the [GPT4All Website](https://gpt4all.io/index.html) and use the Model Explorer
to find and download your model of choice (e.g. ggml-gpt4all-j-v1.3-groovy.bin).

2. Run the Dart code

Use the downloaded model in your Dart code.
Have a look at the example implementation in [main.dart](example/main.dart):

```
  LLModel model = LLModel();
  try {
    // Always load the model before performing any other work.
    await model.load(
      // Path to the downloaded model file (*.bin)
      modelPath: '/some/path/to/ggml-gpt4all-j-v1.3-groovy.bin',
      // Optionally fine-tune the default configuration
      promptConfig: LLModelPromptConfig()..nPredict = 256,
    );

    // Generate a response to the given prompt
    await model.generate(
      prompt: "### Human:\nWhat is the meaning of life?\n### Assistant:",
    );
  } finally {
    // Always destroy the model after calling the load(..) method
    model.destroy();
  }
```

## Known issues

### Static callbacks

Callbacks of the API must be provided in a static way, e.g.:

```
LLModel.setResponseCallback(
      (int tokenId, String response) {
    stderr.write(response);
    return true;
  },
);
```
Obviously, this makes it hard (if not impossible) to work with different models or prompts in parallel...

Unfortunately, this is a requirement by the dart:ffi dependency which cannot be worked around from the Dart code.
