#!/bin/bash

#
# Copyright (c) Shawn Singh, Mubbasir Kapadia, Petros Faloutsos, Glenn Reinman, Glen Berseth
# See license.txt for complete license.
#


#
# USER OPTIONS:
#
# Edit the following variables to configure
# the build process to fit your needs.
#
# For boolean options, use either lowercase "true"
# or lowercase "false".
#

# Change the following three variables if you plan to "install" SteerSuite
# somewhere else.  NOTE: if you change these, the "cleanall" script will
# not remove them, you will have to remove them yourself.
BIN_DIR=`pwd`/bin/
LIB_DIR=`pwd`/lib/
MODULES_DIR=`pwd`/modules/

# If "true" a 32 bit version will compiled
ENABLE_32BIT="true"

# If "true", GLFW (an openGL window framework) will be compiled into SteerSim.
ENABLE_GLFW_GUI="false"

# If "true", a more extensive Qt GUI will be compiled into SteerSim.
# You will need to specify Qt lib and include paths as well.
ENABLE_QT_GUI="false"
QT_LIB_DIR=""
QT_INCLUDE_DIR=""
QT_MOC=""

# These args will be passed to the makefile command.
# One useful option is to use "-j 3" or "-j 4" to
# speed up the build process.  (requires a recent
# version of GNU Make)
MAKE_ARGS="-j 16"



####################################################################
# Should not need to modify anything below this point in the file.
####################################################################


# Check that the user options are consistent.

if [ "$ENABLE_GLFW_GUI" != "true" -a "$ENABLE_GLFW_GUI" != "false" ]; then
    echo ""
    echo "ERROR: User option ENABLE_GLFW_GUI does not have valid value. Use lower case \"true\" or \"false\"."
    exit 1
fi

if [ "$ENABLE_QT_GUI" != "true" -a "$ENABLE_QT_GUI" != "false" ]; then
    echo ""
    echo "ERROR: User option ENABLE_QT_GUI does not have valid value. Use lower case \"true\" or \"false\"."
    exit 1
fi

if [ "$ENABLE_GLFW_GUI" == "true" -a "$ENABLE_32BIT" == "true" ]; then
    echo ""
    echo "ERROR: GLFW does not work currently in 32bit mode. Set either ENABLE_GLFW_GUI or ENABLE_32BIT to \"false\"."
    exit 1
fi


# The SteerSuite build process requires gmake (GNU Make),
# but on many systems "make" is in fact gmake. Here, we
# prefer to use "gmake" if it exists, and use "make" as
# a backup.

if [ -z "`which gmake`" ]; then
    # gmake not found in this case.
    MAKE=make
else
    MAKE=gmake
fi



# The following several chunks of code compute the
# linker options and preprocessor defines for each
# component of SteerSuite.

if [ "$ENABLE_32BIT" == "true" ] ; then
	echo ""
	echo "BUILDING a 32 bit version"
	BASIC_LFLAGS="-Wall -O2 -m32 -std=c++0x"
	BASIC_CFLAGS="-Wall -O2 -m32 -std=c++0x"
else
	BASIC_LFLAGS="-Wall -O2 -std=c++0x"
	BASIC_CFLAGS="-Wall -O2 -std=c++0x"
fi
STEERLIB_LINK="-L../../steerlib/build -lsteer"

BASIC_INCLUDES="-I../include -I../../external"
STEERLIB_INCLUDE="-I../../steerlib/include"

BUILD_PLATFORM="$1"
#BUILD_MODULE="all"
BUILD_MODULE="$2" # To build individual modules if they exist

# these variables start blank, but may be filled-in depending on
# the user options specified at the top of this file.
GUI_DEFINES=""
OPENGL_LINK=""
GLFW_LINK=""
QT_LINK=""
QT_INCLUDES=""


if [ "$ENABLE_GLFW_GUI" == "true" -o "$ENABLE_QT_GUI" == "true" ]; then
    GUI_DEFINES="$GUI_DEFINES -DENABLE_GUI"
fi

if [ "$ENABLE_GLFW_GUI" == "true" ]; then
    GUI_DEFINES="$GUI_DEFINES -DENABLE_GLFW"
fi

if [ "$ENABLE_QT_GUI" == "true" ]; then	
    GUI_DEFINES="$GUI_DEFINES -DENABLE_QT"
fi


if [ "$BUILD_PLATFORM" == "osx" ]; then
    echo "Building SteerSuite for Mac OS X"
    RPATH_LFLAGS="-Wl,-rpath,$LIB_DIR"
    OSX_DYLIB_LFLAGS="-dynamiclib -install_name @rpath/\$(TARGET_NAME)"
    if [ "$ENABLE_GLFW_GUI" == "true" -o "$ENABLE_QT_GUI" == "true" ]; then
	OPENGL_LINK="-L/usr/X11/lib -lGL -lGLU"
    fi
    if [ "$ENABLE_GLFW_GUI" == "true" ]; then
	GLFW_LINK="-L../../external/glfw/lib/macosx -lglfw"
    fi
    if [ "$ENABLE_QT_GUI" == "true" ]; then
	# todo, fill in this blank QT_LINK variable when testing qt with osx
	echo "WARNING: Qt support not tested for OSX."
	echo "         Currently QT_LINK is empty and therefore will not compile."
	QT_LINK=""
	QT_INCLUDES="-I$QT_INCLUDE_DIR"
    fi

    STEERLIB_INCLUDES="$BASIC_INCLUDES"
    STEERBENCH_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    STEERSIM_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE $QT_INCLUDES"
    STEERTOOL_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    SIMPLEAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    PPRAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    EGOCENTRICAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    FOOTSTEPAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    SCENARIO_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"

    BUILD_SCRIPT_DEFINES="-D_OSX $GUI_DEFINES"
    STEERLIB_LFLAGS="$BASIC_LFLAGS $OSX_DYLIB_LFLAGS $OPENGL_LINK -lpthread -ldl"
    STEERBENCH_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK"
    STEERSIM_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $GLFW_LINK $OPENGL_LINK $QT_LINK $STEERLIB_LINK"
    STEERTOOL_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK"
    SIMPLEAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $OSX_DYLIB_LFLAGS $STEERLIB_LINK"
    PPRAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $OSX_DYLIB_LFLAGS $STEERLIB_LINK"
    EGOCENTRICAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $OSX_DYLIB_LFLAGS $STEERLIB_LINK"
    FOOTSTEPAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $OSX_DYLIB_LFLAGS $STEERLIB_LINK"
    SCENARIO_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"

elif [ "$BUILD_PLATFORM" == "linux" ]; then
    echo "Building SteerSuite for Linux"
    RPATH_LFLAGS="-Wl,-rpath,$LIB_DIR"
    if [ "$ENABLE_GLFW_GUI" == "true" -o "$ENABLE_QT_GUI" == "true" ]; then
	OPENGL_LINK="-lGL -lGLU"
    fi
    if [ "$ENABLE_GLFW_GUI" == "true" ]; then
	GLFW_LINK="-L../../external/glfw/lib/x11 -lglfw"
    fi
    if [ "$ENABLE_QT_GUI" == "true" ]; then
	QT_LINK="-L$QT_LIB_DIR -lQtCore -lQtGui -lQtOpenGL"
	QT_INCLUDES="-I$QT_INCLUDE_DIR -I."
    fi

    STEERLIB_INCLUDES="$BASIC_INCLUDES"
    STEERBENCH_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    STEERSIM_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE $QT_INCLUDES"
    STEERTOOL_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    SIMPLEAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    PPRAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    EGOCENTRICAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    FOOTSTEPAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    SCENARIO_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    

    BUILD_SCRIPT_DEFINES="-D_LINUX $GUI_DEFINES"
    STEERLIB_LFLAGS="$BASIC_LFLAGS $OPENGL_LINK -lpthread -ldl"
    STEERBENCH_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK"
    STEERSIM_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $GLFW_LINK $OPENGL_LINK $QT_LINK $STEERLIB_LINK"
    STEERTOOL_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK"
    SIMPLEAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    PPRAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    EGOCENTRICAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    FOOTSTEPAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    SCENARIO_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"

        

elif [ "$BUILD_PLATFORM" == "solaris" ]; then
    echo "Building SteerSuite for Solaris"
    RPATH_LFLAGS="-R $LIB_DIR"
    if [ "$ENABLE_GLFW_GUI" == "true" -o "$ENABLE_QT_GUI" == "true" ]; then
	OPENGL_LINK="-lGL -lGLU"
    fi
    if [ "$ENABLE_GLFW_GUI" == "true" ]; then
	GLFW_LINK="-L../../external/glfw/lib/x11 -lglfw"
    fi
    if [ "$ENABLE_QT_GUI" == "true" ]; then
	echo "WARNING: Qt support not tested for Solaris."
	echo "         Currently QT_LINK is empty and therefore will not compile."
	QT_LINK=""
	QT_INCLUDES="-I$QT_INCLUDE_DIR"
    fi

    STEERLIB_INCLUDES="$BASIC_INCLUDES"
    STEERBENCH_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    STEERSIM_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE $QT_INCLUDES"
    STEERTOOL_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    SIMPLEAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    PPRAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    EGOCENTRICAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    FOOTSTEPAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    SCENARIO_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"

    BUILD_SCRIPT_DEFINES="-D_SOLARIS $GUI_DEFINES"
    STEERLIB_LFLAGS="$BASIC_LFLAGS $OPENGL_LINK -lpthread -ldl -lrt"
    STEERBENCH_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK"
    STEERSIM_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $GLFW_LINK $OPENGL_LINK $QT_LINK $STEERLIB_LINK -lrt"
    STEERTOOL_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK -lrt"
    SIMPLEAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    PPRAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    EGOCENTRICAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    FOOTSTEPAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    SCENARIO_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"

elif [ "$BUILD_PLATFORM" == "simics" ]; then
    echo "Building SteerSuite for Simics simulation environment"
    if [ "$ENABLE_GLFW_GUI" == "true" -o "$ENABLE_QT_GUI" == "true" ]; then
	echo "NOTE: Overriding user option, OpenGL is excluded when building for simics."
    fi
    if [ "$ENABLE_GLFW_GUI" == "true" ]; then
	echo "NOTE: Overriding user option, GLFW is excluded when building for simics."
	ENABLE_GLFW_GUI="false"
    fi
    if [ "$ENABLE_QT_GUI" == "true" ]; then	
	echo "NOTE: Overriding user option, Qt is excluded when building for simics."
	ENABLE_QT_GUI="false"
    fi
    RPATH_LFLAGS="-R $LIB_DIR:/usr/local/lib/:."
    OPENGL_LINK=""
    GLFW_LINK=""

    STEERLIB_INCLUDES="$BASIC_INCLUDES"
    STEERBENCH_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    STEERSIM_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    STEERTOOL_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    SIMPLEAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    PPRAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    EGOCENTRICAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    FOOTSTEPAI_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"
    SCENARIO_INCLUDES="$BASIC_INCLUDES $STEERLIB_INCLUDE"

    BUILD_SCRIPT_DEFINES="-D_SOLARIS"
    STEERLIB_LFLAGS="$BASIC_LFLAGS -lpthread -ldl -lrt"
    STEERBENCH_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK"
    STEERSIM_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK -lrt"
    STEERTOOL_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS $STEERLIB_LINK -lrt"
    SIMPLEAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    PPRAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    EGOCENTRICAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    FOOTSTEPAI_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"
    SCENARIO_LFLAGS="$BASIC_LFLAGS $RPATH_LFLAGS"

else
    EXECUTABLE=`basename $0`
    echo ""
    echo "Please use one of the following:"
    echo ""
    echo "$EXECUTABLE osx"
    echo "$EXECUTABLE linux"
    echo "$EXECUTABLE solaris"
    echo "$EXECUTABLE simics" 
    echo ""
    echo "Visual Studio 2008 project files can be found in the win32/ directory."
    echo ""
    exit 1
fi


# make these variables into environment variables so
# so that Makefiles can use them.

export ADDITIONAL_INCLUDES

export BASIC_CFLAGS
export STEERLIB_INCLUDES
export STEERBENCH_INCLUDES
export STEERSIM_INCLUDES
export STEERTOOL_INCLUDES
export SIMPLEAI_INCLUDES
export PPRAI_INCLUDES
export EGOCENTRICAI_INCLUDES
export FOOTSTEPAI_INCLUDES
export SCENARIO_INCLUDES

export BUILD_SCRIPT_DEFINES
export STEERLIB_LFLAGS
export STEERBENCH_LFLAGS
export STEERSIM_LFLAGS
export STEERTOOL_LFLAGS
export SIMPLEAI_LFLAGS
export PPRAI_LFLAGS
export EGOCENTRICAI_LFLAGS
export FOOTSTEPAI_LFLAGS
export SCENARIO_LFLAGS



# The rest of the script runs the build process for
# each component.  After building all components, it
# will copy the components to the LIB_DIR, BIN_DIR,
# and MODULES_DIR directories that the user specified
# above.

if [[ "$ENABLE_GLFW_GUI" == "true" && $BUILD_MODULE == "all" || $BUILD_MODULE == "glfw" ]]; then
    echo "==================================="
    echo "Building GLFW (external dependency)"
    echo "==================================="
    pushd ../external/glfw > /dev/null
    if [ "$BUILD_PLATFORM" == "osx" ]; then
        $MAKE macosx-gcc
	GLFW_BUILD_RETURN_CODE=$?
    else
        $MAKE x11
	GLFW_BUILD_RETURN_CODE=$?
    fi
    popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "steerlib" ]]; then
	echo "==================================="
	echo "Building SteerLib"
	echo "==================================="
	pushd ../steerlib/build > /dev/null
	$MAKE $MAKE_ARGS
	STEERLIB_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "steerbench" ]]; then
	echo "==================================="
	echo "Building SteerBench"
	echo "==================================="
	pushd ../steerbench/build > /dev/null
	$MAKE $MAKE_ARGS
	STEERBENCH_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "steersim" ]]; then
	echo "==================================="
	echo "Building SteerSim"
	echo "==================================="
	pushd ../steersim/build > /dev/null
	# TODO: later on, move this moc-file generation into the makefile itself.
	if [ "$ENABLE_QT_GUI" == "true" ]; then
	    for QT_FILE in ../include/qtgui/*.h; do
		if [ -n `grep Q_OBJECT $QT_FILE` ]; then
		    BASE=`basename $QT_FILE .h`
		    echo "generating moc_$BASE.cpp"
		    $QT_MOC $BUILD_SCRIPT_DEFINES $STEERSIM_INCLUDES $QT_FILE -o autogenerated/moc_$BASE.cpp
		fi
	    done
	fi
	$MAKE $MAKE_ARGS
	STEERSIM_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "steertool" ]]; then
	echo "==================================="
	echo "Building SteerTool"
	echo "==================================="
	pushd ../steertool/build > /dev/null
	$MAKE $MAKE_ARGS
	STEERTOOL_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "simpleAI" ]]; then
	echo "==================================="
	echo "Building Simple AI module"
	echo "==================================="
	pushd ../simpleAI/build > /dev/null
	$MAKE $MAKE_ARGS
	SIMPLEAI_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "pprAI" ]]; then
	echo "==================================="
	echo "Building PPR AI module"
	echo "==================================="
	pushd ../pprAI/build > /dev/null
	$MAKE $MAKE_ARGS
	PPRAI_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "footstepAI" ]]; then
	echo "==================================="
	echo "Building FOOTSTEPS AI module"
	echo "==================================="
	pushd ../footstepAI/build > /dev/null
	$MAKE $MAKE_ARGS
	FOOTSTEPAI_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "scenario" ]]; then
	echo "==================================="
	echo "Building SCENARIO module"
	echo "==================================="
	pushd ../scenario/build > /dev/null
	$MAKE $MAKE_ARGS
	SCENARIO_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi

if [[ $BUILD_MODULE == "all" || $BUILD_MODULE == "egocentricAI" ]]; then
	echo "==================================="
	echo "Building Egocentric AI module"
	echo "==================================="
	echo "egocentric AI will be available in a later version."
	pushd ../egocentricAI/build > /dev/null
	$MAKE $MAKE_ARGS
	EGOCENTRICAI_BUILD_RETURN_CODE=$?
	popd > /dev/null
fi


mkdir -p $BIN_DIR
mkdir -p $LIB_DIR
mkdir -p $MODULES_DIR

echo "==================================="
echo "Installing binaries"
echo "==================================="


# For the components that compiled successfully, copy them to the desired
# location is specified by LIB_DIR, BIN_DIR, and MODULES_DIR at the 
# top of this script.

if [ "$ENABLE_GLFW_GUI" == "true" ]; then
    if [ $GLFW_BUILD_RETURN_CODE == 0 ]; then
	if [ "$BUILD_PLATFORM" == "osx" ]; then
	    echo "copying libglfw.dylib to $LIB_DIR"
	    cp ../external/glfw/lib/macosx/libglfw.dylib $LIB_DIR
	    GLFW_INSTALL_RETURN_CODE=$?
	else
	    echo "copying libglfw.so to $LIB_DIR"
	    cp ../external/glfw/lib/x11/libglfw.so $LIB_DIR
	    GLFW_INSTALL_RETURN_CODE=$?
	fi
    fi
fi

if [ $STEERLIB_BUILD_RETURN_CODE == 0 ]; then
    echo "copying libsteer.so to $LIB_DIR"
    cp ../steerlib/build/libsteer.so $LIB_DIR
    STEERLIB_INSTALL_RETURN_CODE=$?
fi

if [ $STEERBENCH_BUILD_RETURN_CODE == 0 ]; then
    echo "copying steerbench to $BIN_DIR"
    cp ../steerbench/build/steerbench $BIN_DIR
    STEERBENCH_INSTALL_RETURN_CODE=$?
fi

if [ $STEERSIM_BUILD_RETURN_CODE == 0 ]; then
    echo "copying steersim to $BIN_DIR"
    cp ../steersim/build/steersim $BIN_DIR
    STEERSIM_INSTALL_RETURN_CODE=$?
fi

if [ $STEERTOOL_BUILD_RETURN_CODE == 0 ]; then
    echo "copying steertool to $BIN_DIR"
    cp ../steertool/build/steertool $BIN_DIR
    STEERTOOL_INSTALL_RETURN_CODE=$?
fi

if [ $SIMPLEAI_BUILD_RETURN_CODE == 0 ]; then
    echo "copying simpleAI.o to $MODULES_DIR"
    cp ../simpleAI/build/simpleAI.o $MODULES_DIR
    SIMPLEAI_INSTALL_RETURN_CODE=$?
fi

if [ $PPRAI_BUILD_RETURN_CODE == 0 ]; then
    echo "copying pprAI.o to $MODULES_DIR"
    cp ../pprAI/build/pprAI.o $MODULES_DIR
    PPRAI_INSTALL_RETURN_CODE=$?
fi

if [ $FOOTSTEPAI_BUILD_RETURN_CODE == 0 ];
then
    echo "copying footstepAI.o to $MODULES_DIR"
    cp ../footstepAI/build/footstepAI.o $MODULES_DIR
    FOOTSTEPAI_INSTALL_RETURN_CODE=$?
fi

if [ $SCENARIO_BUILD_RETURN_CODE == 0 ]; then
    echo "copying scenario.o to $MODULES_DIR"
    cp ../scenario/build/scenario.o $MODULES_DIR
    SCENARIO_INSTALL_RETURN_CODE=$?
fi

#if [ $EGOCENTRICAI_BUILD_RETURN_CODE == 0 ]; then
#    echo "copying egocentricAI.o to $MODULES_DIR"
#    cp ../egocentricAI/build/egocentricAI.o $MODULES_DIR
#    EGOCENTRICAI_INSTALL_RETURN_CODE=$?
#fi

echo ""
echo "Summary:"

if [ "$ENABLE_GLFW_GUI" == "true" ]; then
    if [ $GLFW_BUILD_RETURN_CODE != 0 ]; then
	echo "* GLFW did not build properly."
    else
	if [ $GLFW_INSTALL_RETURN_CODE != 0 ]; then
	    echo "* GLFW built successfully, but could not be installed to $LIB_DIR."
	else
	    echo "  GLFW built and installed successfully."
	fi
    fi
fi

if [ $STEERLIB_BUILD_RETURN_CODE != 0 ]; then
    echo "* SteerLib did not build properly."
else
    if [ $STEERLIB_INSTALL_RETURN_CODE != 0 ]; then
	echo "* SteerLib built successfully, but could not be installed to $LIB_DIR."
    else
	echo "  SteerLib built and installed successfully."
    fi
fi

if [ $STEERBENCH_BUILD_RETURN_CODE != 0 ]; then
    echo "* SteerBench did not build properly."
else
    if [ $STEERBENCH_INSTALL_RETURN_CODE != 0 ]; then
	echo "* SteerBench built successfully, but could not be installed to $BIN_DIR."
    else
	echo "  SteerBench built and installed successfully."
    fi
fi

if [ $STEERSIM_BUILD_RETURN_CODE != 0 ]; then
    echo "* SteerSim did not build properly."
else
    if [ $STEERSIM_INSTALL_RETURN_CODE != 0 ]; then
	echo "* SteerSim built successfully, but could not be installed to $BIN_DIR."
    else
	echo "  SteerSim built and installed successfully."
    fi
fi

if [ $STEERTOOL_BUILD_RETURN_CODE != 0 ]; then
    echo "* SteerTool did not build properly."
else
    if [ $STEERTOOL_INSTALL_RETURN_CODE != 0 ]; then
	echo "* SteerTool built successfully, but could not be installed to $BIN_DIR."
    else
	echo "  SteerTool built and installed successfully."
    fi
fi

if [ $SIMPLEAI_BUILD_RETURN_CODE != 0 ]; then
    echo "* SimpleAI did not build properly."
else
    if [ $SIMPLEAI_INSTALL_RETURN_CODE != 0 ]; then
	echo "* SimpleAI built successfully, but could not be installed to $MODULES_DIR."
    else
	echo "  SimpleAI built and installed successfully."
    fi
fi

if [ $PPRAI_BUILD_RETURN_CODE != 0 ]; then
    echo "* PPR AI did not build properly."
else
    if [ $PPRAI_INSTALL_RETURN_CODE != 0 ]; then
	echo "* PPR AI built successfully, but could not be installed to $MODULES_DIR."
    else
	echo "  PPR AI built and installed successfully."
    fi
fi

if [ $FOOTSTEPAI_BUILD_RETURN_CODE != 0 ]; then
    echo "* FOOTSTEPAI AI did not build properly."
else
    if [ $FOOTSTEPAI_INSTALL_RETURN_CODE != 0 ]; then
	echo "* FOOTSTEPAI AI built successfully, but could not be installed to $MODULES_DIR."
    else
	echo "  FOOTSTEPAI AI built and installed successfully."
    fi
fi

if [ $SCENARIO_BUILD_RETURN_CODE != 0 ]; then
    echo "* scenario did not build properly."
else
    if [ $SCENARIO_INSTALL_RETURN_CODE != 0 ]; then
	echo "* scenario built successfully, but could not be installed to $MODULES_DIR."
    else
	echo "  scenario built and installed successfully."
    fi
fi

#if [ $EGOCENTRICAI_BUILD_RETURN_CODE != 0 ]; then
#    echo "* EgocentricAI did not build properly."
#else
#    if [ $EGOCENTRICAI_INSTALL_RETURN_CODE != 0 ]; then
#	echo "* EgocentricAI built successfully, but could not be installed to $MODULES_DIR."
#    else
#	echo "  EgocentricAI built and installed successfully."
#    fi
#fi

echo ""
