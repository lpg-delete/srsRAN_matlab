%listSRSblocks Provide a list of all tested SRS blocks.
%   BLOCKS = listSRSblocks returns a cell array with the names of all SRS blocks
%   with a unit test in the main folder.
%
%   BLOCKS = listSRSblocks('name') is the same as above.
%
%   BLOCKS = listSRSblocks('full') prepends each block name with the block path
%   relative the the SRSRAN root folder.
%
%   BLOCKS = listSRSblocks('path') only returns a list of the paths (relative to
%   the SRSRAN root folder) where the tested blocks are located.

%   Copyright 2021-2023 Software Radio Systems Limited
%
%   This file is part of srsRAN-matlab.
%
%   srsRAN-matlab is free software: you can redistribute it and/or
%   modify it under the terms of the BSD 2-Clause License.
%
%   srsRAN-matlab is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
%   BSD 2-Clause License for more details.
%
%   A copy of the BSD 2-Clause License can be found in the LICENSE
%   file in the top-level directory of this distribution.

function blocks = listSRSblocks(format)
    arguments
        format (1,:) char {mustBeMember(format, {'name', 'path', 'full'})} = 'name'
    end

    blockDetails = {...
        'channel_equalizer', 'phy/upper/equalization/'; ...
        'demodulation_mapper', 'phy/upper/channel_modulation/'; ...
        'dft_processor', 'phy/generic_functions/'; ...
        'dmrs_pbch_processor', 'phy/upper/signal_processors/'; ...
        'dmrs_pdcch_processor', 'phy/upper/signal_processors/'; ...
        'dmrs_pdsch_processor', 'phy/upper/signal_processors/'; ...
        'dmrs_pucch_processor', 'phy/upper/signal_processors/'; ...
        'dmrs_pusch_estimator', 'phy/upper/signal_processors/'; ...
        'ldpc_encoder', 'phy/upper/channel_coding/ldpc/'; ...
        'ldpc_rate_matcher', 'phy/upper/channel_coding/ldpc/'; ...
        'ldpc_segmenter', 'phy/upper/channel_coding/ldpc/'; ...
        'modulation_mapper', 'phy/upper/channel_modulation/'; ...
        'nzp_csi_rs_generator', 'phy/upper/signal_processors/'; ...
        'ofdm_demodulator', 'phy/lower/modulation/'; ...
        'ofdm_modulator', 'phy/lower/modulation/'; ...
        'ofdm_prach_demodulator', 'phy/lower/modulation/'; ...
        'pbch_encoder', 'phy/upper/channel_processors/'; ...
        'pbch_modulator', 'phy/upper/channel_processors/'; ...
        'pdcch_candidates_common', 'ran/pdcch/'; ...
        'pdcch_candidates_ue', 'ran/pdcch/'; ...
        'pdcch_encoder', 'phy/upper/channel_processors/'; ...
        'pdcch_modulator', 'phy/upper/channel_processors/'; ...
        'pdcch_processor', 'phy/upper/channel_processors/'; ...
        'pdsch_encoder', 'phy/upper/channel_processors/'; ...
        'pdsch_modulator', 'phy/upper/channel_processors/'; ...
        'pdsch_processor', 'phy/upper/channel_processors/'; ...
        'port_channel_estimator', 'phy/upper/signal_processors/';...
        'prach_detector', 'phy/upper/channel_processors/'; ...
        'prach_generator', 'phy/upper/channel_processors/'; ...
        'pucch_demodulator_format2', 'phy/upper/channel_processors/'; ...
        'pucch_detector', 'phy/upper/channel_processors/'; ...
        'pucch_processor_format1', 'phy/upper/channel_processors/'; ...
        'pucch_processor_format2', 'phy/upper/channel_processors/'; ...
        'pusch_decoder', 'phy/upper/channel_processors/'; ...
        'pusch_demodulator', 'phy/upper/channel_processors/'; ...
        'pusch_processor', 'phy/upper/channel_processors/'; ...
        'short_block_detector', 'phy/upper/channel_coding/short/'; ...
        'short_block_encoder', 'phy/upper/channel_coding/short/'; ...
        'ssb_processor', 'phy/upper/channel_processors/'; ...
        'tbs_calculator', 'scheduler/support/'; ...
        'uci_decoder', 'phy/upper/channel_processors/'; ...
        'ulsch_demultiplex', 'phy/upper/channel_processors/'; ...
        'ulsch_info', 'ran/pusch/'; ...
        };

    switch format
        case 'name'
            blocks = blockDetails(:, 1).';
        case 'path'
            blocks = unique(blockDetails(:, 2).');
        case 'full'
            blocks = strcat(blockDetails(:, 2), blockDetails(:, 1)).';
    end
end
