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


#include "../PrecompiledHeadersServer.h"
#include "DatabaseLookup.h"

#include "../ServerToolbox.h"
#include "../../Core/DicomParsing/FromDcmtkBridge.h"

namespace Orthanc
{
  void DatabaseLookup::LoadTags(ResourceType level)
  {
    const DicomTag* tags = NULL;
    size_t size;
    
    ServerToolbox::LoadIdentifiers(tags, size, level);
    
    for (size_t i = 0; i < size; i++)
    {
      if (tags_.find(tags[i]) == tags_.end())
      {
        tags_[tags[i]] = TagInfo(DicomTagType_Identifier, level);
      }
      else
      {
        // These patient-level tags are copied in the study level
        assert(level == ResourceType_Study &&
               (tags[i] == DICOM_TAG_PATIENT_ID ||
                tags[i] == DICOM_TAG_PATIENT_NAME ||
                tags[i] == DICOM_TAG_PATIENT_BIRTH_DATE));
      }
    }
    
    DicomMap::LoadMainDicomTags(tags, size, level);
    
    for (size_t i = 0; i < size; i++)
    {
      if (tags_.find(tags[i]) == tags_.end())
      {
        tags_[tags[i]] = TagInfo(DicomTagType_Main, level);
      }
    }
  }


  DatabaseLookup::DatabaseLookup()
  {
    LoadTags(ResourceType_Patient);
    LoadTags(ResourceType_Study);
    LoadTags(ResourceType_Series);
    LoadTags(ResourceType_Instance);
  }


  DatabaseLookup::~DatabaseLookup()
  {
    for (size_t i = 0; i < constraints_.size(); i++)
    {
      assert(constraints_[i] != NULL);
      delete constraints_[i];
    }
  }


  const DicomTagConstraint& DatabaseLookup::GetConstraint(size_t index) const
  {
    if (index >= constraints_.size())
    {
      throw OrthancException(ErrorCode_ParameterOutOfRange);
    }
    else
    {
      assert(constraints_[index] != NULL);
      return *constraints_[index];
    }
  }


  void DatabaseLookup::AddConstraint(DicomTagConstraint* constraint)
  {
    if (constraint == NULL)
    {
      throw OrthancException(ErrorCode_NullPointer);
    }
    else
    {
      constraints_.push_back(constraint);

      std::map<DicomTag, TagInfo>::const_iterator tag = tags_.find(constraint->GetTag());

      if (tag == tags_.end())
      {
        constraint->SetTagInfo(DicomTagType_Generic, ResourceType_Instance);
      }
      else
      {
        constraint->SetTagInfo(tag->second.GetType(), tag->second.GetLevel());
      }
    }
  }


  bool DatabaseLookup::IsMatch(const DicomMap& value)
  {
    for (size_t i = 0; i < constraints_.size(); i++)
    {
      assert(constraints_[i] != NULL);
      if (!constraints_[i]->IsMatch(value))
      {
        return false;
      }
    }

    return true;
  }


  void DatabaseLookup::AddDicomConstraint(const DicomTag& tag,
                                          const std::string& dicomQuery,
                                          bool caseSensitivePN)
  {
    ValueRepresentation vr = FromDcmtkBridge::LookupValueRepresentation(tag);

    if (vr == ValueRepresentation_Sequence)
    {
      throw OrthancException(ErrorCode_ParameterOutOfRange);
    }

    /**
     * DICOM specifies that searches must always be case sensitive,
     * except for tags with a PN value representation. For PN, Orthanc
     * uses the configuration option "CaseSensitivePN" to decide
     * whether matching is case-sensitive or case-insensitive.
     *
     * Reference: DICOM PS 3.4
     *   - C.2.2.2.1 ("Single Value Matching") 
     *   - C.2.2.2.4 ("Wild Card Matching")
     * http://medical.nema.org/Dicom/2011/11_04pu.pdf
     *
     * "Except for Attributes with a PN Value Representation, only
     * entities with values which match exactly the value specified in the
     * request shall match. This matching is case-sensitive, i.e.,
     * sensitive to the exact encoding of the key attribute value in
     * character sets where a letter may have multiple encodings (e.g.,
     * based on its case, its position in a word, or whether it is
     * accented)
     * 
     * For Attributes with a PN Value Representation (e.g., Patient Name
     * (0010,0010)), an application may perform literal matching that is
     * either case-sensitive, or that is insensitive to some or all
     * aspects of case, position, accent, or other character encoding
     * variants."
     *
     * (0008,0018) UI SOPInstanceUID     => Case-sensitive
     * (0008,0050) SH AccessionNumber    => Case-sensitive
     * (0010,0020) LO PatientID          => Case-sensitive
     * (0020,000D) UI StudyInstanceUID   => Case-sensitive
     * (0020,000E) UI SeriesInstanceUID  => Case-sensitive
     **/
    bool caseSensitive = true;
    if (vr == ValueRepresentation_PersonName)
    {
      caseSensitive = caseSensitivePN;
    }

    if ((vr == ValueRepresentation_Date ||
         vr == ValueRepresentation_DateTime ||
         vr == ValueRepresentation_Time) &&
        dicomQuery.find('-') != std::string::npos)
    {
      /**
       * Range matching is only defined for TM, DA and DT value
       * representations. This code fixes issues 35 and 37.
       *
       * Reference: "Range matching is not defined for types of
       * Attributes other than dates and times", DICOM PS 3.4,
       * C.2.2.2.5 ("Range Matching").
       **/
      size_t separator = dicomQuery.find('-');
      std::string lower = dicomQuery.substr(0, separator);
      std::string upper = dicomQuery.substr(separator + 1);

      if (!lower.empty())
      {
        AddConstraint(new DicomTagConstraint
                      (tag, ConstraintType_GreaterOrEqual, lower, caseSensitive));
      }

      if (!upper.empty())
      {
        AddConstraint(new DicomTagConstraint
                      (tag, ConstraintType_SmallerOrEqual, upper, caseSensitive));
      }
    }
    else if (dicomQuery.find('\\') != std::string::npos)
    {
      DicomTag fixedTag(tag);

      if (tag == DICOM_TAG_MODALITIES_IN_STUDY)
      {
        // http://www.itk.org/Wiki/DICOM_QueryRetrieve_Explained
        // http://dicomiseasy.blogspot.be/2012/01/dicom-queryretrieve-part-i.html  
        fixedTag = DICOM_TAG_MODALITY;
      }

      std::auto_ptr<DicomTagConstraint> constraint
        (new DicomTagConstraint(fixedTag, ConstraintType_List, caseSensitive));

      std::vector<std::string> items;
      Toolbox::TokenizeString(items, dicomQuery, '\\');

      for (size_t i = 0; i < items.size(); i++)
      {
        constraint->AddValue(items[i]);
      }

      AddConstraint(constraint.release());
    }
    else if (dicomQuery.find('*') != std::string::npos ||
             dicomQuery.find('?') != std::string::npos)
    {
      AddConstraint(new DicomTagConstraint
                    (tag, ConstraintType_Wildcard, dicomQuery, caseSensitive));
    }
    else
    {
      AddConstraint(new DicomTagConstraint
                    (tag, ConstraintType_Equal, dicomQuery, caseSensitive));
    }
  }
}
