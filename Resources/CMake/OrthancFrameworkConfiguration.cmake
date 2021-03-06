##
## This is a CMake configuration file that configures the core
## libraries of Orthanc. This file can be used by external projects so
## as to gain access to the Orthanc APIs (the most prominent examples
## are currently "Stone of Orthanc" and "Orthanc for whole-slide
## imaging plugin").
##


#####################################################################
## Configuration of the components
#####################################################################

# Path to the root folder of the Orthanc distribution
set(ORTHANC_ROOT ${CMAKE_CURRENT_LIST_DIR}/../..)

# Some basic inclusions
include(CMakePushCheckState)
include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckIncludeFileCXX)
include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CheckStructHasMember)
include(CheckSymbolExists)
include(CheckTypeSize)
include(FindPythonInterp)
  
include(${CMAKE_CURRENT_LIST_DIR}/AutoGeneratedCode.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/DownloadPackage.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/Compiler.cmake)


#####################################################################
## Disable unneeded macros
#####################################################################

if (NOT ENABLE_SQLITE)
  unset(USE_SYSTEM_SQLITE CACHE)
  add_definitions(-DORTHANC_ENABLE_SQLITE=0)
endif()

if (NOT ENABLE_CRYPTO_OPTIONS)
  unset(ENABLE_SSL CACHE)
  unset(ENABLE_PKCS11 CACHE)
  unset(ENABLE_OPENSSL_ENGINES CACHE)
  unset(USE_SYSTEM_OPENSSL CACHE)
  unset(USE_SYSTEM_LIBP11 CACHE)
  add_definitions(
    -DORTHANC_ENABLE_SSL=0
    -DORTHANC_ENABLE_PKCS11=0
    )
endif()

if (NOT ENABLE_WEB_CLIENT)
  unset(USE_SYSTEM_CURL CACHE)
  add_definitions(-DORTHANC_ENABLE_CURL=0)
endif()

if (NOT ENABLE_WEB_SERVER)
  unset(ENABLE_CIVETWEB CACHE)
  unset(USE_SYSTEM_CIVETWEB CACHE)
  unset(USE_SYSTEM_MONGOOSE CACHE)
  add_definitions(
    -DORTHANC_ENABLE_CIVETWEB=0
    -DORTHANC_ENABLE_MONGOOSE=0
    )
endif()

if (NOT ENABLE_JPEG)
  unset(USE_SYSTEM_LIBJPEG CACHE)
  add_definitions(-DORTHANC_ENABLE_JPEG=0)
endif()

if (NOT ENABLE_ZLIB)
  unset(USE_SYSTEM_ZLIB CACHE)
  add_definitions(-DORTHANC_ENABLE_ZLIB=0)
endif()

if (NOT ENABLE_PNG)
  unset(USE_SYSTEM_LIBPNG CACHE)
  add_definitions(-DORTHANC_ENABLE_PNG=0)
endif()

if (NOT ENABLE_LUA)
  unset(USE_SYSTEM_LUA CACHE)
  unset(ENABLE_LUA_MODULES CACHE)
  add_definitions(-DORTHANC_ENABLE_LUA=0)
endif()

if (NOT ENABLE_PUGIXML)
  unset(USE_SYSTEM_PUGIXML CACHE)
  add_definitions(-DORTHANC_ENABLE_PUGIXML=0)
endif()

if (NOT ENABLE_LOCALE)
  unset(USE_SYSTEM_LIBICONV CACHE)
  add_definitions(-DORTHANC_ENABLE_LOCALE=0)
endif()

if (NOT ENABLE_GOOGLE_TEST)
  unset(USE_SYSTEM_GOOGLE_TEST CACHE)
  unset(USE_GOOGLE_TEST_DEBIAN_PACKAGE CACHE)
endif()

if (NOT ENABLE_DCMTK)
  add_definitions(
    -DORTHANC_ENABLE_DCMTK=0
    -DORTHANC_ENABLE_DCMTK_NETWORKING=0
    )
  unset(DCMTK_DICTIONARY_DIR CACHE)
  unset(USE_DCMTK_360 CACHE)
  unset(USE_DCMTK_362_PRIVATE_DIC CACHE)
  unset(USE_SYSTEM_DCMTK CACHE)
  unset(ENABLE_DCMTK_JPEG CACHE)
  unset(ENABLE_DCMTK_JPEG_LOSSLESS CACHE)
endif()


#####################################################################
## List of source files
#####################################################################

set(ORTHANC_CORE_SOURCES_INTERNAL
  ${ORTHANC_ROOT}/Core/Cache/MemoryCache.cpp
  ${ORTHANC_ROOT}/Core/ChunkedBuffer.cpp
  ${ORTHANC_ROOT}/Core/DicomFormat/DicomTag.cpp
  ${ORTHANC_ROOT}/Core/Enumerations.cpp
  ${ORTHANC_ROOT}/Core/FileStorage/MemoryStorageArea.cpp
  ${ORTHANC_ROOT}/Core/Logging.cpp
  ${ORTHANC_ROOT}/Core/SerializationToolbox.cpp
  ${ORTHANC_ROOT}/Core/Toolbox.cpp
  ${ORTHANC_ROOT}/Core/WebServiceParameters.cpp
  )

if (ENABLE_MODULE_IMAGES)
  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/Images/Font.cpp
    ${ORTHANC_ROOT}/Core/Images/FontRegistry.cpp
    ${ORTHANC_ROOT}/Core/Images/IImageWriter.cpp
    ${ORTHANC_ROOT}/Core/Images/Image.cpp
    ${ORTHANC_ROOT}/Core/Images/ImageAccessor.cpp
    ${ORTHANC_ROOT}/Core/Images/ImageBuffer.cpp
    ${ORTHANC_ROOT}/Core/Images/ImageProcessing.cpp
    ${ORTHANC_ROOT}/Core/Images/PamReader.cpp
    ${ORTHANC_ROOT}/Core/Images/PamWriter.cpp
    )
endif()

if (ENABLE_MODULE_DICOM)
  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/DicomFormat/DicomArray.cpp
    ${ORTHANC_ROOT}/Core/DicomFormat/DicomImageInformation.cpp
    ${ORTHANC_ROOT}/Core/DicomFormat/DicomInstanceHasher.cpp
    ${ORTHANC_ROOT}/Core/DicomFormat/DicomIntegerPixelAccessor.cpp
    ${ORTHANC_ROOT}/Core/DicomFormat/DicomMap.cpp
    ${ORTHANC_ROOT}/Core/DicomFormat/DicomValue.cpp
    )
endif()

if (ENABLE_MODULE_JOBS)
  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/JobsEngine/GenericJobUnserializer.cpp
    ${ORTHANC_ROOT}/Core/JobsEngine/JobInfo.cpp
    ${ORTHANC_ROOT}/Core/JobsEngine/JobStatus.cpp
    ${ORTHANC_ROOT}/Core/JobsEngine/JobStepResult.cpp
    ${ORTHANC_ROOT}/Core/JobsEngine/Operations/JobOperationValues.cpp
    ${ORTHANC_ROOT}/Core/JobsEngine/Operations/LogJobOperation.cpp
    ${ORTHANC_ROOT}/Core/JobsEngine/Operations/SequenceOfOperationsJob.cpp
    ${ORTHANC_ROOT}/Core/JobsEngine/SetOfCommandsJob.cpp
    ${ORTHANC_ROOT}/Core/JobsEngine/SetOfInstancesJob.cpp
    )
endif()



#####################################################################
## Configuration of optional third-party dependencies
#####################################################################


##
## Embedded database: SQLite
##

if (ENABLE_SQLITE)
  include(${CMAKE_CURRENT_LIST_DIR}/SQLiteConfiguration.cmake)
  add_definitions(-DORTHANC_ENABLE_SQLITE=1)

  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/SQLite/Connection.cpp
    ${ORTHANC_ROOT}/Core/SQLite/FunctionContext.cpp
    ${ORTHANC_ROOT}/Core/SQLite/Statement.cpp
    ${ORTHANC_ROOT}/Core/SQLite/StatementId.cpp
    ${ORTHANC_ROOT}/Core/SQLite/StatementReference.cpp
    ${ORTHANC_ROOT}/Core/SQLite/Transaction.cpp
    )
endif()


##
## Cryptography: OpenSSL and libp11
## Must be above "ENABLE_WEB_CLIENT" and "ENABLE_WEB_SERVER"
##

if (ENABLE_CRYPTO_OPTIONS)
  if (ENABLE_SSL)
    include(${CMAKE_CURRENT_LIST_DIR}/OpenSslConfiguration.cmake)
    add_definitions(-DORTHANC_ENABLE_SSL=1)
  else()
    unset(ENABLE_OPENSSL_ENGINES CACHE)
    unset(USE_SYSTEM_OPENSSL CACHE)
    add_definitions(-DORTHANC_ENABLE_SSL=0)
  endif()

  if (ENABLE_PKCS11)
    if (ENABLE_SSL)
      include(${CMAKE_CURRENT_LIST_DIR}/LibP11Configuration.cmake)

      add_definitions(-DORTHANC_ENABLE_PKCS11=1)
      list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
        ${ORTHANC_ROOT}/Core/Pkcs11.cpp
        )
    else()
      message(FATAL_ERROR "OpenSSL is required to enable PKCS#11 support")
    endif()
  else()
    add_definitions(-DORTHANC_ENABLE_PKCS11=0)  
  endif()
endif()


##
## HTTP client: libcurl
##

if (ENABLE_WEB_CLIENT)
  include(${CMAKE_CURRENT_LIST_DIR}/LibCurlConfiguration.cmake)
  add_definitions(-DORTHANC_ENABLE_CURL=1)

  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/HttpClient.cpp
    )
endif()


##
## HTTP server: Mongoose 3.8 or Civetweb
##

if (ENABLE_WEB_SERVER)
  if (ENABLE_CIVETWEB)
    include(${CMAKE_CURRENT_LIST_DIR}/CivetwebConfiguration.cmake)
    add_definitions(
      -DORTHANC_ENABLE_CIVETWEB=1
      -DORTHANC_ENABLE_MONGOOSE=0
      )
  else()
    include(${CMAKE_CURRENT_LIST_DIR}/MongooseConfiguration.cmake)
    add_definitions(
      -DORTHANC_ENABLE_CIVETWEB=0
      -DORTHANC_ENABLE_MONGOOSE=1
      )
  endif()

  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/HttpServer/BufferHttpSender.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/FilesystemHttpHandler.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/FilesystemHttpSender.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/HttpContentNegociation.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/HttpFileSender.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/HttpOutput.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/HttpStreamTranscoder.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/HttpToolbox.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/MongooseServer.cpp
    ${ORTHANC_ROOT}/Core/HttpServer/StringHttpOutput.cpp
    ${ORTHANC_ROOT}/Core/RestApi/RestApi.cpp
    ${ORTHANC_ROOT}/Core/RestApi/RestApiCall.cpp
    ${ORTHANC_ROOT}/Core/RestApi/RestApiGetCall.cpp
    ${ORTHANC_ROOT}/Core/RestApi/RestApiHierarchy.cpp
    ${ORTHANC_ROOT}/Core/RestApi/RestApiOutput.cpp
    ${ORTHANC_ROOT}/Core/RestApi/RestApiPath.cpp
    )
endif()


##
## JPEG support: libjpeg
##

if (ENABLE_JPEG)
  if (NOT ENABLE_MODULE_IMAGES)
    message(FATAL_ERROR "Image processing primitives must be enabled if enabling libjpeg support")
  endif()

  include(${CMAKE_CURRENT_LIST_DIR}/LibJpegConfiguration.cmake)
  add_definitions(-DORTHANC_ENABLE_JPEG=1)

  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/Images/JpegErrorManager.cpp
    ${ORTHANC_ROOT}/Core/Images/JpegReader.cpp
    ${ORTHANC_ROOT}/Core/Images/JpegWriter.cpp
    )
endif()


##
## zlib support
##

if (ENABLE_ZLIB)
  include(${CMAKE_CURRENT_LIST_DIR}/ZlibConfiguration.cmake)
  add_definitions(-DORTHANC_ENABLE_ZLIB=1)

  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/Compression/DeflateBaseCompressor.cpp
    ${ORTHANC_ROOT}/Core/Compression/GzipCompressor.cpp
    ${ORTHANC_ROOT}/Core/Compression/ZlibCompressor.cpp
    )

  if (NOT ORTHANC_SANDBOXED)
    list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
      ${ORTHANC_ROOT}/Core/Compression/HierarchicalZipWriter.cpp
      ${ORTHANC_ROOT}/Core/Compression/ZipWriter.cpp
      ${ORTHANC_ROOT}/Core/FileStorage/StorageAccessor.cpp
      )
  endif()
endif()


##
## PNG support: libpng (in conjunction with zlib)
##

if (ENABLE_PNG)
  if (NOT ENABLE_ZLIB)
    message(FATAL_ERROR "Support for zlib must be enabled if enabling libpng support")
  endif()

  if (NOT ENABLE_MODULE_IMAGES)
    message(FATAL_ERROR "Image processing primitives must be enabled if enabling libpng support")
  endif()
  
  include(${CMAKE_CURRENT_LIST_DIR}/LibPngConfiguration.cmake)
  add_definitions(-DORTHANC_ENABLE_PNG=1)

  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/Images/PngReader.cpp
    ${ORTHANC_ROOT}/Core/Images/PngWriter.cpp
    )
endif()


##
## Lua support
##

if (ENABLE_LUA)
  include(${CMAKE_CURRENT_LIST_DIR}/LuaConfiguration.cmake)
  add_definitions(-DORTHANC_ENABLE_LUA=1)

  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/Lua/LuaContext.cpp
    ${ORTHANC_ROOT}/Core/Lua/LuaFunctionCall.cpp
    )
endif()


##
## XML support: pugixml
##

if (ENABLE_PUGIXML)
  include(${CMAKE_CURRENT_LIST_DIR}/PugixmlConfiguration.cmake)
  add_definitions(-DORTHANC_ENABLE_PUGIXML=1)
endif()


##
## Locale support: libiconv
##

if (ENABLE_LOCALE)
  if (CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
    # In WebAssembly or asm.js, we rely on the version of iconv that
    # is shipped with the stdlib
    unset(USE_BOOST_ICONV CACHE)
  else()
    include(${CMAKE_CURRENT_LIST_DIR}/LibIconvConfiguration.cmake)
  endif()
  
  add_definitions(-DORTHANC_ENABLE_LOCALE=1)
endif()


##
## Google Test for unit testing
##

if (ENABLE_GOOGLE_TEST)
  include(${CMAKE_CURRENT_LIST_DIR}/GoogleTestConfiguration.cmake)
endif()



#####################################################################
## Inclusion of mandatory third-party dependencies
#####################################################################

include(${CMAKE_CURRENT_LIST_DIR}/JsonCppConfiguration.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/UuidConfiguration.cmake)

# We put Boost as the last dependency, as it is the heaviest to
# configure, which allows to quickly spot problems when configuring
# static builds in other dependencies
include(${CMAKE_CURRENT_LIST_DIR}/BoostConfiguration.cmake)


#####################################################################
## Optional configuration of DCMTK
#####################################################################

if (ENABLE_DCMTK)
  if (NOT ENABLE_LOCALE)
    message(FATAL_ERROR "Support for locales must be enabled if enabling DCMTK support")
  endif()

  if (NOT ENABLE_MODULE_DICOM)
    message(FATAL_ERROR "DICOM module must be enabled if enabling DCMTK support")
  endif()

  include(${CMAKE_CURRENT_LIST_DIR}/DcmtkConfiguration.cmake)

  add_definitions(-DORTHANC_ENABLE_DCMTK=1)

  if (ENABLE_DCMTK_JPEG)
    add_definitions(-DORTHANC_ENABLE_DCMTK_JPEG=1)
  else()
    add_definitions(-DORTHANC_ENABLE_DCMTK_JPEG=0)
  endif()

  if (ENABLE_DCMTK_JPEG_LOSSLESS)
    add_definitions(-DORTHANC_ENABLE_DCMTK_JPEG_LOSSLESS=1)
  else()
    add_definitions(-DORTHANC_ENABLE_DCMTK_JPEG_LOSSLESS=0)
  endif()

  set(ORTHANC_DICOM_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/DicomParsing/DicomModification.cpp
    ${ORTHANC_ROOT}/Core/DicomParsing/FromDcmtkBridge.cpp
    ${ORTHANC_ROOT}/Core/DicomParsing/ParsedDicomFile.cpp
    ${ORTHANC_ROOT}/Core/DicomParsing/ToDcmtkBridge.cpp

    ${ORTHANC_ROOT}/Core/DicomParsing/Internals/DicomFrameIndex.cpp
    ${ORTHANC_ROOT}/Core/DicomParsing/Internals/DicomImageDecoder.cpp
    )

  if (NOT ORTHANC_SANDBOXED)
    list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
      ${ORTHANC_ROOT}/Core/DicomParsing/DicomDirWriter.cpp
      )
  endif()

  if (ENABLE_DCMTK_NETWORKING)
    add_definitions(-DORTHANC_ENABLE_DCMTK_NETWORKING=1)
    list(APPEND ORTHANC_DICOM_SOURCES_INTERNAL
      ${ORTHANC_ROOT}/Core/DicomNetworking/DicomFindAnswers.cpp
      ${ORTHANC_ROOT}/Core/DicomNetworking/DicomServer.cpp
      ${ORTHANC_ROOT}/Core/DicomNetworking/DicomUserConnection.cpp
      ${ORTHANC_ROOT}/Core/DicomNetworking/Internals/CommandDispatcher.cpp
      ${ORTHANC_ROOT}/Core/DicomNetworking/Internals/FindScp.cpp
      ${ORTHANC_ROOT}/Core/DicomNetworking/Internals/MoveScp.cpp
      ${ORTHANC_ROOT}/Core/DicomNetworking/Internals/StoreScp.cpp
      ${ORTHANC_ROOT}/Core/DicomNetworking/RemoteModalityParameters.cpp
      ${ORTHANC_ROOT}/Core/DicomNetworking/TimeoutDicomConnectionManager.cpp
      )
  else()
    add_definitions(-DORTHANC_ENABLE_DCMTK_NETWORKING=0)
  endif()

  if (STANDALONE_BUILD AND NOT HAS_EMBEDDED_RESOURCES)
    EmbedResources(
      ${DCMTK_DICTIONARIES}
      )
    list(APPEND ORTHANC_DICOM_SOURCES_DEPENDENCIES
      ${AUTOGENERATED_SOURCES}
      )
  endif()
endif()


#####################################################################
## Configuration of the C/C++ macros
#####################################################################

add_definitions(
  -DORTHANC_API_VERSION="${ORTHANC_API_VERSION}"
  -DORTHANC_DATABASE_VERSION=${ORTHANC_DATABASE_VERSION}
  -DORTHANC_DEFAULT_DICOM_ENCODING=Encoding_Latin1
  -DORTHANC_ENABLE_BASE64=1
  -DORTHANC_ENABLE_MD5=1
  -DORTHANC_MAXIMUM_TAG_LENGTH=256
  -DORTHANC_VERSION="${ORTHANC_VERSION}"
  )


if (ORTHANC_SANDBOXED)
  add_definitions(
    -DORTHANC_SANDBOXED=1
    -DORTHANC_ENABLE_LOGGING_PLUGIN=0
    )

  if (CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
    add_definitions(
      -DORTHANC_ENABLE_LOGGING=1
      -DORTHANC_ENABLE_LOGGING_STDIO=1
      )
  else()
    add_definitions(
      -DORTHANC_ENABLE_LOGGING=0
      )
  endif()
  
else()
  add_definitions(
    -DORTHANC_ENABLE_LOGGING=1
    -DORTHANC_ENABLE_LOGGING_STDIO=0
    -DORTHANC_SANDBOXED=0
    )

  list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
    ${ORTHANC_ROOT}/Core/Cache/SharedArchive.cpp
    ${ORTHANC_ROOT}/Core/FileStorage/FilesystemStorage.cpp
    ${ORTHANC_ROOT}/Core/MultiThreading/RunnableWorkersPool.cpp
    ${ORTHANC_ROOT}/Core/MultiThreading/Semaphore.cpp
    ${ORTHANC_ROOT}/Core/MultiThreading/SharedMessageQueue.cpp
    ${ORTHANC_ROOT}/Core/SharedLibrary.cpp
    ${ORTHANC_ROOT}/Core/SystemToolbox.cpp
    ${ORTHANC_ROOT}/Core/TemporaryFile.cpp
    )

  if (ENABLE_MODULE_JOBS)
    list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
      ${ORTHANC_ROOT}/Core/JobsEngine/JobsEngine.cpp
      ${ORTHANC_ROOT}/Core/JobsEngine/JobsRegistry.cpp
      )
  endif()
endif()


if (HAS_EMBEDDED_RESOURCES)
  add_definitions(-DORTHANC_HAS_EMBEDDED_RESOURCES=1)

  if (ENABLE_WEB_SERVER)
    list(APPEND ORTHANC_CORE_SOURCES_INTERNAL
      ${ORTHANC_ROOT}/Core/HttpServer/EmbeddedResourceHttpHandler.cpp
      )
  endif()
else()
  add_definitions(-DORTHANC_HAS_EMBEDDED_RESOURCES=0)
endif()


#####################################################################
## Gathering of all the source code
#####################################################################

# The "xxx_INTERNAL" variables list the source code that belongs to
# the Orthanc project. It can be used to configure precompiled headers
# if using Microsoft Visual Studio.

# The "xxx_DEPENDENCIES" variables list the source code coming from
# third-party dependencies.


set(ORTHANC_CORE_SOURCES_DEPENDENCIES
  ${BOOST_SOURCES}
  ${CIVETWEB_SOURCES}
  ${CURL_SOURCES}
  ${JSONCPP_SOURCES}
  ${LIBICONV_SOURCES}
  ${LIBJPEG_SOURCES}
  ${LIBP11_SOURCES}
  ${LIBPNG_SOURCES}
  ${LUA_SOURCES}
  ${MONGOOSE_SOURCES}
  ${OPENSSL_SOURCES}
  ${PUGIXML_SOURCES}
  ${SQLITE_SOURCES}
  ${UUID_SOURCES}
  ${ZLIB_SOURCES}

  ${ORTHANC_ROOT}/Resources/ThirdParty/md5/md5.c
  ${ORTHANC_ROOT}/Resources/ThirdParty/base64/base64.cpp
  )

if (ENABLE_ZLIB AND NOT ORTHANC_SANDBOXED)
  list(APPEND ORTHANC_CORE_SOURCES_DEPENDENCIES
    # This is the minizip distribution to create ZIP files using zlib
    ${ORTHANC_ROOT}/Resources/ThirdParty/minizip/ioapi.c
    ${ORTHANC_ROOT}/Resources/ThirdParty/minizip/zip.c
    )
endif()


set(ORTHANC_CORE_SOURCES
  ${ORTHANC_CORE_SOURCES_INTERNAL}
  ${ORTHANC_CORE_SOURCES_DEPENDENCIES}
  )

if (ENABLE_DCMTK)
  list(APPEND ORTHANC_DICOM_SOURCES_DEPENDENCIES
    ${DCMTK_SOURCES}
    )
  
  set(ORTHANC_DICOM_SOURCES
    ${ORTHANC_DICOM_SOURCES_INTERNAL}
    ${ORTHANC_DICOM_SOURCES_DEPENDENCIES}
    )
endif()
