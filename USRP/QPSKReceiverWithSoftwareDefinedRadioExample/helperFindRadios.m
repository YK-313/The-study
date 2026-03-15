function connectedRadios = helperFindRadios(sdrType)
%   Copyright 2023-2025 The MathWorks, Inc.
fctrlCond = matlab.internal.feature("findsdr", 1); %#ok<NASGU>
connectedRadios = findsdr(SDRType = sdrType);
fprintf("\n")
disp(connectedRadios);
end