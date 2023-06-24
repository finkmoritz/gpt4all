# GPT4All Dart Binding

Dart bindings for the GPT4All C/C++ libraries and models.

This readme describes how to build the package released here: https://pub.dev/packages/gpt4all

The actual contents of the released package are found in the [package](package) folder.

## Build package

### 1. Compile `llmodel` C/C++ libraries

```
git clone --recurse-submodules https://github.com/nomic-ai/gpt4all
cd gpt4all/gpt4all-backend/
mkdir build
cd build
cmake ..
cmake --build . --parallel
```
Confirm that `libllmodel.*` exists in `gpt4all-backend/build`.

Repeat this process for each of the target platforms to get all necessary compiled source files:
- Windows
- macOS
- Linux

### 2. Copy the compiles sources to package

Copy all compiled source files from step 1 to [./package/assets/sources](package/assets/sources).
