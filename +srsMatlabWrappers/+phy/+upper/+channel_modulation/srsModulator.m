%srsModulator Generation of modulated symbols from an input bit array.
%   [MODULATEDSYMBOLS] = srsModulator(CW, SHEME)
%   modulates the input bit sequence accordig to the requested SCHEME
%   and returns the complex symbols MODULATEDSYMBOLS.
%
%   See also nrPBCHDMRS, nrPBCHDMRSIndices.

function [modulatedSymbols] = srsModulator(cw, scheme)
    modulatedSymbols = nrSymbolModulate(cw, scheme, 'OutputDataType', 'single');
end
