%srsPUSCHdmrsUnittest Unit tests for PUSCH DMRS processor functions.
%   This class implements unit tests for the PUSCH DMRS processor functions using the
%   matlab.unittest framework. The simplest use consists in creating an object with
%       testCase = srsPUSCHdmrsUnittest
%   and then running all the tests with
%       testResults = testCase.run
%
%   srsPUSCHdmrsUnittest Properties (Constant):
%
%   srsBlock      - The tested block (i.e., 'dmrs_pusch_estimator').
%   srsBlockType  - The type of the tested block, including layer
%                   (i.e., 'phy/upper/signal_processors').
%
%   srsPUSCHdmrsUnittest Properties (ClassSetupParameter):
%
%   outputPath - Path to the folder where the test results are stored.
%
%   srsPUSCHdmrsUnittest Properties (TestParameter):
%
%   numerology              - Defines the subcarrier spacing (0, 1).
%   NumLayers               - Number of transmission layers (1, 2, 4, 8).
%   DMRSTypeAPosition       - Position of the first DMRS OFDM symbol (2, 3).
%   DMRSAdditionalPosition  - Maximum number of DMRS additional positions (0, 1, 2, 3).
%   DMRSLength              - Number of consecutive front-loaded DMRS OFDM symbols (1, 2).
%   DMRSConfigurationType   - DMRS configuration type (1, 2).
%   testLabel               - Test label ('dmrs_creation' or 'ch_estimation').
%
%   srsPUSCHdmrsUnittest Methods (TestTags = {'testvector'}):
%
%   testvectorGenerationCases - Generates a test vector according to the provided
%                               parameters.
%
%   srsPUSCHdmrsUnittest Methods (Access = protected):
%
%   addTestIncludesToHeaderFile     - Adds include directives to the test header file.
%   addTestDefinitionToHeaderFile   - Adds details (e.g., type/variable declarations)
%                                     to the test header file.
%
%   See also matlab.unittest.

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

classdef srsPUSCHdmrsUnittest < srsTest.srsBlockUnittest
    properties (Constant)
        %Name of the tested block.
        srsBlock = 'dmrs_pusch_estimator'

        %Type of the tested block.
        srsBlockType = 'phy/upper/signal_processors'
    end

    properties (Constant, Hidden)
        norNCellID = 1008
        randomizeTestvector = randperm(srsPUSCHdmrsUnittest.norNCellID);
    end

    properties (ClassSetupParameter)
        %Path to results folder (old 'dmrs_pusch_estimator' tests will be erased).
        outputPath = {['testPUSCHdmrs', char(datetime('now', 'Format', 'yyyyMMdd''T''HHmmss'))]}
    end

    properties (TestParameter)
        %Defines the subcarrier spacing (0, 1).
        numerology = {0, 1}

        %Number of transmission layers (1, 2, 4).
        NumLayers = {1, 2, 4}

        %Position of the first DMRS OFDM symbol (2, 3).
        DMRSTypeAPosition = {2, 3}

        %Maximum number of DMRS additional positions (0, 1, 2, 3).
        DMRSAdditionalPosition = {0, 1, 2, 3}

        %Number of consecutive front-loaded DMRS OFDM symbols (1, 2).
        DMRSLength = {1, 2}

        %DMRS configuration type (1, 2).
        DMRSConfigurationType = {1, 2}

        %Test label ('dmrs_creation' or 'ch_estimation').
        %   'dmrs_creation' tests only check that the DM-RS pilots are generated correctly
        %   and placed in the correct location in the resource grid.
        %   'ch_estimation' also check that the channel is estimated correctly.
        testLabel = {'dmrs_creation', 'ch_estimation'}
    end

    methods (Access = protected)
        function addTestIncludesToHeaderFile(~, fileID)
        %addTestIncludesToHeaderFile Adds include directives to the test header file.


            fprintf(fileID, '#include "../../support/resource_grid_test_doubles.h"\n');
            fprintf(fileID, '#include "srsran/phy/upper/signal_processors/dmrs_pusch_estimator.h"\n');
            fprintf(fileID, '#include "srsran/support/file_vector.h"\n');
        end

        function addTestDefinitionToHeaderFile(~, fileID)
        %addTestDetailsToHeaderFile Adds details (e.g., type/variable declarations) to the test header file.
            fprintf(fileID, 'enum class test_label {dmrs_creation, ch_estimation};\n\n');
            fprintf(fileID, 'struct test_case_t {\n');
            fprintf(fileID, '  test_label                                              label;\n');
            fprintf(fileID, '  dmrs_pusch_estimator::configuration                     config;\n');
            fprintf(fileID, '  float                                                   est_noise_var;\n');
            fprintf(fileID, '  float                                                   est_rsrp;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> rx_symbols;\n');
            fprintf(fileID, '  file_vector<resource_grid_reader_spy::expected_entry_t> ch_estimates;\n');
            fprintf(fileID, '};\n');
        end
    end % of methods (Access = protected)

    methods (Test, TestTags = {'testvector'})
        function testvectorGenerationCases(testCase, numerology, NumLayers, ...
                DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, ...
                DMRSConfigurationType, testLabel)
        %testvectorGenerationCases Generates a test vector for the given numerology,
        %   NumLayers, DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength,
        %   DMRSConfigurationType and testLabel. NCellID, NSlot and PRB are randomly generated.

            import srsTest.helpers.cellarray2str
            import srsLib.phy.helpers.srsConfigureCarrier
            import srsLib.phy.helpers.srsConfigurePUSCHdmrs
            import srsLib.phy.helpers.srsConfigurePUSCH
            import srsLib.phy.upper.signal_processors.srsPUSCHdmrs
            import srsLib.phy.upper.signal_processors.srsChannelEstimator
            import srsTest.helpers.writeResourceGridEntryFile
            import srsTest.helpers.symbolAllocationMask2string
            import srsTest.helpers.RBallocationMask2string

            % Skip those invalid configuration cases.
            isDMRSLengthOK = (DMRSLength == 1 || DMRSAdditionalPosition < 2);
            isChEstimationOK = strcmp(testLabel, 'dmrs_creation') || (NumLayers == 1);
            if ~(isDMRSLengthOK && isChEstimationOK)
                return;
            end

            % Generate a unique test ID.
            testID = testCase.generateTestID;

            % Use a unique NCellID, NSlot, scrambling ID and PRB allocation for each test.
            NCellID = testCase.randomizeTestvector(testID + 1) - 1;
            if numerology == 0
                NSlot = randi([0, 9]);
            else
                NSlot = randi([0, 19]);
            end
            NSCID = randi([0, 1]);
            PRBstart = randi([0, 136]);
            PRBend = randi([136, 271]);

            % Current fixed parameter values (e.g., number of CDM groups without data).
            NSizeGrid = 272;
            NStartGrid = 0;
            NFrame = 0;
            CyclicPrefix = 'normal';
            RNTI = 0;
            NStartBWP = 0;
            NSizeBWP = NSizeGrid;
            NIDNSCID = NCellID;
            NID = NCellID;
            Modulation = '16QAM';
            MappingType = 'A';
            SymbolAllocation = [1 13];
            PRBSet = PRBstart:PRBend;
            amplitude = sqrt(2);
            PUSCHports = 0:(NumLayers-1);

            % Configure the carrier according to the test parameters.
            SubcarrierSpacing = 15 * (2 .^ numerology);
            carrier = srsConfigureCarrier(NCellID, SubcarrierSpacing, ...
                NSizeGrid, NStartGrid, NSlot, NFrame, CyclicPrefix);

            % Configure the PUSCH DM-RS symbols according to the test parameters.
            DMRS = srsConfigurePUSCHdmrs(DMRSConfigurationType, ...
                DMRSTypeAPosition, DMRSAdditionalPosition, DMRSLength, ...
                NIDNSCID, NSCID);

            % Configure the PUSCH according to the test parameters.
            pusch = srsConfigurePUSCH(DMRS, NStartBWP, NSizeBWP, NID, RNTI, ...
                Modulation, NumLayers, MappingType, SymbolAllocation, PRBSet);

            % Call the PUSCH DM-RS symbol processor MATLAB functions.
            [DMRSsymbols, symbolIndices] = srsPUSCHdmrs(carrier, pusch);

            % If 'dmrs-creation' test, write each complex symbol and their
            % associated indices into a binary file, and an empty channel
            % coefficients file.
            if strcmp(testLabel, 'dmrs_creation')
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, DMRSsymbols * amplitude, symbolIndices);
                testCase.saveDataFile('_ch_estimates', testID, ...
                    @writeResourceGridEntryFile, [], uint32.empty(0,3));
                estRSRP = 0;
                estNoiseVar = 0;
            else
                % Ensure we are transmitting on a single layer.
                assert(all(symbolIndices(:, 3) == 0), 'srsran_matlab:srsPUSCHdmrsUnittest', ...
                    'Multi-layer channel estimation not enabled yet.');
                channel = createChannel(carrier);

                sizeRG = [NSizeGrid * 12, 14];
                symbolIndicesLinear = sub2ind(sizeRG, symbolIndices(:, 1) + 1, ...
                    symbolIndices(:, 2) + 1);
                receivedRG = channel;
                receivedRG(symbolIndicesLinear) = receivedRG(symbolIndicesLinear) ...
                    .* DMRSsymbols * amplitude;
                noiseVar = 0.1; % 10 dB
                noiseRG = randn(sizeRG) + 1j * randn(sizeRG) * sqrt(noiseVar / 2);
                receivedRG = receivedRG + noiseRG;

                hop = configureHop();
                % Empty second hop.
                hop2.DMRSsymbols = [];
                nOFDMSymbols = sum(hop.DMRSsymbols);
                pilots = reshape(DMRSsymbols, [], nOFDMSymbols);
                cfg.DMRSSymbolMask = hop.DMRSsymbols;
                cfg.DMRSREmask = hop.DMRSREmask;
                cfg.nPilotsNoiseAvg = 2;
                cfg.scs = SubcarrierSpacing * 1000;
                cfg.useFilter = true;
                [estChannel, estNoiseVar, estRSRP] = srsChannelEstimator(receivedRG, ...
                    pilots, amplitude, hop, hop2, cfg);

                % Write simulation data.
                testCase.saveDataFile('_test_output', testID, ...
                    @writeResourceGridEntryFile, receivedRG(symbolIndicesLinear), symbolIndices);
                [subcarriers, syms, vals] = find(estChannel);
                testCase.saveDataFile('_ch_estimates', testID, ...
                    @writeResourceGridEntryFile, vals, [subcarriers, syms, zeros(length(subcarriers), 1)] - 1);
            end

            % Generate a 'slot_point' configuration string.
            slotPointConfig = cellarray2str({numerology, NFrame, ...
                floor(NSlot / carrier.SlotsPerSubframe), ...
                rem(NSlot, carrier.SlotsPerSubframe)}, true);

            % DMRS type
            DmrsTypeStr = ['dmrs_type::TYPE', num2str(DMRSConfigurationType)];

            % Cyclic Prefix.
            cyclicPrefixStr = 'cyclic_prefix::NORMAL';

            % generate a symbol allocation mask string
            symbolAllocationMask = symbolAllocationMask2string(symbolIndices);

            % generate a RB allocation mask string
            rbAllocationMask = RBallocationMask2string(PRBstart, PRBend);


            % Prepare DMRS configuration cell
            dmrsConfigCell = { ...
                slotPointConfig, ...           % slot
                DmrsTypeStr, ...               % type
                NIDNSCID, ...                  % Scrambling_id
                NSCID, ...                     % n_scid
                amplitude, ...                 % scaling
                cyclicPrefixStr, ...           % c_prefix
                symbolAllocationMask, ...      % symbol_mask
                rbAllocationMask, ...          % rb_mask
                pusch.SymbolAllocation(1), ... % first_symbol
                pusch.SymbolAllocation(2), ... % nof_symbols
                NumLayers, ...                 % nof_tx_layers
                {PUSCHports}, ...              % rx_ports
                };

            testCell = {['test_label::' testLabel], dmrsConfigCell, estNoiseVar, estRSRP};

            % generate the test case entry
            testCaseString = testCase.testCaseToString(testID, testCell, ...
                false, '_test_output', '_ch_estimates');

            % add the test to the file header
            testCase.addTestToHeaderFile(testCase.headerFileID, testCaseString);

            %   Nested functions
            %%%%%%%%%%%%%%%%%%%%%%%%%%%
            function hop_ = configureHop
                ofdmSymIndices = unique(symbolIndices(:, 2) + 1);
                hop_.DMRSsymbols = false(14, 1);
                hop_.DMRSsymbols(ofdmSymIndices) = true;
                hop_.DMRSREmask = false(12, 1);
                if DMRSConfigurationType == 1
                    hop_.DMRSREmask(1:2:end) = true;
                else
                    hop_.DMRSREmask([1, 2, 7, 8]) = true;
                end
                hop_.PRBstart = PRBstart;
                hop_.nPRBs = length(PRBSet);
                hop_.maskPRBs = false(NSizeGrid, 1);
                hop_.maskPRBs(PRBSet + 1) = true;
                hop_.startSymbol = SymbolAllocation(1);
                hop_.nAllocatedSymbols = SymbolAllocation(2);
                hop_.CHsymbols = false(14, 1);
                hop_.CHsymbols((1:SymbolAllocation(2)) + SymbolAllocation(1)) = true;
            end
        end % of function testvectorGenerationCases
    end % of methods (Test, TestTags = {'testvector'})
end % of classdef srsPUSCHdmrsUnittest

function channel = createChannel(carrier)
%Generates the frequency-response of single-tap channel that is consistent with
%   the simulation setup.
    nSubcarriers = carrier.NSizeGrid * 12;
    nOFDMSymbols = 14;
    % Compute maximum delay (1/4 CP length) in number of samples.
    maxDelay = floor(0.7 * 0.25 * nSubcarriers);
    % Random delay and random gain.
    delay = randi(maxDelay);
    gain = randn(1, 2) * [1; 1j] / sqrt(2);
    channel = repmat(gain * exp(-2j * pi / nSubcarriers * delay ...
        * (-nSubcarriers/2:nSubcarriers/2-1).'), 1, nOFDMSymbols);
end
