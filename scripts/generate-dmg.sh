BUILD_CONFIG=$1

fail()
{
	echo "$1" 1>&2
	exit 1
}

if [ "$BUILD_CONFIG" != "Debug" ] && [ "$BUILD_CONFIG" != "Release" ]; then
  fail "Invalid build configuration"
fi

BUILD_ROOT=$PWD/build
SOURCE_ROOT=$PWD
BUILD_FOLDER=$BUILD_ROOT/build-$BUILD_CONFIG
INSTALLER_FOLDER=$BUILD_ROOT/installer-$BUILD_CONFIG

echo Cleaning output directories
rm -rf $BUILD_FOLDER
rm -rf $INSTALLER_FOLDER
mkdir $BUILD_ROOT
mkdir $BUILD_FOLDER
mkdir $INSTALLER_FOLDER

echo Configuring the project
pushd $BUILD_FOLDER
qmake $SOURCE_ROOT/moonlight-qt.pro || fail "Qmake failed!"
popd

echo Compiling Moonlight in $BUILD_CONFIG configuration
pushd $BUILD_FOLDER
make $(echo "$BUILD_CONFIG" | tr '[:upper:]' '[:lower:]') || fail "Make failed!"
popd

echo Copying dylib dependencies
mkdir $BUILD_FOLDER/app/Moonlight.app/Contents/lib
cp $SOURCE_ROOT/libs/mac/lib/*.dylib $BUILD_FOLDER/app/Moonlight.app/Contents/lib/ || fail "Dylib copy failed!"

echo Copying frameworks dependencies
mkdir $BUILD_FOLDER/app/Moonlight.app/Contents/Frameworks
cp -R $SOURCE_ROOT/libs/mac/Frameworks/ $BUILD_FOLDER/app/Moonlight.app/Contents/Frameworks/ || fail "Framework copy failed!"

echo Creating DMG
EXTRA_ARGS=
if [ "$BUILD_CONFIG" == "Debug" ]; then EXTRA_ARGS="$EXTRA_ARGS -use-debug-libs"; fi
if [ "$SIGNING_KEY" != "" ]; then EXTRA_ARGS="$EXTRA_ARGS -codesign=$SIGNING_KEY"; fi
echo Extra deployment arguments: $EXTRA_ARGS
macdeployqt $BUILD_FOLDER/app/Moonlight.app -dmg $EXTRA_ARGS -qmldir=$SOURCE_ROOT/app/gui -appstore-compliant || fail "macdeployqt failed!"

echo Deploying DMG
mv $BUILD_FOLDER/app/Moonlight.dmg $INSTALLER_FOLDER/
