set -e
export PUB_CACHE=/work/.pub-cache
mkdir -p /work
tar -C /src --exclude=.dart_tool --exclude=./tool/kosherjava_parity/build --exclude=./.git -cf - . | tar -C /work -xf -
cd /work/tool/kosherjava_parity
mkdir -p build/jni_libs
cp /src/tool/kosherjava_parity/build/kosherjava.jar build/
cp /src/tool/kosherjava_parity/build/jni_libs/jni.jar build/jni_libs/
dart pub get >/dev/null
if [ ! -f build/jni_libs/libdartjni.so ]; then
  JNI_ROOT=$(grep -o '"rootUri": "file://[^"]*/jni-[0-9][^"]*"' .dart_tool/package_config.json | sed 's/.*file:\/\///; s/"$//')
  gcc -shared -fPIC -O2 -DDART_SHARED_LIB -I "$JNI_ROOT/src" -I "$JNI_ROOT/third_party" \
      "$JNI_ROOT/src/dartjni.c" "$JNI_ROOT/src/third_party/global_jni_env.c" "$JNI_ROOT/src/include/dart_api_dl.c" \
      -L "$JAVA_HOME/lib/server" -ljvm -lpthread -o build/jni_libs/libdartjni.so
  echo "$JAVA_HOME" > build/java_home
fi
[ -n "$SETUP_ONLY" ] && exit 0
exec dart run bin/parity.dart "$@"
