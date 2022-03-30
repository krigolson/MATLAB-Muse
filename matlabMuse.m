clear all;
close all;
clc;

% by Olav Krigolson
% program to connect to a MUSEdirectly to MATLAB using ble and stream data directly without using
% uvicMuse or BlueMuse or any dongles (tested in OSX only so far). this
% version does not use buffering and reads sequentially from channel
% characterisitcs using READ and not NOTIFY. thus, there is a potential for
% data loss - check the events variable to see if there is.
% press space bar to end, if you let it run too long you will run out of
% memory!

% specify a Muse Name
museName = 'MuseS-4161';

% decide to plot EEG (1), FFT (2), or Wavelets (3)
plotWhat = 1;

% muse sampling rate
sampleRate = 256;
% key parameter for biquad filters, this is a recommended value
bandWidth = 0.707;
% turn on high pass, low pass, and notch with 1, off with 0
whichFilters = [1 1 1];

% set up biquad high pass filter coefficients
frequency = 0.1;
highPass = biQuadHighPass(frequency,sampleRate,bandWidth);

% set up biquad high pass filter coefficients
frequency = 30;
lowPass = biQuadLowPass(frequency,sampleRate,bandWidth);

% setup biquad notch filter coefficients
frequency = 60;
notchFilter = biQuadNotch(frequency,sampleRate,bandWidth);

% define muse BLE names and characteristics
museServiceUUID = 'FE8D';
museControlCharacteristic = '273E0001-4C4D-454D-96BE-F03BAC821358';
museEEGCh1Characteristic = '273E0003-4C4D-454D-96BE-F03BAC821358';
museEEGCh2Characteristic = '273E0004-4C4D-454D-96BE-F03BAC821358';
museEEGCh3Characteristic = '273E0005-4C4D-454D-96BE-F03BAC821358';
museEEGCh4Characteristic = '273E0006-4C4D-454D-96BE-F03BAC821358';
museEEGChAux1Characteristic = '273E0007-4C4D-454D-96BE-F03BAC821358';
museACCCharacteristic = '273E000A-4C4D-454D-96BE-F03BAC821358';
museGyroCharacteristic = '273E0009-4C4D-454D-96BE-F03BAC821358';
museTeleCharacteristic = '273E000B-4C4D-454D-96BE-F03BAC821358';

% connect to a MUSE
b = ble(museName);

disp('Muse Connected...');

% set up the control charactertistic to write to
controlCharacteristic = characteristic(b,museServiceUUID,museControlCharacteristic);
% set up characteristics for channels 1 to 4
chCharacteristic{1} = characteristic(b,museServiceUUID,museEEGCh1Characteristic);
chCharacteristic{2} = characteristic(b,museServiceUUID,museEEGCh2Characteristic);
chCharacteristic{3} = characteristic(b,museServiceUUID,museEEGCh3Characteristic);
chCharacteristic{4} = characteristic(b,museServiceUUID,museEEGCh4Characteristic);

disp('Muse Characteristics Read...');

% send values to open the data stream from the Muse
% each message begins with the number of bytes, the message, and a linefeed (10)
% send a h to stop the muse temporarily
write(controlCharacteristic,[uint8(2) uint8('h') uint8(10)],'withoutresponse');
% disable the aux channel by sending p21 (p20 to enable)
write(controlCharacteristic,[uint8(4) uint8('p') uint8('2') uint8('1') uint8(10)],'withoutresponse');
% send a "s" to the muse to tell it to start
write(controlCharacteristic,[uint8(2) uint8('s') uint8(10)],'withoutresponse');
% send a "d" to the muse to tell it to continue
write(controlCharacteristic,[uint8(2) uint8('d') uint8(10)],'withoutresponse');

% create a bunch of empty variables
events = zeros(4,10000000);
eegData = zeros(4,12);
eegSamples = zeros(1,12);
tempEEG = zeros(4,12);
plotBuffer = zeros(4,512);
previousSamples = zeros(4,2,3);
previousResults = zeros(4,2,3);

% set up some colors for bar graphs
col(1,:) = [0 1 0]; % -- green
col(2,:) = [0 1 0]; % -- green
col(3,:) = [0 1 0]; % -- green
col(4,:) = [1 0 0]; % -- red
col(5,:) = [1 0 0]; % -- red
col(6,:) = [1 0 0]; % -- red
col(7,:) = [1 0 0]; % -- red
col(8,:) = [0 0 1]; % -- blue
col(9,:) = [0 0 1]; % -- blue
col(10,:) = [0 0 1]; % -- blue
col(11,:) = [0 0 1]; % -- blue
col(12,:) = [0 0 1]; % -- blue
col(13,:) = [1 1 0]; % -- yellow
col(14,:) = [1 1 0]; % -- yellow
col(15,:) = [1 1 0]; % -- yellow
col(16,:) = [1 1 0]; % -- yellow
col(17,:) = [1 1 0]; % -- yellow
col(18,:) = [1 1 0]; % -- yellow
col(19,:) = [1 1 0]; % -- yellow
col(20,:) = [1 1 0]; % -- yellow
col(21,:) = [1 1 0]; % -- yellow
col(22,:) = [1 1 0]; % -- yellow
col(23,:) = [1 1 0]; % -- yellow
col(24,:) = [1 1 0]; % -- yellow
col(25,:) = [1 1 0]; % -- yellow
col(26,:) = [1 1 0]; % -- yellow
col(27,:) = [1 1 0]; % -- yellow
col(28,:) = [1 1 0]; % -- yellow
col(29,:) = [1 1 0]; % -- yellow
col(30,:) = [1 1 0]; % -- yellow
c = 1:1:30;

disp('Starting Data Acquisition...');

% loop through and get some data and plot it
global endCollection
endCollection = 0;
collectData = true;
f = figure;
dataCounter = 1;

while collectData
    
    set(f,'windowkeypressfcn',@keyPressed);
    
    for channelCounter = 1:4
    
        % read a characteristic
        chData = read(chCharacteristic{channelCounter});
        % convert the data to EEG format
        [eegEvent, eegSample] = readMuse(chData);
        
        % store the values
        events(channelCounter,dataCounter) = eegEvent;
        tempEEG(channelCounter,:) = eegSample;
        
    end
    
    dataCounter = dataCounter + 1;
    
    % append data for storage and plotting
    eegData = [eegData tempEEG];
    plotSample = flip(tempEEG,2);

    % clean the data with a biquad filter
    [plotSample,previousSamples,previousResults] = applyBiQuad(plotSample,whichFilters,highPass,lowPass,notchFilter,previousSamples,previousResults);

    plotBuffer(:,13:512) = plotBuffer(:,1:500);
    plotBuffer(:,1:12) = plotSample;
    
    % plot raw eeg data
    if plotWhat == 1
    
        subplot(2,2,3);
        plot(plotBuffer(1,:));
        ylim([-1000 1000]);
        xlim([1 512]);
        title('TP9');
        subplot(2,2,1);
        plot(plotBuffer(2,:));
        ylim([-1000 1000]);
        xlim([1 512]);
        title('AF7');
        subplot(2,2,2);
        plot(plotBuffer(3,:));
        ylim([-1000 1000]);
        xlim([1 512]);
        title('AF8');
        subplot(2,2,4);
        plot(plotBuffer(4,:));
        ylim([-1000 1000]);
        xlim([1 512]);
        title('TP10');
        drawnow;
        
    end
    
    % plot FFT output
    % define maximum y value for power
    yMax = 20;
    if plotWhat == 2

        fftCoefficients = doMuseFFT(plotBuffer,sampleRate);
        subplot(2,2,3);
        
        barPlot = bar(c,fftCoefficients(1,:),'FaceColor','flat');
        barPlot.CData = col;
        ylim([0 yMax]);
        title('TP9');
        subplot(2,2,1);
        barPlot = bar(c,fftCoefficients(2,:),'FaceColor','flat');
        barPlot.CData = col;
        ylim([0 yMax]);
        title('AF7');
        subplot(2,2,2);
        barPlot = bar(c,fftCoefficients(3,:),'FaceColor','flat');
        barPlot.CData = col;
        ylim([0 yMax]);
        title('AF8');
        subplot(2,2,4);
        barPlot = bar(c,fftCoefficients(4,:),'FaceColor','flat');
        barPlot.CData = col;
        ylim([0 yMax]);
        title('TP10');
        drawnow; 
        
    end
    
    % plot the wavelets
    if plotWhat == 3
        
        waveletData = doMuseWavelet(plotBuffer);
        subplot(2,2,3);
        imagesc(squeeze(waveletData(1,:,:)));
        set(gca,'YDir','normal');
        title('TP9');
        subplot(2,2,1);
        imagesc(squeeze(waveletData(2,:,:)));
        set(gca,'YDir','normal');
        title('AF7');
        subplot(2,2,2);
        imagesc(squeeze(waveletData(3,:,:)));
        set(gca,'YDir','normal');
        title('AF8');
        subplot(2,2,4);
        imagesc(squeeze(waveletData(4,:,:)));
        set(gca,'YDir','normal');
        title('TP10');
        drawnow;
        
    end
    
    if endCollection == 1
        collectData = false;
    end
end

disp('Done data collection!');
disp('Save the MATLAB variable eedData to keep your raw data');

% create a callback function to stop data collection
function keyPressed(source, event)
    global endCollection
    KeyPressed=event.Key;
    if strcmp(KeyPressed,'space')
        endCollection = 1;
        close all;
    end
end