classdef QPSKDataDecoder < matlab.System
    %

    % Copyright 2012-2024 The MathWorks, Inc.
    
    properties (Nontunable)
        ModulationOrder = 4; 
        HeaderLength = 26;
        PayloadLength = 2240;
        NumberOfMessage = 20;
        DescramblerBase = 2;
        DescramblerPolynomial = [1 1 1 0 1];
        DescramblerInitialConditions = [0 0 0 0];
        BerMask = [];
        PrintOption = false;
        Preview = false;
    end
    
    properties (Access = private)
        pPayloadLength
        pDescrambler
        pErrorRateCalc
        pTargetBits
        pBER
        pGrayMapping
    end
    
    properties (Constant, Access = private)
        pBarkerCode = [+1; +1; +1; +1; +1; -1; -1; +1; +1; -1; +1; -1; +1]; % Bipolar Barker Code
        pModulatedHeader = sqrt(2)/2 * (-1-1i) * QPSKDataDecoder.pBarkerCode;
        pMessage = 'Hello world';
        pMessageLength = 16;
        pNormFactor = 2/pi; % M/(2*pi), for QPSK demodulation
    end
    
    methods
        function obj = QPSKDataDecoder(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj, ~, ~)
            coder.extrinsic('sprintf');
            
            obj.pDescrambler = comm.Descrambler(obj.DescramblerBase, ...
                obj.DescramblerPolynomial, obj.DescramblerInitialConditions);
            
            obj.pErrorRateCalc = comm.ErrorRate( ...
                'Samples', 'Custom', ...
                'CustomSamples', obj.BerMask);
            
            % Since we only calculate BER on message part, 000s are not
            % necessary here, they are just place-holder.
            msgSet = zeros(obj.NumberOfMessage * obj.pMessageLength, 1);
            for msgCnt = 0 : obj.NumberOfMessage - 1
                msgSet(msgCnt * obj.pMessageLength + (1 : obj.pMessageLength)) = ...
                    sprintf('%s %03d\n', obj.pMessage, mod(msgCnt, 100));
            end
            obj.pTargetBits = int2bit(msgSet, 7);

            % Gray coding
            j = int32((0:obj.ModulationOrder-1)');
            obj.pGrayMapping = bitxor(j,bitshift(j,-1));
        end
        
        function  [BER,output] = stepImpl(obj, data, isValid)
            output = [];
            if isValid
                % Phase ambiguity estimation
                phaseEst = round(angle(mean(conj(obj.pModulatedHeader) .* data(1:obj.HeaderLength/2)))*2/pi)/2*pi;
                
                % Compensating for the phase ambiguity
                phShiftedData = data .* exp(-1i*phaseEst);
                
                % Demodulating the phase recovered data
                demodOut = qpskDemod(phShiftedData, pi/4, obj.pGrayMapping, obj.pNormFactor);
                
                % Performs descrambling on only payload part
                deScrData = obj.pDescrambler( ...
                    demodOut(obj.HeaderLength + (1 : obj.PayloadLength)));
                
                % Recovering the message from the data
                if (obj.Preview)
                    output = deScrData;
                elseif(obj.PrintOption)
                    charSet = int8(bi2de(reshape(deScrData, 7, [])', 'left-msb'));
                    fprintf('%s', char(charSet));
                end
                                
                % Perform BER calculation only on message part
                obj.pBER = obj.pErrorRateCalc(obj.pTargetBits, deScrData);
            end
            BER = obj.pBER;
        end
        
        function resetImpl(obj)
            reset(obj.pDescrambler);
            reset(obj.pErrorRateCalc);
            obj.pBER = zeros(3, 1);
        end
        
        function releaseImpl(obj)
            release(obj.pDescrambler);
            release(obj.pErrorRateCalc);
            obj.pBER = zeros(3, 1);
        end
    end
end

function z = qpskDemod(y, phaseOffset, grayMapping, normFactor)
    % QPSK demodulation

    M = 4;
    nBits = 2;

    % De-rotate
    y1 = y .* exp(-1i*phaseOffset);

    % Convert input signal angle to linear domain; round the value to get ideal
    % constellation points
    z1 = round((angle(y1) .* normFactor));
    % Move all the negative integers by M
    idx = z1 < 0;
    z1(idx) = M + z1(idx);

    % Gray coding
    z1(:) = grayMapping(z1+1);

    % Convert symbols to bits
    z = reshape(mod(floor(z1(:) * [0.5, 1]), nBits)', length(z1)*nBits, 1);
end


