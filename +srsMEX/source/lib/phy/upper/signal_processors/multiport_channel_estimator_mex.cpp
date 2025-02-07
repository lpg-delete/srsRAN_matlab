/*
 *
 * Copyright 2021-2023 Software Radio Systems Limited
 *
 * This file is part of srsRAN-matlab.
 *
 * srsRAN-matlab is free software: you can redistribute it and/or
 * modify it under the terms of the BSD 2-Clause License.
 *
 * srsRAN-matlab is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * BSD 2-Clause License for more details.
 *
 * A copy of the BSD 2-Clause License can be found in the LICENSE
 * file in the top-level directory of this distribution.
 *
 */

/// \file
/// \brief Multiport channel estimator MEX definition.

#include "multiport_channel_estimator_mex.h"
#include "srsran_matlab/support/factory_functions.h"
#include "srsran_matlab/support/matlab_to_srs.h"
#include "srsran_matlab/support/to_span.h"
#include "srsran/phy/support/resource_grid_writer.h"
#include <memory>
#include <numeric>

using namespace matlab::data;
using namespace srsran;
using namespace srsran_matlab;

void MexFunction::check_step_outputs_inputs(ArgumentList outputs, ArgumentList inputs)
{
  constexpr unsigned NOF_INPUTS = 5;
  if (inputs.size() != NOF_INPUTS) {
    mex_abort("Wrong number of inputs: expected {}, provided {}.", NOF_INPUTS, inputs.size());
  }

  if ((inputs[1].getType() != ArrayType::COMPLEX_SINGLE) || (inputs[1].getDimensions().size() < 2) ||
      (inputs[1].getDimensions().size() > 3)) {
    mex_abort("Input 'rxGrid' should be a 2- or 3-dimensional array of complex floats.");
  }

  if ((inputs[2].getType() != ArrayType::DOUBLE) || (inputs[2].getNumberOfElements() != 2)) {
    mex_abort("Input 'symbolAllocation' should contain two elements only.");
  }

  if ((inputs[3].getType() != ArrayType::COMPLEX_SINGLE) ||
      (inputs[3].getDimensions()[0] != inputs[3].getNumberOfElements())) {
    mex_abort("Input 'refSym' should be a column array of complex float symbols.");
  }

  if ((inputs[4].getType() != ArrayType::STRUCT) || (inputs[4].getNumberOfElements() > 1)) {
    mex_abort("Input 'config' should be a scalar structure.");
  }

  constexpr unsigned NOF_OUTPUTS = 2;
  if (outputs.size() != NOF_OUTPUTS) {
    mex_abort("Wrong number of outputs: expected {}, provided {}.", NOF_OUTPUTS, outputs.size());
  }
}

void MexFunction::method_step(ArgumentList outputs, ArgumentList inputs)
{
  check_step_outputs_inputs(outputs, inputs);

  StructArray  in_cfg_array = inputs[4];
  const Struct in_cfg       = in_cfg_array[0];

  port_channel_estimator::configuration cfg   = {};
  const CharArray                       in_cp = in_cfg["CyclicPrefix"];
  cfg.cp                                      = matlab_to_srs_cyclic_prefix(in_cp.toAscii());

  cfg.scs = matlab_to_srs_subcarrier_spacing(static_cast<unsigned>(in_cfg["SubcarrierSpacing"][0]));

  const TypedArray<double> in_allocation = inputs[2];
  cfg.first_symbol                       = static_cast<unsigned>(in_allocation[0]);
  cfg.nof_symbols                        = static_cast<unsigned>(in_allocation[1]);

  // For now, one Tx layer only.
  cfg.dmrs_pattern.resize(1);
  port_channel_estimator::layer_dmrs_pattern& dmrs_pattern = cfg.dmrs_pattern[0];

  const TypedArray<bool> in_symbols = in_cfg["Symbols"];
  dmrs_pattern.symbols              = bounded_bitset<MAX_NSYMB_PER_SLOT>(in_symbols.cbegin(), in_symbols.cend());

  const TypedArray<bool> in_rb_mask = in_cfg["RBMask"];
  dmrs_pattern.rb_mask              = bounded_bitset<MAX_RB>(in_rb_mask.cbegin(), in_rb_mask.cend());

  const TypedArray<double> in_hop = in_cfg["HoppingIndex"];
  if (!in_hop.isEmpty()) {
    dmrs_pattern.hopping_symbol_index = static_cast<unsigned>(in_hop[0]);

    const TypedArray<bool> in_rb_mask2 = in_cfg["RBMask2"];
    dmrs_pattern.rb_mask2              = bounded_bitset<MAX_RB>(in_rb_mask2.cbegin(), in_rb_mask2.cend());
  }

  const TypedArray<bool> in_re_pattern = in_cfg["REPattern"];
  dmrs_pattern.re_pattern              = bounded_bitset<NRE>(in_re_pattern.cbegin(), in_re_pattern.cend());

  cfg.scaling = static_cast<float>(in_cfg["BetaScaling"][0]);

  const TypedArray<cf_t> in_grid         = inputs[1];
  const ArrayDimensions  grid_dims       = in_grid.getDimensions();
  unsigned               nof_subcarriers = grid_dims[0];
  unsigned               nof_symbols     = grid_dims[1];
  unsigned               nof_rx_ports    = 1;
  if (grid_dims.size() == 3) {
    nof_rx_ports = grid_dims[2];
  }

  std::unique_ptr<resource_grid> grid = create_resource_grid(nof_subcarriers, nof_symbols, nof_rx_ports);
  if (!grid) {
    mex_abort("Cannot create resource grid.");
  }

  const TypedArray<double> in_port_indices  = in_cfg["PortIndices"];
  unsigned                 nof_port_indices = in_port_indices.getNumberOfElements();
  if (nof_port_indices != nof_rx_ports) {
    mex_abort("PortIndices and number of resource grid ports do not match: {} vs. {}.", nof_port_indices, nof_rx_ports);
  }
  cfg.rx_ports.resize(nof_rx_ports);
  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    cfg.rx_ports[i_port] = static_cast<unsigned>(in_port_indices[i_port]);
  }

  span<const cf_t> grid_view = to_span(in_grid);

  unsigned remaining_res = in_grid.getNumberOfElements();
  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    for (unsigned i_symbol = 0; i_symbol != nof_symbols; ++i_symbol) {
      span<const cf_t> symbol_view = grid_view.first(nof_subcarriers);
      remaining_res -= nof_subcarriers;
      grid_view = grid_view.last(remaining_res);

      grid->get_writer().put(i_port, i_symbol, 0, symbol_view);
    }
  }

  const TypedArray<cf_t> in_pilots = inputs[3];

  unsigned nof_pilot_res     = dmrs_pattern.rb_mask.count() * dmrs_pattern.re_pattern.count();
  unsigned nof_pilot_symbols = dmrs_pattern.symbols.count();
  if (in_pilots.getNumberOfElements() != nof_pilot_res * nof_pilot_symbols) {
    mex_abort(
        "Expected {} DM-RS symbols, received {}.", nof_pilot_res * nof_pilot_symbols, in_pilots.getNumberOfElements());
  }
  span<const cf_t> pilot_view = to_span(in_pilots);

  re_measurement_dimensions pilot_dims;
  pilot_dims.nof_subc    = nof_pilot_res;
  pilot_dims.nof_symbols = nof_pilot_symbols;
  pilot_dims.nof_slices  = nof_rx_ports;
  dmrs_symbol_list pilots(pilot_dims);
  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    pilots.set_slice(pilot_view, i_port);
  }

  channel_estimate::channel_estimate_dimensions ch_est_dims;
  ch_est_dims.nof_prb       = dmrs_pattern.rb_mask.size();
  ch_est_dims.nof_symbols   = dmrs_pattern.symbols.size();
  ch_est_dims.nof_rx_ports  = nof_rx_ports;
  ch_est_dims.nof_tx_layers = 1;
  channel_estimate ch_estimate(ch_est_dims);

  TypedArray<cf_t> ch_est_out = factory.createArray<cf_t>(
      {static_cast<size_t>(ch_est_dims.nof_prb * NRE), ch_est_dims.nof_symbols, nof_rx_ports});
  TypedArray<cf_t>::iterator ch_est_out_iter = ch_est_out.begin();
  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    estimator->compute(ch_estimate, grid->get_reader(), i_port, pilots, cfg);

    span<const cf_t> ch_estimate_view = ch_estimate.get_path_ch_estimate(i_port);
    ch_est_out_iter                   = std::copy_n(ch_estimate_view.begin(), ch_estimate_view.size(), ch_est_out_iter);
  }

  StructArray info_out =
      factory.createStructArray({nof_rx_ports + 1, 1}, {"NoiseVar", "RSRP", "EPRE", "SINR", "TimeAlignment"});
  float  total_noise_var      = 0;
  float  total_rsrp           = 0;
  float  total_epre           = 0;
  double total_time_alignment = 0;
  for (unsigned i_port = 0; i_port != nof_rx_ports; ++i_port) {
    info_out[i_port]["NoiseVar"] = factory.createScalar(static_cast<double>(ch_estimate.get_noise_variance(i_port)));
    total_noise_var += ch_estimate.get_noise_variance(i_port);
    info_out[i_port]["RSRP"] = factory.createScalar(static_cast<double>(ch_estimate.get_rsrp(i_port)));
    total_rsrp += ch_estimate.get_rsrp(i_port);
    info_out[i_port]["EPRE"] = factory.createScalar(static_cast<double>(ch_estimate.get_epre(i_port)));
    total_epre += ch_estimate.get_epre(i_port);
    info_out[i_port]["SINR"] = factory.createScalar(static_cast<double>(ch_estimate.get_snr(i_port)));
    info_out[i_port]["TimeAlignment"] =
        factory.createScalar(static_cast<double>(ch_estimate.get_time_alignment(i_port).to_seconds()));
    total_time_alignment += ch_estimate.get_time_alignment(i_port).to_seconds();
  }

  // In the last "info_out" we store the global metrics.
  total_noise_var /= static_cast<float>(nof_rx_ports);
  info_out[nof_rx_ports]["NoiseVar"] = factory.createScalar(static_cast<double>(total_noise_var));
  info_out[nof_rx_ports]["RSRP"]     = factory.createScalar(static_cast<double>(total_rsrp / nof_rx_ports));
  info_out[nof_rx_ports]["EPRE"]     = factory.createScalar(static_cast<double>(total_epre / nof_rx_ports));
  // A global SINR doesn't make much sense, we need to know how the ports are combined.
  info_out[nof_rx_ports]["SINR"]          = factory.createScalar(std::numeric_limits<double>::quiet_NaN());
  info_out[nof_rx_ports]["TimeAlignment"] = factory.createScalar(total_time_alignment / nof_rx_ports);

  outputs[0] = ch_est_out;
  outputs[1] = info_out;
}
