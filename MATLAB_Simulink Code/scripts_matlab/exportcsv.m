% Extract data and time vector
data = out.yOut.Data;
time = out.yOut.Time; 

% Convert to column doubles
data = double(data(:));
time = double(time(:));

% Combine and export 
T = table(time, data);
writetable(T, 'dsmadc_output.csv');
disp('Export complete: dsmadc_output.csv');