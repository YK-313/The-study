classdef (StrictDefaults)QPSKTransmitter < matlab.System  
%#codegen
% Generates the QPSK signal to be transmitted
    
%   Copyright 2012-2024 The MathWorks, Inc.
    
    properties (Nontunable)
        UpsamplingFactor = 2;
        ScramblerBase = 2;
        ScramblerPolynomial = [1 1 1 0 1];
        ScramblerInitialConditions = [0 0 0 0];
        RolloffFactor = 0.5
        RaisedCosineFilterSpan = 10
        NumberOfMessage = 10
        MessageLength = 16
        MessageBits = []
    end
    
    properties (Access=private)
        pBitGenerator
        pTransmitterFilter
        pMessage = 'Hello world';
        pHeader = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]; % Bipolar barker-code
        pConstellation
    end
    
    methods
        function obj = QPSKTransmitter(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access=protected)
        function setupImpl(obj)
            obj.pBitGenerator = QPSKBitsGenerator( ...
                'NumberOfMessage',              obj.NumberOfMessage, ...
                'MessageLength',                obj.MessageLength, ...
                'MessageBits',                  obj.MessageBits, ...
                'ScramblerBase',                obj.ScramblerBase, ...
                'ScramblerPolynomial',          obj.ScramblerPolynomial, ...
                'ScramblerInitialConditions',   obj.ScramblerInitialConditions);
            obj.pTransmitterFilter = comm.RaisedCosineTransmitFilter( ...
                'RolloffFactor',                obj.RolloffFactor, ...
                'FilterSpanInSymbols',          obj.RaisedCosineFilterSpan, ...
                'OutputSamplesPerSymbol',       obj.UpsamplingFactor);
            % Gray coded constellation
            const = comm.internal.psk.getConstellation(4, pi/4, 'double');
            % Gray coding
            j = int32((0:3)');
            mapping = bitxor(j,bitshift(j,-1));
            const(mapping+1) = const;
            obj.pConstellation = const;
        end

        function transmittedSignal = stepImpl(obj)

            % Generates the data to be transmitted
            [transmittedBin, ~] = obj.pBitGenerator();                 
            % Convert bits to symbols
            xSymbol = reshape([2 1] * reshape(transmittedBin,2,[]), [length(transmittedBin)/2, 1]);
            % QPSK Modulation
            modulatedData = obj.pConstellation(xSymbol+1);
             % Square root Raised Cosine Transmit Filter
            transmittedSignal = obj.pTransmitterFilter(modulatedData);
        end
        
        function resetImpl(obj)
            reset(obj.pBitGenerator);
            reset(obj.pTransmitterFilter);
        end
        
        function releaseImpl(obj)
            release(obj.pBitGenerator);
            release(obj.pTransmitterFilter);
        end
        
        function N = getNumInputsImpl(~)
            N = 0;
        end
    end
end

