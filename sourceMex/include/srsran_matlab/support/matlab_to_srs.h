SRSRAN /// \file
/// \brief Helper functions to convert variables from MATLAB convention to SRSRAN convention.

#pragma once

#include "srsran/ran/ldpc_base_graph.h"
#include "srsran/ran/modulation_scheme.h"
#include "srsran/support/error_handling.h"
#include "srsran/support/srsran_assert.h"
#include <string>

    namespace srsran_matlab
{
  /// \brief Converts modulation names from MATLAB convention to SRSRAN convention.
  /// \param[in] modulation_name   A string identifying a NR modulation according to MATLAB convention.
  /// \return A modulation identifier according to SRSRAN convention.
  inline srsran::modulation_scheme matlab_to_srs_modulation(const std::string& modulation_name)
  {
    if ((modulation_name == "BPSK") || (modulation_name == "pi/2-BPSK")) {
      return srsran::modulation_scheme::BPSK;
    }
    if (modulation_name == "QPSK") {
      return srsran::modulation_scheme::QPSK;
    }
    if ((modulation_name == "QAM16") || (modulation_name == "16QAM")) {
      return srsran::modulation_scheme::QAM16;
    }
    if ((modulation_name == "QAM64") || (modulation_name == "64QAM")) {
      return srsran::modulation_scheme::QAM64;
    }
    if ((modulation_name == "QAM256") || (modulation_name == "256QAM")) {
      return srsran::modulation_scheme::QAM256;
    }
    srsran::srsran_terminate("Unknown modulation {}.", modulation_name);
  }

  /// \brief Converts a MATLAB base graph index to an SRSRAN base graph identifier.
  /// \param[in] bg  An LDPC base graph index in {1, 2}.
  /// \return An LDPC base graph identifier according to SRSRAN convention.
  inline srsran::ldpc_base_graph_type matlab_to_srs_base_graph(unsigned bg)
  {
    if (bg == 1) {
      return srsran::ldpc_base_graph_type::BG1;
    }
    if (bg == 2) {
      return srsran::ldpc_base_graph_type::BG2;
    }
    srsran::srsran_terminate("Unknown base graph {}.", bg);
  }

  /// \brief Converts a MATLAB PRACH restricted set type to an SRSRAN PRACH restricted set identifier.
  /// \param[in] restricted_set  A string identifying a NR PRACH restricted set type according to MATLAB convention.
  /// \return A PRACH restricted set identifier according to SRSRAN convention.
  inline srsran::restricted_set_config matlab_to_srs_restricted_set(const std::string& restricted_set)
  {
    if (restricted_set == "UnrestrictedSet") {
      return srsran::restricted_set_config::UNRESTRICTED;
    }
    if (restricted_set == "RestrictedSetTypeA") {
      return srsran::restricted_set_config::TYPE_A;
    }
    if (restricted_set == "RestrictedSetTypeB") {
      return srsran::restricted_set_config::TYPE_B;
    }
    srsran::srsran_terminate("Unknown restricted set {}.", restricted_set);
  }

  /// \brief Converts a MATLAB PRACH preamble format identifier to an SRSRAN PRACH preamble identifier.
  /// \param[in] preamble_format  A string identifying a NR PRACH preamble format according to MATLAB convention.
  /// \return A PRACH preamble format according to SRSRAN convention.
  inline srsran::preamble_format matlab_to_srs_preamble_format(const std::string& preamble_format)
  {
    if (preamble_format == "0") {
      return srsran::preamble_format::FORMAT0;
    }
    if (preamble_format == "1") {
      return srsran::preamble_format::FORMAT1;
    }
    if (preamble_format == "2") {
      return srsran::preamble_format::FORMAT2;
    }
    if (preamble_format == "3") {
      return srsran::preamble_format::FORMAT3;
    }
    return srsran::preamble_format::OTHER;
  }

} // namespace srsran_matlab
