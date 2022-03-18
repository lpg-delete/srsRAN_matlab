%NR_PBCH_SYMBOL_MODULATOR_TESTVECTOR_IMPL:
%   Class adding a new testvector to the set created as part of the PBCH modulation symbols unit test.
%   The associated 'pbch_modulator_test_data.h' file will be also generated by the calling unit-test.
%
%   Call details:
%     addTestCase(TESTID, NCELLID, CW, SSBINDEX, SSBLMAX) generates a new
%       testvector, using the values indicated by the input paramters
%         * double NCELLID   - PHY-layer cell ID
%         * double array CW - BCH codeword
%         * double SSB_INDEX - index of the SSB
%         * double SSB_LMAX  - parameter defining the maximum number of SSBs within a SSB set
%         * double TESTID    - unique test indentifier
%       Besides the input parameters, a random codeword will also be generated for each test
%       using a predefined random seed value.
classdef nrPBCHsymbolModulatorTestvectorImpl < testvector
    methods (Access = public)
        function testCaseString = addTestCase(obj, testID, NCellID, cw, SSBindex, Lmax, outputPath)
            % all output files will have a common name basis
            baseFilename = 'pbch_modulator_test_';

            % current fixed parameter values
            numPorts = 1;
            SSBfirstSubcarrier = 0;
            SSBfirstSymbol = 0;
            SSBamplitude = 1;
            SSBports = zeros(numPorts, 1);
            SSBportsStr = convertArrayToString(SSBports);

            % write the BCH codeword to a binary file
            obj.saveDataFile(baseFilename, 'input', testID, outputPath, 'writeUint8File', cw);

            % call the PBCH symbol modulation Matlab functions
            [modulatedSymbols, symbolIndices] = nrPBCHmodulationSymbolsGenerate(cw, NCellID, SSBindex, Lmax);

            % write each complex symbol into a binary file, and the associated indices to another
            obj.saveDataFile(baseFilename, 'output', testID, outputPath, 'writeResourceGridEntryFile', modulatedSymbols, symbolIndices);

            % generate the test case entry
            testCaseString = obj.testCaseToString('{%d, %d, %d, %d, %.1f, {%s}}', baseFilename, testID, NCellID, SSBindex, ...
                                               SSBfirstSubcarrier, SSBfirstSymbol, SSBamplitude, SSBportsStr);       
        end
    end
end