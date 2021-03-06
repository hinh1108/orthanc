/**
 * Orthanc - A Lightweight, RESTful DICOM Store
 * Copyright (C) 2012-2016 Sebastien Jodogne, Medical Physics
 * Department, University Hospital of Liege, Belgium
 * Copyright (C) 2017-2018 Osimis S.A., Belgium
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * In addition, as a special exception, the copyright holders of this
 * program give permission to link the code of its release with the
 * OpenSSL project's "OpenSSL" library (or with modified versions of it
 * that use the same license as the "OpenSSL" library), and distribute
 * the linked executables. You must obey the GNU General Public License
 * in all respects for all of the code used other than "OpenSSL". If you
 * modify file(s) with this exception, you may extend this exception to
 * your version of the file(s), but you are not obligated to do so. If
 * you do not wish to do so, delete this exception statement from your
 * version. If you delete this exception statement from all source files
 * in the program, then also delete it here.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 **/


#pragma once

#include "../Enumerations.h"

#include <stdint.h>
#include <boost/noncopyable.hpp>
#include <json/value.h>

#if !defined(ORTHANC_ENABLE_BASE64)
#  error The macro ORTHANC_ENABLE_BASE64 must be defined
#endif


namespace Orthanc
{
  class DicomValue : public boost::noncopyable
  {
  private:
    enum Type
    {
      Type_Null,
      Type_String,
      Type_Binary
    };

    Type         type_;
    std::string  content_;

    DicomValue(const DicomValue& other);

  public:
    DicomValue() : type_(Type_Null)
    {
    }
    
    DicomValue(const std::string& content,
               bool isBinary);
    
    DicomValue(const char* data,
               size_t size,
               bool isBinary);
    
    const std::string& GetContent() const;

    bool IsNull() const
    {
      return type_ == Type_Null;
    }

    bool IsBinary() const
    {
      return type_ == Type_Binary;
    }
    
    DicomValue* Clone() const;

#if ORTHANC_ENABLE_BASE64 == 1
    void FormatDataUriScheme(std::string& target,
                             const std::string& mime) const;

    void FormatDataUriScheme(std::string& target) const
    {
      FormatDataUriScheme(target, MIME_BINARY);
    }
#endif

    bool CopyToString(std::string& result,
                      bool allowBinary) const;
    
    bool ParseInteger32(int32_t& result) const;

    bool ParseInteger64(int64_t& result) const;                                

    bool ParseUnsignedInteger32(uint32_t& result) const;

    bool ParseUnsignedInteger64(uint64_t& result) const;                                

    bool ParseFloat(float& result) const;                                

    bool ParseDouble(double& result) const;

    void Serialize(Json::Value& target) const;

    void Unserialize(const Json::Value& source);
  };
}
