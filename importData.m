function [passedTime,TempK] = importData(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as column vectors.
%   [UHRZEIT,TEMP] = IMPORTFILE(FILENAME) Reads data from text file
%   FILENAME for the default selection.
%
%   [UHRZEIT,TEMP] = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from
%   rows STARTROW through ENDROW of text file FILENAME.
%
% Example:
%   [Uhrzeit,Temp] = importfile('T_november_alone.csv',2, 48);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2019/10/02 12:16:31

%% Initialize variables.
delimiter = ';';
if nargin<=2
    startRow = 2;
    endRow = 100;
end

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

% Converts strings in the input cell array to numbers. Replaced non-numeric
% strings with NaN.
rawData = dataArray{2};
for row=1:size(rawData, 1);
    % Create a regular expression to detect and remove non-numeric prefixes and
    % suffixes.
    regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
    try
        result = regexp(rawData{row}, regexstr, 'names');
        numbers = result.numbers;
        
        
        % Detected commas in non-thousand locations.
        invalidThousandsSeparator = false;
        if any(numbers==',');
            thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
            if isempty(regexp(numbers, thousandsRegExp, 'once'));
                numbers = NaN;
                invalidThousandsSeparator = true;
            end
        end
        % Convert numeric strings to numbers.
        if ~invalidThousandsSeparator;
            numbers = textscan(strrep(numbers, ',', ''), '%f');
            numericData(row, 2) = numbers{1};
            raw{row, 2} = numbers{1};
        end
    catch me
    end
end

% Convert the contents of columns with dates to MATLAB datetimes using date
% format string.
try
    dates{1} = datetime(dataArray{1}, 'Format', 'HH:mm', 'InputFormat', 'HH:mm');
catch
    try
        % Handle dates surrounded by quotes
        dataArray{1} = cellfun(@(x) x(2:end-1), dataArray{1}, 'UniformOutput', false);
        dates{1} = datetime(dataArray{1}, 'Format', 'HH:mm', 'InputFormat', 'HH:mm');
    catch
        dates{1} = repmat(datetime([NaN NaN NaN]), size(dataArray{1}));
    end
end

anyBlankDates = cellfun(@isempty, dataArray{1});
anyInvalidDates = isnan(dates{1}.Hour) - anyBlankDates;
dates = dates(:,1);

%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, 2);
for i = 1:size(rawNumericColumns)
    if isempty(rawNumericColumns{i})
        rawNumericColumns{i} = -200;
    end
end
%% Allocate imported array to column variable names
Uhrzeit = dates{:, 1};
Temp = cell2mat(rawNumericColumns(:, 1));
%% Remove empty cells
TempTrue = Temp(Temp ~= -200);
UhrzeitTrue = Uhrzeit(~isnat(Uhrzeit));
%% Convert to the right units
startTime = UhrzeitTrue(1);
passedTime = seconds(UhrzeitTrue - startTime);

% Convert to Kelvin
TempK = TempTrue + 273.15;

end
