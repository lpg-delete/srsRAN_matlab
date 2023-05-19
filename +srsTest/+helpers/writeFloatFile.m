%writeFloatFile Writes real-valued float symbols to a binary file.
%   writeFloatFile(FILENAME, DATA) generates a new binary file FILENAME
%   containing a set of real-valued symbols, formatted to match the 'file_vector<float>'
%   object used by the SRS gNB.

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

function writeFloatFile(filename, data)
    fileID = fopen(filename, 'w');
    fwrite(fileID, data, 'float32');
    fclose(fileID);
end
