/**
 * Palantir - A Lightweight, RESTful DICOM Store
 * Copyright (C) 2012 Medical Physics Department, CHU of Liege,
 * Belgium
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 **/


#include "Toolbox.h"

#include "PalantirException.h"

#include <string.h>
#include <boost/filesystem.hpp>
#include <boost/filesystem/fstream.hpp>
#include <algorithm>

#if defined(_WIN32)
#include <windows.h>
#endif

#if defined(__linux)
#include <signal.h>
#include <unistd.h>
#endif

#include "../Resources/md5/md5.h"


namespace Palantir
{
  static bool finish;

#if defined(_WIN32)
  static BOOL WINAPI ConsoleControlHandler(DWORD dwCtrlType)
  {
	// http://msdn.microsoft.com/en-us/library/ms683242(v=vs.85).aspx
	finish = true;
	return true;
  }
#else
  static void SignalHandler(int)
  {
    finish = true;
  }
#endif

  void Toolbox::Sleep(uint32_t seconds)
  {
#if defined(_WIN32)
    ::Sleep(static_cast<DWORD>(seconds) * static_cast<DWORD>(1000));
#elif defined(__linux)
    usleep(static_cast<uint64_t>(seconds) * static_cast<uint64_t>(1000000));
#else
#error Support your platform here
#endif
  }

  void Toolbox::USleep(uint64_t microSeconds)
  {
#if defined(_WIN32)
    ::Sleep(static_cast<DWORD>(microSeconds / static_cast<uint64_t>(1000)));
#elif defined(__linux)
    usleep(microSeconds);
#else
#error Support your platform here
#endif
  }


  void Toolbox::ServerBarrier()
  {
#if defined(_WIN32)
	SetConsoleCtrlHandler(ConsoleControlHandler, true);
#else
    signal(SIGINT, SignalHandler);
    signal(SIGQUIT, SignalHandler);
#endif
  
    finish = false;
    while (!finish)
    {
      USleep(100000);
    }

#if defined(_WIN32)
	SetConsoleCtrlHandler(ConsoleControlHandler, false);
#else
    signal(SIGINT, NULL);
    signal(SIGQUIT, NULL);
#endif
  }



  void Toolbox::ToUpperCase(std::string& s)
  {
    std::transform(s.begin(), s.end(), s.begin(), toupper);
  }


  void Toolbox::ToLowerCase(std::string& s)
  {
    std::transform(s.begin(), s.end(), s.begin(), tolower);
  }



  void Toolbox::ReadFile(std::string& content,
                         const std::string& path) 
  {
    boost::filesystem::ifstream f;
    f.open(path, std::ifstream::in | std::ios::binary);
    if (!f.good())
    {
      throw PalantirException("Unable to open a file");
    }

    // http://www.cplusplus.com/reference/iostream/istream/tellg/
    f.seekg(0, std::ios::end);
    std::streamsize size = f.tellg();
    f.seekg(0, std::ios::beg);

    content.resize(size);
    if (size != 0)
    {
      f.read(reinterpret_cast<char*>(&content[0]), size);
    }

    f.close();
  }


  void Toolbox::RemoveFile(const std::string& path)
  {
    if (boost::filesystem::exists(path))
    {
      if (boost::filesystem::is_regular_file(path))
        boost::filesystem::remove(path);
      else
        throw PalantirException("The path is not a regular file: " + path);
    }
  }



  void Toolbox::SplitUriComponents(UriComponents& components,
                                   const std::string& uri)
  {
    static const char URI_SEPARATOR = '/';

    components.clear();

    if (uri.size() == 0 ||
        uri[0] != URI_SEPARATOR)
    {
      throw PalantirException(ErrorCode_UriSyntax);
    }

    // Count the number of slashes in the URI to make an assumption
    // about the number of components in the URI
    unsigned int estimatedSize = 0;
    for (unsigned int i = 0; i < uri.size(); i++)
    {
      if (uri[i] == URI_SEPARATOR)
        estimatedSize++;
    }

    components.reserve(estimatedSize - 1);

    unsigned int start = 1;
    unsigned int end = 1;
    while (end < uri.size())
    {
      // This is the loop invariant
      assert(uri[start - 1] == '/' && (end >= start));

      if (uri[end] == '/')
      {
        components.push_back(std::string(&uri[start], end - start));
        end++;
        start = end;
      }
      else
      {
        end++;
      }
    }

    if (start < uri.size())
    {
      components.push_back(std::string(&uri[start], end - start));
    }
  }


  bool Toolbox::IsChildUri(const UriComponents& baseUri,
                           const UriComponents& testedUri)
  {
    if (testedUri.size() < baseUri.size())
    {
      return false;
    }

    for (size_t i = 0; i < baseUri.size(); i++)
    {
      if (baseUri[i] != testedUri[i])
        return false;
    }

    return true;
  }


  std::string Toolbox::AutodetectMimeType(const std::string& path)
  {
    std::string contentType;
    size_t lastDot = path.rfind('.');
    size_t lastSlash = path.rfind('/');

    if (lastDot == std::string::npos ||
        (lastSlash != std::string::npos && lastDot < lastSlash))
    {
      // No trailing dot, unable to detect the content type
    }
    else
    {
      const char* extension = &path[lastDot + 1];
    
      // http://en.wikipedia.org/wiki/Mime_types
      // Text types
      if (!strcmp(extension, "txt"))
        contentType = "text/plain";
      else if (!strcmp(extension, "html"))
        contentType = "text/html";
      else if (!strcmp(extension, "xml"))
        contentType = "text/xml";
      else if (!strcmp(extension, "css"))
        contentType = "text/css";

      // Application types
      else if (!strcmp(extension, "js"))
        contentType = "application/javascript";
      else if (!strcmp(extension, "json"))
        contentType = "application/json";
      else if (!strcmp(extension, "pdf"))
        contentType = "application/pdf";

      // Images types
      else if (!strcmp(extension, "jpg") || !strcmp(extension, "jpeg"))
        contentType = "image/jpeg";
      else if (!strcmp(extension, "gif"))
        contentType = "image/gif";
      else if (!strcmp(extension, "png"))
        contentType = "image/png";
    }

    return contentType;
  }


  std::string Toolbox::FlattenUri(const UriComponents& components,
                                  size_t fromLevel)
  {
    if (components.size() <= fromLevel)
    {
      return "/";
    }
    else
    {
      std::string r;

      for (size_t i = fromLevel; i < components.size(); i++)
      {
        r += "/" + components[i];
      }

      return r;
    }
  }



  uint64_t Toolbox::GetFileSize(const std::string& path)
  {
    try
    {
      return static_cast<uint64_t>(boost::filesystem::file_size(path));
    }
    catch (boost::filesystem::filesystem_error)
    {
      throw PalantirException(ErrorCode_InexistentFile);
    }
  }



  static char GetHexadecimalCharacter(uint8_t value)
  {
    assert(value < 16);

    if (value < 10)
      return value + '0';
    else
      return (value - 10) + 'a';
  }

  void Toolbox::ComputeMD5(std::string& result,
                           const std::string& data)
  {
    md5_state_s state;
    md5_init(&state);

    if (data.size() > 0)
    {
      md5_append(&state, reinterpret_cast<const md5_byte_t*>(&data[0]), 
                 static_cast<int>(data.size()));
    }

    md5_byte_t actualHash[16];
    md5_finish(&state, actualHash);

    result.resize(32);
    for (unsigned int i = 0; i < 16; i++)
    {
      result[2 * i] = GetHexadecimalCharacter(actualHash[i] / 16);
      result[2 * i + 1] = GetHexadecimalCharacter(actualHash[i] % 16);
    }

  }
}
