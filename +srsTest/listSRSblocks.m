%listSRSblocks Provide a list of all tested SRS blocks.
%   BLOCKS = listSRSblocks returns a cell array with the names of all SRS blocks
%   with a unit test in the main folder.
%
%   BLOCKS = listSRSblocks('name') is the same as above.
%
%   BLOCKS = listSRSblocks('full') prepends each block name with the block path
%   relative the the SRSGNB root folder.
%
%   BLOCKS = listSRSblocks('path') only returns a list of the paths (relative to
%   the SRSGNB root folder) where the tested blocks are located.
%
function blocks = listSRSblocks(format)
    arguments
        format (1,:) char {mustBeMember(format, {'name', 'path', 'full'})} = 'name'
    end

    blockDetails = {...
        'channel_equalizer', 'phy/upper/equalization/'; ...
        'csi_rs_processor', 'phy/upper/signal_processors/'; ...
        'demodulation_mapper', 'phy/upper/channel_modulation/'; ...
        'dl_processor', 'phy/upper/'; ...
        'dmrs_pbch_processor', 'phy/upper/signal_processors/'; ...
        'dmrs_pdcch_processor', 'phy/upper/signal_processors/'; ...
        'dmrs_pdsch_processor', 'phy/upper/signal_processors/'; ...
        'dmrs_pucch_processor', 'phy/upper/signal_processors/'; ...
        'dmrs_pusch_estimator', 'phy/upper/signal_processors/'; ...
        'ldpc_encoder', 'phy/upper/channel_coding/ldpc/'; ...
        'ldpc_rate_matcher', 'phy/upper/channel_coding/ldpc/'; ...
        'ldpc_segmenter', 'phy/upper/channel_coding/ldpc/'; ...
        'modulation_mapper', 'phy/upper/channel_modulation/'; ...
        'ofdm_demodulator', 'phy/lower/modulation/'; ...
        'ofdm_modulator', 'phy/lower/modulation/'; ...
        'ofdm_prach_demodulator', 'phy/lower/modulation/'; ...
        'pbch_encoder', 'phy/upper/channel_processors/'; ...
        'pbch_modulator', 'phy/upper/channel_processors/'; ...
        'pdcch_candidates_common', 'ran/pdcch/'; ...
        'pdcch_encoder', 'phy/upper/channel_processors/'; ...
        'pdcch_modulator', 'phy/upper/channel_processors/'; ...
        'pdsch_encoder', 'phy/upper/channel_processors/'; ...
        'pdsch_modulator', 'phy/upper/channel_processors/'; ...
        'prach_generator', 'phy/upper/channel_processors/'; ...
        'pusch_decoder', 'phy/upper/channel_processors/'; ...
        'short_block_detector', 'phy/upper/channel_coding/short/'; ...
        'short_block_encoder', 'phy/upper/channel_coding/short/'; ...
        'ssb_processor', 'phy/upper/channel_processors/'; ...
        'tbs_calculator', 'scheduler/support/'; ...
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
