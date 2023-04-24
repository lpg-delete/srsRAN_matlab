/// \file
/// \brief PUSCH demodulator MEX declaration.

#pragma once

#include "srsran_matlab/srsran_mex_dispatcher.h"
#include "srsran/phy/support/support_factories.h"
#include "srsran/phy/upper/channel_processors/channel_processor_factories.h"
#include "srsran/phy/upper/channel_processors/pusch_demodulator.h"
#include "srsran/phy/upper/equalization/equalization_factories.h"

/// \brief Factory method for a PUSCH demodulator.
///
/// Creates and assemblies all the necessary components (equalizer, modulator and PRG) for a fully-functional
/// PUSCH demodulator.
static std::unique_ptr<srsran::pusch_demodulator> create_pusch_demodulator();

/// Implements a PUSCH demodulator following the srsran_mex_dispatcher template.
class MexFunction : public srsran_mex_dispatcher
{
public:
  /// \brief Constructor.
  ///
  /// Stores the string identifier&ndash;method pairs that form the public interface of the PUSCH demodulator MEX
  /// object.
  MexFunction()
  {
    // Ensure srsran PUSCH demodulator was created successfully.
    if (!demodulator) {
      mex_abort("Cannot create srsran PUSCH demodulator.");
    }

    create_callback("step", [this](ArgumentList& out, ArgumentList& in) { return this->method_step(out, in); });
  }

private:
  /// Checks that outputs/inputs arguments match the requirements of method_step().
  void check_step_outputs_inputs(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs);

  /// \brief Demodulates a PUSCH transmission according to the given configuration.
  ///
  /// The method takes six inputs.
  ///   - The string <tt>"step"</tt>.
  ///   - An array of \c cf_t containing the PUSCH resource elements.
  ///   - A matrix of \c unsigned containing the PUSCH resource grid indices.
  ///   - An array of \c cf_t containing the related channel estimates.
  ///   - A one-dimesional structure that describes the PUSCH demodulator configuration. The fields are
  ///      - \c rnti, radio network temporary identifier;
  ///      - \c rbMask, allocation RB list;
  ///      - \c modulation, modulation scheme used for transmission;
  ///      - \c startSymbolIndex, start symbol index of the time domain allocation within a slot;
  ///      - \c nofSymbols, number of symbols of the time domain allocation within a slot;
  ///      - \c dmrsSymbPos, boolean mask flagging the OFDM symbols containing DMRS;
  ///      - \c dmrsConfigType, DMRS configuration type;
  ///      - \c nofCdmGroupsWithoutData, number of DMRS CDM groups without data;
  ///      - \c nId, scrambling identifier;
  ///      - \c nofTxLayers, number of transmit layers;
  ///      - \c placeholders, ULSCH Scrambling placeholder list;
  ///      - \c rxPorts, receive antenna port indices the PUSCH transmission is mapped to;
  ///   - A \c float providing the noise variance.
  ///
  /// The method has one single output.
  ///   - An array of \c log_likelihood_ratio resulting from the PUSCH demodulation.
  void method_step(ArgumentList& outputs, ArgumentList& inputs);

  /// A pointer to the actual PUSCH decoder.
  std::unique_ptr<srsran::pusch_demodulator> demodulator = create_pusch_demodulator();
};

std::unique_ptr<srsran::pusch_demodulator> create_pusch_demodulator()
{
  using namespace srsran;

  std::shared_ptr<channel_equalizer_factory> equalizer_factory = create_channel_equalizer_factory_zf();

  std::shared_ptr<channel_modulation_factory> demod_factory = create_channel_modulation_sw_factory();

  std::shared_ptr<pseudo_random_generator_factory> prg_factory = create_pseudo_random_generator_sw_factory();

  std::shared_ptr<pusch_demodulator_factory> pusch_demod_factory =
      create_pusch_demodulator_factory_sw(equalizer_factory, demod_factory, prg_factory);

  return pusch_demod_factory->create();
}
